Class {
	#name : 'ZealCase',
	#superclass : 'ZealExpression',
	#instVars : [
		'target',
		'cases'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealCase >> cases [ ^ cases ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealCase >> cases: a [ cases := a
]

{ #category : 'verse' }
ZealCase >> compileToVerse: stream indent: level [
	stream nextPutAll: 'case('.
	target compileToVerse: stream indent: level.
	stream nextPutAll: ') {'.
	self cases do: [:pair |
		stream cr. self emitIndent: level + 1 on: stream.
		pair first compileToVerse: stream indent: level + 1.
		stream nextPutAll: ' => '.
		pair second compileToVerse: stream indent: level + 1 ].
	stream cr. self emitIndent: level on: stream. stream nextPut: $}
]

{ #category : 'accessing' }
ZealCase >> target [ ^ target
]

{ #category : 'accessing' }
ZealCase >> target: e [ target := e
]
