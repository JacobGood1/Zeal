Class {
	#name : 'ZealProject',
	#superclass : 'ZealNode',
	#instVars : [
		'name',
		'path',
		'modules'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

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
ZealProject >> loadVerseFile: aFileRef into: aModule [
	| source lines codeLines preprocessed parsed nodes inUsingBlock |
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
	
	preprocessed := VersePreprocessor process: (Character cr join: codeLines).
	[ parsed := VersePP2Grammar new parse: preprocessed.
	  (parsed isKindOf: PP2Failure) 
		ifTrue: [ aModule definitions add: (ZealCompileError new message: 'Parse failed: ' , parsed message) ]
		ifFalse: [
			nodes := VersePP2ToZeal convert: parsed.
			(nodes isKindOf: Collection)
				ifTrue: [ nodes do: [:n |
					(self isTopLevelDef: n) ifTrue: [
						n parent: aModule. aModule definitions add: n ] ] ]
				ifFalse: [ 
					(self isTopLevelDef: nodes) ifTrue: [
						nodes parent: aModule. aModule definitions add: nodes ] ] ] ]
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
ZealProject >> scanFolder: aFileReference [
	"Scan a UEFN project folder, build ZealNode tree, and generate Smalltalk classes."
	| root |
	root := aFileReference asFileReference.
	path := root fullName.
	name := root basename.
	modules := OrderedCollection new.
	self scanDirectory: root into: self.
	self generateClasses.
	^ self
]
