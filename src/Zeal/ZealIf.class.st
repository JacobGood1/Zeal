Class {
	#name : 'ZealIf',
	#superclass : 'ZealExpression',
	#instVars : [
		'clauses',
		'elseBody'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealIf >> clauses [ ^ clauses ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealIf >> clauses: a [ clauses := a
]

{ #category : 'compiling' }
ZealIf >> compileToVerse: stream indent: level [
	self compileToVerse: stream indent: level isElseIf: false
]

{ #category : 'compiling' }
ZealIf >> compileToVerse: stream indent: level isElseIf: isElseIf [
	| elseExprs |
	clauses doWithIndex: [:pair :i |
		| cond body bodyExprs |
		cond := pair first. body := pair second.
		i > 1 ifTrue: [ stream cr. self emitIndent: level on: stream. stream nextPutAll: 'else ' ].
		(i = 1 and: [isElseIf not]) ifTrue: [ self emitIndent: level on: stream ].
		stream nextPutAll: 'if('.
		self emitCondition: cond on: stream.
		stream nextPutAll: '):'.
		bodyExprs := (body isKindOf: ZealBlock) ifTrue: [body body] ifFalse: [{body}].
		bodyExprs do: [:expr | stream cr. expr compileToVerse: stream indent: level + 1 ] ].
	elseBody ifNotNil: [:eb |
		(eb isKindOf: ZealIf) ifTrue: [
			stream cr. self emitIndent: level on: stream. stream nextPutAll: 'else '.
			eb compileToVerse: stream indent: level isElseIf: true. ^ self ].
		elseExprs := (eb isKindOf: ZealBlock) ifTrue: [eb body] ifFalse: [{eb}].
		stream cr. self emitIndent: level on: stream. stream nextPutAll: 'else:'.
		elseExprs do: [:expr | stream cr. expr compileToVerse: stream indent: level + 1 ] ]
]

{ #category : 'compiling' }
ZealIf >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(if '.
	clauses do: [:pair |
		pair first compileToZeal: stream indent: 0.
		stream cr. pair second compileToZeal: stream indent: level + 1 ].
	elseBody ifNotNil: [:eb |
		stream cr. eb compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealIf >> elseBody [ ^ elseBody
]

{ #category : 'accessing' }
ZealIf >> elseBody: e [ elseBody := e
]

{ #category : 'compiling' }
ZealIf >> emitCondition: cond on: stream [
	"Emit condition — flatten 'and' chains back to comma-separated, handle := bindings"
	((cond isKindOf: ZealOperator) and: [cond operator = 'and']) ifTrue: [
		self emitCondition: cond operands first on: stream.
		stream nextPutAll: ', '.
		self emitCondition: cond operands second on: stream ]
	ifFalse: [ ((cond isKindOf: ZealOperator) and: [cond operator = ':=']) ifTrue: [
		cond operands first compileToVerse: stream indent: 0.
		stream nextPutAll: ' := '.
		cond operands second compileToVerse: stream indent: 0 ]
	ifFalse: [
		cond compileToVerse: stream indent: 0 ] ]
]
