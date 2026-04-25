Class {
	#name : 'VerseZealProject',
	#superclass : 'ZealProject',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
VerseZealProject >> extractZealCachedDefsFrom: sourceText [
	"Scan sourceText for `# @zeal ... # @end` blocks. For each, compile the embedded
	 Zeal source to a Zeal node. Return the compiled defs as an OrderedCollection,
	 or nil if no cache blocks are present."
	| lines inBlock buffer defs startMarker endMarker |
	startMarker := self zealCommentMarkerStart.
	endMarker := self zealCommentMarkerEnd.
	lines := sourceText lines.
	(lines anySatisfy: [:l | l trimBoth = startMarker ]) ifFalse: [ ^ nil ].

	defs := OrderedCollection new.
	inBlock := false.
	buffer := nil.
	lines do: [:line |
		| trimmed |
		trimmed := line trimBoth.
		trimmed = startMarker ifTrue: [
			inBlock := true.
			buffer := WriteStream on: String new ]
		ifFalse: [
			trimmed = endMarker ifTrue: [
				| zealSrc node |
				inBlock := false.
				zealSrc := buffer contents.
				node := [ ZealCompiler compile: zealSrc ] on: Error do: [:e | nil ].
				node ifNotNil: [
					(node isKindOf: Collection)
						ifTrue: [ defs addAll: node ]
						ifFalse: [ defs add: node ] ] ]
			ifFalse: [
				inBlock ifTrue: [
					"Strip `# ` prefix (or just `#` if the line is bare)"
					| stripped |
					stripped := (line beginsWith: '# ')
						ifTrue: [ line copyFrom: 3 to: line size ]
						ifFalse: [ (line beginsWith: '#')
							ifTrue: [ line copyFrom: 2 to: line size ]
							ifFalse: [ line ] ].
					buffer nextPutAll: stripped; nextPutAll: String lf ] ] ] ].
	^ defs
]

{ #category : 'api' }
VerseZealProject >> generateClasses [
	"Recursively generate Smalltalk classes for the Verse project.
	 All folder-kind ZealModules get TZealModule trait so they round-trip
	 through loadFromCache as sub-modules (not flattened into namespace defs)."
	| packageName projectClass generated |
	packageName := 'ZealProject-' , (name copyReplaceAll: ' ' with: '').
	projectClass := ZealClassGenerator
		ensureClass: ('Zeal_' , (ZealClassGenerator toPascalCase: name))
		superclass: ZealDefinitionClass
		trait: nil
		package: packageName.
	generated := OrderedCollection new.
	generated add: projectClass.
	self modules do: [:mod |
		generated addAll: (self generateModuleClassesFor: mod under: projectClass package: packageName) ].
	^ generated
]

{ #category : 'api' }
VerseZealProject >> generateModuleClassesFor: aModule under: parentClass package: packageName [
	"Recursively create a TZealModule-trait class for a folder module.
	 Inside it, nested folder modules recurse; inline ZealModules get
	 TZealNamespace trait; other definitions become plain def classes."
	| moduleClass generated |
	moduleClass := ZealClassGenerator
		ensureClass: (parentClass name , '_' , (ZealClassGenerator toPascalCase: aModule name))
		superclass: parentClass
		trait: TZealModule
		package: packageName.
	moduleClass class compile: ('zealSource ^ ''module: ' , aModule name , '''') classified: 'zeal'.
	moduleClass class compile: ('verseSource ^ ''module: ' , aModule name , '''') classified: 'zeal'.
	generated := OrderedCollection new.
	generated add: moduleClass.
	aModule definitions do: [:def |
		(def isKindOf: ZealCompileError) ifTrue: [ ^ generated ].
		((def isKindOf: ZealModule) and: [ def kind = #folder ])
			ifTrue: [ generated addAll: (self generateModuleClassesFor: def under: moduleClass package: packageName) ]
			ifFalse: [
				(def isKindOf: ZealModule)
					ifTrue: [
						| nsClass zealSrc verseSrc |
						nsClass := ZealClassGenerator
							ensureClass: (moduleClass name , '_' , (ZealClassGenerator toPascalCase: def name))
							superclass: moduleClass
							trait: TZealNamespace
							package: packageName.
						zealSrc := [ def compileToZeal ] on: Error do: [:e | 'Error: ' , e messageText ].
						verseSrc := [ def compileToVerse ] on: Error do: [:e | 'Error: ' , e messageText ].
						nsClass class compile: ('zealSource	^ ' , zealSrc printString) classified: 'zeal'.
						nsClass class compile: ('verseSource	^ ' , verseSrc printString) classified: 'zeal'.
						generated add: nsClass.
						def definitions do: [:innerDef |
							(innerDef isKindOf: ZealCompileError) ifFalse: [
								| defClass |
								defClass := ZealClassGenerator generateDef: innerDef parent: nsClass package: packageName.
								defClass ifNotNil: [ generated add: defClass ] ] ] ]
					ifFalse: [
						| defClass |
						defClass := ZealClassGenerator generateDef: def parent: moduleClass package: packageName.
						defClass ifNotNil: [ generated add: defClass ] ] ] ].
	^ generated
]

{ #category : 'api' }
VerseZealProject >> loadVerseFile: aFileRef into: aModule [
	"Verse loader with zeal-cache support. If the file contains `# @zeal ... # @end`
	 comment blocks, compile the embedded Zeal directly and skip Verse parsing
	 (faster and round-trip lossless). Otherwise fall back to parsing Verse."
	| source cachedDefs |
	source := aFileRef contents.

	"Parse `using {...}` from the file first — applies to both cache and fallback paths."
	self parseUsingsFrom: source into: aModule.

	cachedDefs := self extractZealCachedDefsFrom: source.
	cachedDefs ifNotNil: [
		cachedDefs do: [:n |
			n parent: aModule.
			aModule definitions add: n ].
		^ self ].

	"No cache — fall back to base Verse parsing."
	^ super loadVerseFile: aFileRef into: aModule
]

{ #category : 'api' }
VerseZealProject >> parseUsingsFrom: source into: aModule [
	"Extract `using { /path }` and `using:` block declarations into aModule usings."
	| lines inUsingBlock |
	lines := source lines.
	inUsingBlock := false.
	lines do: [:line |
		| trimmed |
		trimmed := line trimBoth.
		((trimmed beginsWith: 'using') and: [ trimmed includesSubstring: '{' ]) ifTrue: [
			| start end path |
			start := trimmed indexOf: ${.
			end := trimmed indexOf: $}.
			(start > 0 and: [ end > start ]) ifTrue: [
				path := (trimmed copyFrom: start + 1 to: end - 1) trimBoth.
				aModule usings add: (ZealUsing new path: path; parent: aModule) ] ]
		ifFalse: [ (trimmed = 'using:') ifTrue: [ inUsingBlock := true ]
		ifFalse: [ inUsingBlock ifTrue: [
			(trimmed notEmpty and: [ (VersePreprocessor indentOf: line) > 0 ]) ifTrue: [
				aModule usings add: (ZealUsing new path: trimmed; parent: aModule) ]
			ifFalse: [ inUsingBlock := false ] ] ] ] ]
]

{ #category : 'api' }
VerseZealProject >> scanDirectory: aDir into: parentNode [
	"Verse semantics: a module is a directory. All .verse files in that directory
	 contribute definitions directly to the directory's namespace — files themselves
	 are not modules. Sub-directories become nested sub-modules under their parent."
	| verseFiles subDirs mod |
	verseFiles := aDir children select: [:f | f isFile and: [ f extension = 'verse' ] ].
	subDirs := aDir children select: [:f | f isDirectory ].
	verseFiles notEmpty ifTrue: [
		mod := ZealModule new
			name: aDir basename;
			kind: #folder;
			usings: OrderedCollection new;
			definitions: OrderedCollection new.
		mod parent: parentNode.
		verseFiles do: [:f | self loadVerseFile: f into: mod ].
		(parentNode isKindOf: ZealModule)
			ifTrue: [ parentNode definitions add: mod ]
			ifFalse: [ self modules add: mod ] ].
	subDirs do: [:d | self scanDirectory: d into: (mod ifNil: [ parentNode ]) ]
]

{ #category : 'api' }
VerseZealProject >> zealCommentBlockFor: zealSource [
	"Return the comment-block header embedding a Zeal source cache above a Verse def.
	 Format:
	   # @zeal
	   # <zeal line 1>
	   # <zeal line 2>
	   # @end"
	| stream lf |
	stream := String new writeStream.
	lf := String lf.
	stream nextPutAll: self zealCommentMarkerStart; nextPutAll: lf.
	zealSource lines do: [:line |
		stream nextPutAll: '# '; nextPutAll: line; nextPutAll: lf ].
	stream nextPutAll: self zealCommentMarkerEnd; nextPutAll: lf.
	^ stream contents
]

{ #category : 'api' }
VerseZealProject >> zealCommentMarkerEnd [
	^ '# @end'
]

{ #category : 'api' }
VerseZealProject >> zealCommentMarkerStart [
	^ '# @zeal'
]
