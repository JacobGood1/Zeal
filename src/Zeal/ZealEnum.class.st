Class {
	#name : 'ZealEnum',
	#superclass : 'ZealDefinition',
	#instVars : [
		'values'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'verse' }
ZealEnum >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: (self toSnakeCase: name); nextPutAll: ' := enum {'.
	self values do: [:v |
		stream cr. self emitIndent: level + 1 on: stream.
		stream nextPutAll: (self toPascalCase: v) ].
	stream cr. self emitIndent: level on: stream. stream nextPut: $}
]

{ #category : 'compiling' }
ZealEnum >> compileToVerseWithComments: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '// zeal: (defenum ' , name , ' ' , (values joinUsing: ' ') , ')'.
	stream cr.
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealEnum >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(defenum ' , name.
	self values do: [:v | stream nextPut: $ ; nextPutAll: v ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealEnum >> values [ ^ values ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealEnum >> values: a [ values := a
]
