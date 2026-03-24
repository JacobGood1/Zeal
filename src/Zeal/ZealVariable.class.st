Class {
	#name : 'ZealVariable',
	#superclass : 'ZealDefinition',
	#instVars : [
		'value',
		'isMutable'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealVariable >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	self isMutable ifTrue: [ stream nextPutAll: 'var ' ].
	stream nextPutAll: (self toPascalCase: name).
	self emitSpecifiers: (specifiers select: [:s | ZealColonChainResolver isDeclarationSpecifier: s]) on: stream.
	type ifNotNil: [ stream nextPut: $:; nextPutAll: (self typeToVerse: type) ].
	value ifNotNil: [
		stream nextPutAll: ' = '.
		value compileToVerse: stream indent: 0 ]
]

{ #category : 'compiling' }
ZealVariable >> compileToVerseWithComments: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '// zeal: (' , (self isMutable ifTrue: ['var '] ifFalse: ['def ']) , name.
	type ifNotNil: [ stream nextPut: $:; nextPutAll: type ].
	stream nextPutAll: ' ...)'.
	stream cr.
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealVariable >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '('.
	stream nextPutAll: (self isMutable ifTrue: ['var '] ifFalse: ['def ']).
	stream nextPutAll: (self toKebabCase: name).
	specifiers do: [:s | stream nextPut: $:; nextPutAll: (self toKebabCase: s) ].
	type ifNotNil: [ stream nextPut: $:; nextPutAll: (self typeToZeal: type) ].
	value ifNotNil: [ stream nextPut: $ . value compileToZeal: stream indent: 0 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealVariable >> isMutable [ ^ isMutable ifNil: [ false ]
]

{ #category : 'accessing' }
ZealVariable >> isMutable: aBool [ isMutable := aBool
]

{ #category : 'accessing' }
ZealVariable >> value [ ^ value
]

{ #category : 'accessing' }
ZealVariable >> value: anExpr [ value := anExpr
]
