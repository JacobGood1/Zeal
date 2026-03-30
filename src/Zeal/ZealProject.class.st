Class {
	#name : 'ZealProject',
	#superclass : 'ZealNode',
	#instVars : [
		'name',
		'path',
		'modules',
		'externalModules'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'scanning' }
ZealProject >> digestParseLine: stripped into: defs currentClass: currentClass onClassChange: aBlock [
	"Parse a single line from a digest file"
	((stripped includesSubstring: ':= module:') or: [stripped beginsWith: 'using']) ifTrue: [ ^ self ].
	
	(stripped includesSubstring: ':= class') ifTrue: [
		| clsName parents cls |
		clsName := stripped copyUpTo: $ .
		parents := OrderedCollection new.
		(stripped includes: $() ifTrue: [
			| pStr |
			pStr := (stripped copyAfter: $() copyUpTo: $).
			(pStr substrings: ',') do: [:p | parents add: p trimBoth ] ].
		cls := ZealClass new name: clsName;
			superclass: (parents isEmpty ifTrue: [nil] ifFalse: [parents first]);
			interfaces: (parents size > 1 ifTrue: [parents allButFirst] ifFalse: [#()]);
			fields: OrderedCollection new; methods: OrderedCollection new.
		defs add: cls. aBlock value: cls. ^ self ].
	
	(stripped includesSubstring: ':= interface') ifTrue: [
		| iface |
		iface := ZealInterface new name: (stripped copyUpTo: $ ); methods: OrderedCollection new.
		defs add: iface. aBlock value: iface. ^ self ].
	
	(stripped includesSubstring: ':= struct') ifTrue: [
		defs add: (ZealStruct new name: (stripped copyUpTo: $ ); fields: OrderedCollection new).
		aBlock value: nil. ^ self ].
	
	(stripped includesSubstring: ':= enum') ifTrue: [
		defs add: (ZealEnum new name: (stripped copyUpTo: $ ); values: OrderedCollection new).
		aBlock value: nil. ^ self ].
	
	"Method: Name(Params):ReturnType or Name(Params)<specs>:ReturnType"
	(currentClass notNil and: [(stripped includes: $() and: [(stripped includesSubstring: ':=') not]]) ifTrue: [
		| methodName fn sig retType |
		methodName := (stripped copyUpTo: $() trimBoth.
		methodName isEmpty ifFalse: [
			sig := stripped.
			retType := (sig includesSubstring: ':') 
				ifTrue: [ ((sig reversed copyUpTo: $:) reversed) trimBoth copyUpTo: $  ]
				ifFalse: [ 'void' ].
			fn := ZealFunction new name: methodName; 
				parameters: OrderedCollection new; body: OrderedCollection new;
				type: retType.
			fn rawSource: stripped. "Store original signature"
			fn parent: currentClass.
			(currentClass respondsTo: #methods) ifTrue: [ currentClass methods add: fn ] ].
		^ self ].
	
	"Field: Name:Type = external {} or var Name:Type = external {}"
	(currentClass notNil and: [stripped includes: $:]) ifTrue: [
		| fieldName fieldType field line |
		line := stripped.
		(line beginsWith: 'var ') ifTrue: [ line := line allButFirst: 4 ].
		fieldName := (line copyUpTo: $:) trimBoth.
		fieldType := ((line copyAfter: $:) copyUpTo: $ ) trimBoth.
		(fieldName notEmpty and: [fieldName first isLetter]) ifTrue: [
			field := ZealField new name: fieldName; type: fieldType.
			(currentClass respondsTo: #fields) ifTrue: [ currentClass fields add: field ] ].
		^ self ]
]

{ #category : 'exporting' }
ZealProject >> exportModule: aModule to: aDir [
	"Export a module definitions as a single .verse file."
	| stream fileName |
	fileName := aModule name , '.verse'.
	stream := String new writeStream.
	aModule usings do: [:u |
		u compileToVerse: stream indent: 0. stream cr ].
	stream cr.
	aModule definitions do: [:d |
		d compileToVerseWithComments: stream indent: 0.
		stream cr; cr ].
	(aDir / fileName) writeStream
		nextPutAll: stream contents;
		close
]

{ #category : 'exporting' }
ZealProject >> exportTo: aFolderPath [
	"Export all modules as .verse files to the given folder."
	| root |
	root := aFolderPath asFileReference.
	root ensureCreateDirectory.
	self modules do: [:mod |
		| modDir |
		modDir := root / mod name.
		modDir ensureCreateDirectory.
		self exportModule: mod to: modDir ]
]

{ #category : 'accessing' }
ZealProject >> externalModules [
	^ externalModules ifNil: [ externalModules := OrderedCollection new ]
]

{ #category : 'scanning' }
ZealProject >> extractRawChunks: codeLines [
	"Split code lines into chunks per top-level definition.
	 Each chunk starts at a non-empty, non-comment line at indent 0.
	 Comments before a definition are included in its chunk."
	| chunks current hasCode |
	chunks := OrderedCollection new.
	current := OrderedCollection new.
	hasCode := false.
	codeLines do: [:line |
		| trimmed |
		trimmed := line trimBoth.
		trimmed isEmpty ifTrue: [
			current add: line ]
		ifFalse: [ (trimmed first = $#) ifTrue: [
			"Comment: if we have code already, start a new chunk"
			hasCode ifTrue: [
				chunks add: ((String with: Character lf) join: current) trimBoth.
				current := OrderedCollection new.
				hasCode := false ].
			current add: line ]
		ifFalse: [
			((VersePreprocessor indentOf: line) = 0 and: [hasCode]) ifTrue: [
				chunks add: ((String with: Character lf) join: current) trimBoth.
				current := OrderedCollection new.
				hasCode := false ].
			current add: line.
			hasCode := true ] ] ].
	current notEmpty ifTrue: [ 
		chunks add: ((String with: Character lf) join: current) trimBoth ].
	^ chunks reject: [:c | c isEmpty]
]

{ #category : 'generating' }
ZealProject >> generateClasses [
	"Generate Smalltalk classes for all top-level definitions. Returns the generated classes."
	^ ZealClassGenerator generateFromProject: self
]

{ #category : 'views' }
ZealProject >> gtAllDefinitionsFor: aView [
	<gtView>
	^ aView columnedTree
		title: 'All Definitions';
		items: [ self modules ];
		children: [:item |
			(item isKindOf: ZealModule) ifTrue: [ item definitions ] ifFalse: [
				(item isKindOf: ZealClass) ifTrue: [ item methods ] ifFalse: [ #() ] ] ];
		column: 'Type' text: [:item | item class name allButFirst: 4 ] width: 120;
		column: 'Name' text: [:item | item name ifNil: [ '?' ] ]
]

{ #category : 'views' }
ZealProject >> gtModulesFor: aView [
	<gtView>
	^ aView list
		title: 'Modules';
		items: [ self modules ];
		itemText: [:m | m name , ' (' , m definitions size printString , ' definitions)' ]
]

{ #category : 'initialization' }
ZealProject >> initialize [
	super initialize.
	modules := OrderedCollection new
]

{ #category : 'scanning' }
ZealProject >> isTopLevelDef: aNode [
	^ (aNode isKindOf: ZealFunction) or: [
		(aNode isKindOf: ZealVariable) or: [
		(aNode isKindOf: ZealClass) or: [
		(aNode isKindOf: ZealStruct) or: [
		(aNode isKindOf: ZealEnum) or: [
		(aNode isKindOf: ZealInterface) or: [
		(aNode isKindOf: ZealModule) or: [
		(aNode isKindOf: ZealCompileError) ] ] ] ] ] ] ]
]

{ #category : 'scanning' }
ZealProject >> loadDigestFile: aFileRef into: aModule [
	"Parse a .digest.verse file — extracts class/interface/method definitions."
	| content lines currentClass defs |
	content := aFileRef contents.
	lines := content lines.
	currentClass := nil.
	defs := OrderedCollection new.
	
	lines do: [:rawLine |
		| stripped |
		stripped := rawLine trimBoth.
		(stripped isEmpty or: [stripped beginsWith: '#']) ifFalse: [
			#('<native>' '<public>' '<private>' '<internal>' '<final>' '<final_super>' '<concrete>' '<abstract>' '<unique>' '<override>' '<epic_internal>') do: [:spec |
				stripped := stripped copyReplaceAll: spec with: '' ].
			stripped := stripped trimBoth.
			self digestParseLine: stripped into: defs currentClass: currentClass onClassChange: [:c | currentClass := c] ] ].
	
	aModule definitions: defs asArray
]

{ #category : 'scanning' }
ZealProject >> loadFromCache [
	"Rebuild project tree from generated Smalltalk class hierarchy.
	 Modules have TZealModule trait. Everything else is a definition."
	| projectClass prefix |
	prefix := 'Zeal_' , (ZealClassGenerator toPascalCase: name).
	projectClass := Smalltalk globals at: prefix asSymbol ifAbsent: [ ^ false ].
	
	modules := OrderedCollection new.
	
	(Smalltalk allClassesAndTraits select: [:c | c superclass == projectClass]) do: [:modClass |
		| mod modName |
		modName := self pascalToSnake: (modClass name allButFirst: prefix size + 1).
		mod := ZealModule new name: modName; kind: #folder.
		self loadModuleFromCache: modClass into: mod.
		modules add: mod ].
	
	self scanExternalModules.
	^ modules notEmpty
]

{ #category : 'scanning' }
ZealProject >> loadModuleFromCache: parentClass into: aModule [
	"Load definitions and sub-modules from generated class hierarchy.
	 TZealModule = sub-module, TZealNamespace = old namespace (flatten into parent), others = definitions."
	| defs |
	defs := OrderedCollection new.
	
	(Smalltalk allClassesAndTraits select: [:c | c superclass == parentClass]) do: [:childClass |
		(childClass traits includes: TZealModule) ifTrue: [
			| subMod subName |
			subName := self pascalToSnake: (childClass name allButFirst: parentClass name size + 1).
			subMod := ZealModule new name: subName; kind: #folder.
			self loadModuleFromCache: childClass into: subMod.
			defs add: subMod ]
		ifFalse: [ (childClass traits includes: TZealNamespace) ifTrue: [
			"Old namespace — flatten its children into this module"
			self loadModuleFromCache: childClass into: aModule ]
		ifFalse: [
			| zealSource compiled |
			zealSource := [childClass zealSource] on: Error do: [nil].
			zealSource ifNotNil: [
				[ compiled := ZealCompiler compile: zealSource.
				  compiled := (compiled isKindOf: Collection) ifTrue: [compiled first] ifFalse: [compiled].
				  compiled generatedClass: childClass.
				  defs add: compiled ]
				on: Error do: [ ] ] ] ] ].
	
	"Merge defs into aModule's existing definitions (for namespace flattening)"
	aModule definitions: (aModule definitions asOrderedCollection addAll: defs; yourself) asArray
]

{ #category : 'scanning' }
ZealProject >> loadVerseFile: aFileRef into: aModule [
	| source lines codeLines preprocessed parsed nodes inUsingBlock rawChunks |
	source := aFileRef contents.
	lines := source lines.
	codeLines := OrderedCollection new.
	inUsingBlock := false.
	
	lines do: [:line |
		| trimmed |
		trimmed := line trimBoth.
		((trimmed beginsWith: 'using') and: [ trimmed includesSubstring: '{' ]) ifTrue: [
			| start end path |
			start := trimmed indexOf: ${ .
			end := trimmed indexOf: $}.
			(start > 0 and: [ end > start ]) ifTrue: [
				path := (trimmed copyFrom: start + 1 to: end - 1) trimBoth.
				aModule usings add: (ZealUsing new path: path; parent: aModule) ] ]
		ifFalse: [ (trimmed = 'using:') ifTrue: [ inUsingBlock := true ]
		ifFalse: [ inUsingBlock ifTrue: [
			(trimmed notEmpty and: [ (VersePreprocessor indentOf: line) > 0 ]) ifTrue: [
				aModule usings add: (ZealUsing new path: trimmed; parent: aModule) ]
			ifFalse: [ inUsingBlock := false. codeLines add: line ] ]
		ifFalse: [ codeLines add: line ] ] ] ].
	
	rawChunks := self extractRawChunks: codeLines.
	
	preprocessed := VersePreprocessor process: ((String with: Character lf) join: codeLines).
	[ parsed := VersePP2Grammar new parse: preprocessed.
	  (parsed isKindOf: PP2Failure) 
		ifTrue: [ aModule definitions add: (ZealCompileError new message: 'Parse failed: ' , parsed message) ]
		ifFalse: [
			nodes := VersePP2ToZeal convert: parsed.
			(nodes isKindOf: Collection)
				ifTrue: [ nodes do: [:n |
					(self isTopLevelDef: n) ifTrue: [
						n parent: aModule.
						"Match raw source by name"
						(n respondsTo: #name) ifTrue: [
							rawChunks do: [:chunk |
								(chunk includesSubstring: (n name ifNil: [''])) ifTrue: [ 
									n rawSource ifNil: [ n rawSource: chunk ] ] ] ].
						aModule definitions add: n ] ] ]
				ifFalse: [ 
					(self isTopLevelDef: nodes) ifTrue: [
						nodes parent: aModule.
						rawChunks notEmpty ifTrue: [ nodes rawSource: rawChunks first ].
						aModule definitions add: nodes ] ] ] ]
	on: Error do: [:e |
		aModule definitions add: (ZealCompileError new 
			message: 'Error parsing ' , aFileRef basename , ': ' , e messageText) ]
]

{ #category : 'accessing' }
ZealProject >> modules [ ^ modules ifNil: [ modules := OrderedCollection new ]
]

{ #category : 'accessing' }
ZealProject >> modules: a [ modules := a
]

{ #category : 'accessing' }
ZealProject >> name [ ^ name
]

{ #category : 'accessing' }
ZealProject >> name: s [ name := s
]

{ #category : 'private' }
ZealProject >> pascalToSnake: aString [
	"Convert PascalCase to snake_case: 8Oop → 8_oop, IntroLessons → intro_lessons"
	| result |
	result := WriteStream on: String new.
	aString do: [:ch |
		(ch isUppercase and: [result position > 0]) 
			ifTrue: [ result nextPut: $_; nextPut: ch asLowercase ]
			ifFalse: [ result nextPut: ch asLowercase ] ].
	^ result contents
]

{ #category : 'accessing' }
ZealProject >> path [ ^ path
]

{ #category : 'accessing' }
ZealProject >> path: s [ path := s
]

{ #category : 'printing' }
ZealProject >> printOn: aStream [
	aStream nextPutAll: 'ZealProject('.
	aStream nextPutAll: name asString.
	aStream nextPutAll: ' - '.
	aStream nextPutAll: self modules size printString.
	aStream nextPutAll: ' modules)'
]

{ #category : 'scanning' }
ZealProject >> scanDirectory: aDir into: parentNode [
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
		"Create a namespace (sub-module) per .verse file"
		verseFiles do: [:f |
			| ns |
			ns := ZealModule new
				name: f basenameWithoutExtension;
				kind: #file;
				usings: OrderedCollection new;
				definitions: OrderedCollection new.
			ns parent: mod.
			self loadVerseFile: f into: ns.
			mod definitions add: ns ].
		self modules add: mod ].
	subDirs do: [:d | self scanDirectory: d into: (mod ifNil: [ parentNode ]) ]
]

{ #category : 'scanning' }
ZealProject >> scanExternalModules [
	"Scan the VerseProject digest files for external API definitions."
	| verseProjectPath |
	externalModules := OrderedCollection new.
	verseProjectPath := 'C:\Users\Jacob Goodson\AppData\Local\UnrealEditorFortnite\Saved\VerseProject' asFileReference / name.
	verseProjectPath exists ifFalse: [ ^ self ].
	
	verseProjectPath directories do: [:dir |
		| digestFile mod |
		digestFile := dir files detect: [:f | f basename endsWith: '.digest.verse'] ifNone: [nil].
		digestFile ifNotNil: [
			mod := ZealModule new name: dir basename; kind: #external.
			[ self loadDigestFile: digestFile into: mod ] on: Error do: [:e | ].
			mod definitions notEmpty ifTrue: [ externalModules add: mod ] ] ]
]

{ #category : 'scanning' }
ZealProject >> scanFolder: aFileReference [
	"Load from cache if available, otherwise scan .verse files."
	| root |
	root := aFileReference asFileReference.
	path := root fullName.
	name := root basename.
	
	"Try loading from cached generated classes"
	(self loadFromCache) ifTrue: [ ^ self ].
	
	"First time — scan .verse files"
	modules := OrderedCollection new.
	self scanDirectory: root into: self.
	self scanExternalModules.
	self generateClasses.
	^ self
]
