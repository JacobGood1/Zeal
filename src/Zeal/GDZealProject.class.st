Class {
	#name : 'GDZealProject',
	#superclass : 'Object',
	#instVars : [
		'name',
		'path',
		'modules',
		'registry'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'actions' }
GDZealProject >> addDefinition: aNode fromSource: sourceString [
	"Add a definition to the right module based on its type"
	| folder mod |
	folder := self folderFor: aNode.
	mod := modules at: folder.
	aNode rawSource: sourceString.
	aNode parent: mod.
	"Replace existing def with same name"
	mod definitions
		detect: [ :d | d name = aNode name ]
		ifFound: [ :old | mod definitions at: (mod definitions indexOf: old) put: aNode ]
		ifNone: [ mod definitions add: aNode ].
	"Register components"
	(aNode annotations includesAny: #('gecs_component')) ifTrue: [
		registry register: aNode name ]
]

{ #category : 'accessing' }
GDZealProject >> allDefinitions [
	"All definitions across all modules"
	^ modules values flatCollect: [ :mod | mod definitions ]
]

{ #category : 'persistence' }
GDZealProject >> compileAll [
	"Compile all definitions to GDScript"
	| count errors |
	count := 0. errors := 0.
	self allDefinitions do: [ :node |
		[ self compileDefinition: node.
		  count := count + 1 ]
		on: Error do: [ :e | errors := errors + 1 ] ].
	^ count -> errors
]

{ #category : 'compilation' }
GDZealProject >> compileDefinition: aNode [
	"Compile a single definition to GDScript and write to Godot project.
	 For deffsm components, also writes a sibling system file in systems/."
	| gdScript gdPath snakeName folder source |
	folder := self folderFor: aNode.
	snakeName := aNode name copyReplaceAll: '-' with: '_'.
	folder = 'components' ifTrue: [ gdPath := 'components/c_' , snakeName , '.gd' ].
	folder = 'entities' ifTrue: [ gdPath := 'entities/' , snakeName , '.gd' ].
	folder = 'systems' ifTrue: [ gdPath := 'systems/' , snakeName , '.gd' ].
	folder = 'observers' ifTrue: [ gdPath := 'observers/' , snakeName , '.gd' ].
	gdPath ifNil: [ gdPath := 'scripts/' , snakeName , '.gd' ].
	source := aNode rawSource.
	gdScript := GDZealCodeGenerator compile: source withRegistry: registry.
	(path , '/' , gdPath) asFileReference
		ensureDelete;
		writeStreamDo: [ :s | s nextPutAll: gdScript ].
	"deffsm components also generate a sibling system"
	(GDZealCompiler isDeffsm: source) ifTrue: [
		| systemSrc systemPath bindings |
		bindings := GDZealCompiler deffsmBindings: source.
		systemSrc := GDZealCompiler compileFsmSystemFor: aNode name withBindings: bindings.
		systemPath := 'systems/' , snakeName , '_system.gd'.
		(path , '/' , systemPath) asFileReference
			ensureDelete;
			writeStreamDo: [ :s | s nextPutAll: systemSrc ] ].
	^ gdPath
]

{ #category : 'accessing' }
GDZealProject >> externalModules [
	"GDZeal has no external modules"
	^ #()
]

{ #category : 'private' }
GDZealProject >> extractDefName: source [
	| forms |
	forms := #('defcomp ' 'defentity ' 'defsystem ' 'defobserver ' 'defn ').
	forms do: [ :form |
		| pos |
		pos := source findString: '(' , form.
		pos > 0 ifTrue: [
			| start end |
			start := pos + form size + 1.
			end := start.
			[ end <= source size and: [ (source at: end) isLetter or: [ (source at: end) isDigit or: [ '-_' includes: (source at: end) ] ] ] ] whileTrue: [ end := end + 1 ].
			end > start ifTrue: [ ^ source copyFrom: start to: end - 1 ] ] ].
	^ nil
]

{ #category : 'accessing' }
GDZealProject >> findDefinition: aName [
	"Find a definition by name across all modules"
	^ self allDefinitions
		detect: [ :d | d name = aName ]
		ifNone: [ nil ]
]

{ #category : 'private' }
GDZealProject >> folderFor: aNode [
	"Determine folder for a definition based on superclass/annotations"
	(aNode isKindOf: ZealClass) ifFalse: [ ^ 'scripts' ].
	aNode superclass = 'Component' ifTrue: [ ^ 'components' ].
	aNode superclass = 'Entity' ifTrue: [ ^ 'entities' ].
	aNode superclass = 'System' ifTrue: [ ^ 'systems' ].
	aNode superclass = 'Observer' ifTrue: [ ^ 'observers' ].
	^ 'scripts'
]

{ #category : 'initialization' }
GDZealProject >> initialize [
	modules := OrderedDictionary new.
	registry := GDZealComponentRegistry new.
	#('components' 'entities' 'systems' 'observers') do: [ :folder |
		| mod |
		mod := ZealModule new name: folder; kind: #folder; definitions: OrderedCollection new.
		modules at: folder put: mod ]
]

{ #category : 'loading' }
GDZealProject >> loadFromDirectory [
	"Scan gdzeal/ directory and load all .zeal files as ZealNode definitions"
	| zealDir |
	zealDir := (path , '/gdzeal') asFileReference.
	zealDir exists ifFalse: [ ^ self ].
	"First pass: register components"
	modules valuesDo: [ :mod |
		| dir |
		dir := zealDir / mod name.
		dir exists ifTrue: [
			(dir children select: [ :f | f extension = 'zeal' ]) do: [ :f |
				| src |
				src := f contents.
				(src includesSubstring: '(defcomp ') ifTrue: [
					| defName |
					defName := self extractDefName: src.
					defName ifNotNil: [ registry register: defName ] ] ] ] ].
	"Second pass: compile all"
	modules valuesDo: [ :mod |
		| dir |
		dir := zealDir / mod name.
		mod definitions: OrderedCollection new.
		dir exists ifTrue: [
			(dir children select: [ :f | f extension = 'zeal' ]) do: [ :f |
				| src node |
				src := f contents.
				[ node := GDZealCompiler compile: src.
				  node rawSource: src.
				  node parent: mod.
				  mod definitions add: node ]
				on: Error do: [ :e | "skip broken files" ] ] ] ]
]

{ #category : 'loading' }
GDZealProject >> loadFromImage [
	"Reload project from generated Smalltalk classes"
	| genClasses |
	genClasses := Smalltalk globals allClasses select: [ :c |
		c name beginsWith: 'GDZ_' ].
	genClasses do: [ :cls |
		| source node |
		[ source := cls zealSource.
		  node := GDZealCompiler compile: source.
		  node rawSource: source.
		  node generatedClass: cls.
		  self addDefinition: node fromSource: source ]
		on: Error do: [ :e | "skip broken" ] ]
]

{ #category : 'accessing' }
GDZealProject >> modules [
	^ modules
]

{ #category : 'accessing' }
GDZealProject >> name [
	^ name ifNil: [ 'GDZeal' ]
]

{ #category : 'accessing' }
GDZealProject >> name: aString [
	name := aString
]

{ #category : 'accessing' }
GDZealProject >> path [
	^ path
]

{ #category : 'accessing' }
GDZealProject >> path: aString [
	path := aString
]

{ #category : 'persistence' }
GDZealProject >> persistToImage [
	"Persist all definitions as generated Smalltalk classes for image-based storage.
	 Generated classes go in GDZeal-Generated package, methods classified under 'metadata'."
	self allDefinitions do: [ :node |
		| className cls |
		className := ('GDZ_' , (node name copyReplaceAll: '-' with: '_')) asSymbol.
		cls := Smalltalk globals at: className ifAbsent: [
			Object subclass: className
				instanceVariableNames: ''
				classVariableNames: ''
				package: 'GDZeal-Generated' ].
		cls class compile: 'zealSource ^ ' , node rawSource printString classified: 'metadata'.
		cls class compile: 'zealNodeType ^ ' , node class name printString classified: 'metadata'.
		cls class compile: 'zealName ^ ' , node name printString classified: 'metadata'.
		(node isKindOf: ZealClass)
			ifTrue: [ cls class compile: 'zealSuperclass ^ ' , node superclass printString classified: 'metadata' ]
			ifFalse: [ cls class compile: 'zealSuperclass ^ nil' classified: 'metadata' ].
		node generatedClass: cls ]
]

{ #category : 'accessing' }
GDZealProject >> registry [
	^ registry
]

{ #category : 'actions' }
GDZealProject >> removeDefinition: aNode [
	"Remove a definition from its module"
	modules valuesDo: [ :mod |
		mod definitions remove: aNode ifAbsent: [] ]
]

{ #category : 'persistence' }
GDZealProject >> saveDefinition: aNode [
	"Save .zeal source file for a definition"
	| folder fileName filePath |
	folder := self folderFor: aNode.
	fileName := aNode name , '.zeal'.
	filePath := path , '/gdzeal/' , folder , '/' , fileName.
	filePath asFileReference parent ensureCreateDirectory.
	filePath asFileReference
		ensureDelete;
		writeStreamDo: [ :s | s nextPutAll: aNode rawSource ]
]
