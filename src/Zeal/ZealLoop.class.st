Class {
	#name : 'ZealLoop',
	#superclass : 'ZealExpression',
	#instVars : [
		'body'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealLoop >> body [ ^ body ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealLoop >> body: a [ body := a
]

{ #category : 'verse' }
ZealLoop >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'loop {'.
	self body do: [:e | stream cr. e compileToVerse: stream indent: level + 1 ].
	stream cr. self emitIndent: level on: stream. stream nextPut: $}
]

{ #category : 'compiling' }
ZealLoop >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(loop'.
	self body do: [:e | stream cr. e compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]
