Class {
	#name : 'ZealArray',
	#superclass : 'ZealExpression',
	#instVars : [
		'elements'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealArray >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'array{'.
	self elements do: [:e | e compileToVerse: stream indent: 0 ] separatedBy: [ stream nextPutAll: ', ' ].
	stream nextPut: $}
]

{ #category : 'compiling' }
ZealArray >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPut: $[.
	self elements do: [:e | e compileToZeal: stream indent: 0 ] separatedBy: [ stream nextPut: $  ].
	stream nextPut: $]
]

{ #category : 'accessing' }
ZealArray >> elements [ ^ elements ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealArray >> elements: a [ elements := a
]
