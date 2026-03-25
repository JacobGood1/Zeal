Class {
	#name : 'ZealDefer',
	#superclass : 'ZealExpression',
	#instVars : [
		'body'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealDefer >> body [ ^ body ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealDefer >> body: a [ body := a
]

{ #category : 'verse' }
ZealDefer >> compileToVerse: stream indent: level [
	stream nextPutAll: 'defer {'.
	self body do: [:e |
		stream cr. self emitIndent: level + 1 on: stream.
		e compileToVerse: stream indent: level + 1 ].
	stream cr. self emitIndent: level on: stream. stream nextPut: $}
]
