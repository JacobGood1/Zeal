Class {
	#name : 'ZealReturn',
	#superclass : 'ZealExpression',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealReturn >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'return'.
	value ifNotNil: [ stream nextPut: $ . value compileToVerse: stream indent: 0 ]
]

{ #category : 'compiling' }
ZealReturn >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(return'.
	value ifNotNil: [ stream nextPut: $ . value compileToZeal: stream indent: 0 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealReturn >> value [ ^ value
]

{ #category : 'accessing' }
ZealReturn >> value: e [ value := e
]
