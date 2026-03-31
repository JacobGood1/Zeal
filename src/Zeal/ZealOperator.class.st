Class {
	#name : 'ZealOperator',
	#superclass : 'ZealExpression',
	#instVars : [
		'operator',
		'operands'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealOperator >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	operator = 'not' ifTrue: [
		stream nextPutAll: 'not '. operands first compileToVerse: stream indent: 0. ^ self ].
	(operator = '-' and: [ operands size = 1 ]) ifTrue: [
		stream nextPut: $-. operands first compileToVerse: stream indent: 0. ^ self ].
	(operator = '?' and: [ operands size = 1 ]) ifTrue: [
		operands first compileToVerse: stream indent: 0. stream nextPut: $?. ^ self ].
	operator = '..' ifTrue: [
		operands first compileToVerse: stream indent: 0.
		stream nextPutAll: '..'.
		operands second compileToVerse: stream indent: 0. ^ self ].
	"Wrap binary operations in parens to preserve precedence"
	stream nextPut: $(.
	operands first compileToVerse: stream indent: 0.
	operands allButFirst do: [:o |
		stream nextPutAll: ' '; nextPutAll: operator; nextPutAll: ' '.
		o compileToVerse: stream indent: 0 ].
	stream nextPut: $)
]

{ #category : 'compiling' }
ZealOperator >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	operator = 'not' ifTrue: [
		stream nextPutAll: '(not '. operands first compileToZeal: stream indent: 0. stream nextPut: $). ^ self ].
	(operator = '-' and: [ operands size = 1 ]) ifTrue: [
		stream nextPut: $-. operands first compileToZeal: stream indent: 0. ^ self ].
	(operator = '?' and: [ operands size = 1 ]) ifTrue: [
		stream nextPutAll: '(? '. operands first compileToZeal: stream indent: 0. stream nextPut: $). ^ self ].
	operator = '..' ifTrue: [
		operands first compileToZeal: stream indent: 0.
		stream nextPutAll: '..'.
		operands second compileToZeal: stream indent: 0. ^ self ].
	stream nextPutAll: '(' , operator.
	operands do: [:o | stream nextPut: $ . o compileToZeal: stream indent: 0 ].
	stream nextPut: $)
]

{ #category : 'compiling' }
ZealOperator >> emitWithoutOuterParens: stream [
	"Emit binary operator without wrapping parens — used when parent already provides them"
	operands first compileToVerse: stream indent: 0.
	operands allButFirst do: [:o |
		stream nextPutAll: ' '; nextPutAll: operator; nextPutAll: ' '.
		o compileToVerse: stream indent: 0 ]
]

{ #category : 'accessing' }
ZealOperator >> operands [ ^ operands ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealOperator >> operands: a [ operands := a
]

{ #category : 'accessing' }
ZealOperator >> operator [ ^ operator
]

{ #category : 'accessing' }
ZealOperator >> operator: s [ operator := s
]
