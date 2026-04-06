Class {
	#name : 'ZealNode',
	#superclass : 'Object',
	#instVars : [
		'parent',
		'specifiers',
		'annotations',
		'rawSource',
		'generatedClass',
		'usings'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealNode >> annotations [ ^ annotations
]

{ #category : 'accessing' }
ZealNode >> annotations: anArray [ annotations := anArray
]

{ #category : 'gdscript' }
ZealNode >> compileToGDScript [
	"Compile this node to GDScript string.
	 Default: use rawSource through GDZealCodeGenerator"
	^ self compileToGDScript: (WriteStream on: String new) indent: 0
]

{ #category : 'gdscript' }
ZealNode >> compileToGDScript: stream indent: level [
	"Default: emit rawSource or subclass override"
	rawSource ifNotNil: [
		stream nextPutAll: (GDZealCodeGenerator compile: rawSource).
		^ stream ].
	stream nextPutAll: '/* uncompilable: ' , self class name , ' */'.
	^ stream
]

{ #category : 'compiling' }
ZealNode >> compileToVerse [
	rawSource ifNotNil: [ ^ rawSource ].
	^ String streamContents: [:s | self compileToVerse: s indent: 0 ]
]

{ #category : 'compiling' }
ZealNode >> compileToVerse: stream indent: level [
	"Subclasses override this"
	stream nextPutAll: self printString
]

{ #category : 'compiling' }
ZealNode >> compileToVerseWithComments [
	"Compile to Verse with embedded Zeal source as comments."
	^ String streamContents: [:s | self compileToVerseWithComments: s indent: 0 ]
]

{ #category : 'compiling' }
ZealNode >> compileToVerseWithComments: stream indent: level [
	"Default: emit zeal comment then verse output."
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealNode >> compileToVerseWithZealComment: zealSource [
	"Compile to Verse with multi-line zeal comment block above it."
	^ String streamContents: [:s |
		s nextPutAll: '# start-zeal'; cr.
		zealSource lines do: [:line |
			s nextPutAll: '# '; nextPutAll: line; cr ].
		s nextPutAll: '# end-zeal'; cr.
		self compileToVerse: s indent: 0 ]
]

{ #category : 'compiling' }
ZealNode >> compileToZeal [
	^ String streamContents: [:s | self compileToZeal: s indent: 0 ]
]

{ #category : 'compiling' }
ZealNode >> compileToZeal: stream indent: level [
	stream nextPutAll: self printString
]

{ #category : 'compiling' }
ZealNode >> emitIndent: level on: stream [
	level timesRepeat: [ stream nextPutAll: '    ' ]
]

{ #category : 'compiling' }
ZealNode >> emitSpecifiers: specs on: stream [
	specs do: [:s | stream nextPutAll: '<', s, '>' ]
]

{ #category : 'gdscript' }
ZealNode >> gdScriptString [
	"Convenience: compile to GDScript and return string"
	^ (self compileToGDScript: (WriteStream on: String new) indent: 0) contents
]

{ #category : 'accessing' }
ZealNode >> generatedClass [
	^ generatedClass
]

{ #category : 'accessing' }
ZealNode >> generatedClass: aClass [
	generatedClass := aClass
]

{ #category : 'views' }
ZealNode >> gtVerseFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Verse';
		text: [ self compileToVerse ]
]

{ #category : 'initialization' }
ZealNode >> initialize [
	super initialize.
	specifiers := #().
	annotations := #()
]

{ #category : 'navigation' }
ZealNode >> module [
	| node |
	node := self.
	[ node notNil ] whileTrue: [
		(node isKindOf: ZealModule) ifTrue: [ ^ node ].
		node := node parent ].
	^ nil
]

{ #category : 'navigation' }
ZealNode >> owningClass [
	| node |
	node := self.
	[ node notNil ] whileTrue: [
		(node isKindOf: ZealClass) ifTrue: [ ^ node ].
		node := node parent ].
	^ nil
]

{ #category : 'accessing' }
ZealNode >> parent [ ^ parent
]

{ #category : 'accessing' }
ZealNode >> parent: aNode [ parent := aNode
]

{ #category : 'printing' }
ZealNode >> printOn: aStream [
	aStream nextPutAll: self class name.
	(self respondsTo: #name) ifTrue: [
		aStream nextPutAll: '('.
		aStream nextPutAll: (self perform: #name) asString.
		aStream nextPutAll: ')' ]
]

{ #category : 'accessing' }
ZealNode >> rawSource [ ^ rawSource
]

{ #category : 'accessing' }
ZealNode >> rawSource: s [ rawSource := s
]

{ #category : 'accessing' }
ZealNode >> specifiers [ ^ specifiers
]

{ #category : 'accessing' }
ZealNode >> specifiers: anArray [ specifiers := anArray
]

{ #category : 'naming' }
ZealNode >> toKebabCase: aString [
	"Convert PascalCase or snake_case to kebab-case"
	^ String streamContents: [:s |
		aString doWithIndex: [:ch :i |
			(ch isUppercase and: [i > 1]) ifTrue: [ s nextPut: $- ].
			ch = $_ ifTrue: [ s nextPut: $- ]
			ifFalse: [ s nextPut: ch asLowercase ] ] ]
]

{ #category : 'naming' }
ZealNode >> toPascalCase: aString [
	^ String streamContents: [:s |
		| capitalize |
		capitalize := true.
		aString do: [:ch |
			ch = $-
				ifTrue: [ capitalize := true ]
				ifFalse: [
					capitalize
						ifTrue: [ s nextPut: ch asUppercase. capitalize := false ]
						ifFalse: [ s nextPut: ch ] ] ] ]
]

{ #category : 'naming' }
ZealNode >> toSnakeCase: aString [
	^ aString copyReplaceAll: '-' with: '_'
]

{ #category : 'naming' }
ZealNode >> typeToVerse: aTypeString [
	"Convert Zeal type to Verse type: int? -> ?int"
	aTypeString ifNil: [ ^ nil ].
	(aTypeString endsWith: '?') ifTrue: [ 
		^ '?' , aTypeString allButLast ].
	^ aTypeString
]

{ #category : 'naming' }
ZealNode >> typeToZeal: aTypeString [
	"Convert Verse type to Zeal type: ?int -> int?, []int -> []int"
	aTypeString ifNil: [ ^ nil ].
	(aTypeString beginsWith: '?') ifTrue: [ 
		^ (self toKebabCase: aTypeString allButFirst) , '?' ].
	^ self toKebabCase: aTypeString
]

{ #category : 'accessing' }
ZealNode >> usings [
	^ usings ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealNode >> usings: aCollection [
	usings := aCollection
]
