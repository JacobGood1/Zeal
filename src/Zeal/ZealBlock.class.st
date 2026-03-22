Class {
	#name : 'ZealBlock',
	#superclass : 'ZealExpression',
	#instVars : [
		'body'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealBlock >> body [ ^ body ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealBlock >> body: a [ body := a
]

{ #category : 'compiling' }
ZealBlock >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'block:'.
	self body do: [:e | stream cr. e compileToVerse: stream indent: level + 1 ]
]

{ #category : 'compiling' }
ZealBlock >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(do'.
	self body do: [:e | stream cr. e compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]
