Class {
	#name : 'ZealLiteral',
	#superclass : 'ZealExpression',
	#instVars : [
		'value',
		'literalType'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealLiteral >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: value asString
]

{ #category : 'compiling' }
ZealLiteral >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: value asString
]

{ #category : 'accessing' }
ZealLiteral >> literalType [ ^ literalType
]

{ #category : 'accessing' }
ZealLiteral >> literalType: s [ literalType := s
]

{ #category : 'accessing' }
ZealLiteral >> value [ ^ value
]

{ #category : 'accessing' }
ZealLiteral >> value: v [ value := v
]
