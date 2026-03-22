Class {
	#name : 'ZealNode',
	#superclass : 'Object',
	#instVars : [
		'parent',
		'specifiers',
		'annotations'
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

{ #category : 'compiling' }
ZealNode >> compileToVerse [
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
