Class {
	#name : 'ZealMap',
	#superclass : 'ZealExpression',
	#instVars : [
		'entries'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealMap >> compileToVerse: stream indent: level [
	stream nextPutAll: 'map{'.
	self entries do: [:pair |
		pair first compileToVerse: stream indent: level.
		stream nextPutAll: ' => '.
		pair second compileToVerse: stream indent: level ] separatedBy: [ stream nextPutAll: ', ' ].
	stream nextPut: $}
]

{ #category : 'compiling' }
ZealMap >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPut: ${.
	self entries do: [:pair |
		pair first compileToZeal: stream indent: 0.
		stream nextPut: $ .
		pair second compileToZeal: stream indent: 0 ] separatedBy: [ stream nextPut: $  ].
	stream nextPut: $}
]

{ #category : 'accessing' }
ZealMap >> entries [ ^ entries ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealMap >> entries: a [ entries := a
]
