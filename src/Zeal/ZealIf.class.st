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

{ #category : 'verse' }
ZealIf >> compileToVerse: stream indent: level isElseIf: isElseIf [
	| elseExprs |
	clauses doWithIndex: [:pair :i |
		| cond body bodyExprs |
		cond := pair first. body := pair second.
		i > 1 ifTrue: [ stream cr. self emitIndent: level on: stream. stream nextPutAll: 'else ' ].
		(i = 1 and: [isElseIf not]) ifTrue: [ self emitIndent: level on: stream ].
		stream nextPutAll: 'if('.
		self emitCondition: cond on: stream.
		stream nextPutAll: ') {'.
		bodyExprs := (body isKindOf: ZealBlock) ifTrue: [body body] ifFalse: [{body}].
		bodyExprs do: [:expr | stream cr. expr compileToVerse: stream indent: level + 1 ].
		stream cr. self emitIndent: level on: stream. stream nextPut: $} ].
	elseBody ifNotNil: [:eb |
		(eb isKindOf: ZealIf) ifTrue: [
			stream cr. self emitIndent: level on: stream. stream nextPutAll: 'else '.
			eb compileToVerse: stream indent: level isElseIf: true. ^ self ].
		elseExprs := (eb isKindOf: ZealBlock) ifTrue: [eb body] ifFalse: [{eb}].
		stream nextPutAll: ' else {'.
		elseExprs do: [:expr | stream cr. expr compileToVerse: stream indent: level + 1 ].
		stream cr. self emitIndent: level on: stream. stream nextPut: $} ]
]

{ #category : 'zeal' }
ZealIf >> compileToZeal: stream indent: level [
	| allClauses finalElse hasBinding |
	self emitIndent: level on: stream.
	allClauses := self flattenClauses.
	finalElse := self finalElseBody.
	
	hasBinding := allClauses anySatisfy: [:pair |
		(pair first isKindOf: ZealOperator) and: [pair first operator = ':='] ].
	hasBinding ifTrue: [ ^ self compileToZealAsLet: stream indent: level clauses: allClauses else: finalElse ].
	
	stream nextPutAll: '(if'.
	allClauses doWithIndex: [:pair :i |
		stream nextPut: $ .
		self emitZealCondition: pair first on: stream.
		stream cr.
		pair second compileToZeal: stream indent: level + 1.
		"Simple if/else (one clause + else): no :else keyword"
		"Multi-clause: use :else before the final else"
		].
	finalElse ifNotNil: [:eb |
		allClauses size > 1 ifTrue: [
			"Multi-clause: need :else"
			stream cr.
			self emitIndent: level + 1 on: stream.
			stream nextPutAll: ':else' ].
		stream cr.
		eb compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'compiling' }
ZealIf >> compileToZealAsLet: stream indent: level clauses: allClauses else: finalElse [
	"Emit as (let [bindings/conditions] body :else elseBody)"
	stream nextPutAll: '(let ['.
	allClauses do: [:pair |
		| cond |
		cond := pair first.
		((cond isKindOf: ZealOperator) and: [cond operator = ':=']) ifTrue: [
			"Binding: name expr"
			cond operands first compileToZeal: stream indent: 0.
			stream nextPut: $ .
			cond operands second compileToZeal: stream indent: 0 ]
		ifFalse: [
			"Regular condition"
			cond compileToZeal: stream indent: 0 ] ].
	stream nextPut: $].
	allClauses do: [:pair |
		stream cr.
		pair second compileToZeal: stream indent: level + 1 ].
	finalElse ifNotNil: [:eb |
		stream cr.
		self emitIndent: level + 1 on: stream.
		stream nextPutAll: ':else'.
		stream cr.
		eb compileToZeal: stream indent: level + 1 ].
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
	"Emit condition — comma operator emits comma-separated, and stays as 'and'"
	((cond isKindOf: ZealOperator) and: [cond operator = ',']) ifTrue: [
		cond operands 
			do: [:o | self emitCondition: o on: stream ]
			separatedBy: [ stream nextPutAll: ', ' ] ]
	ifFalse: [ ((cond isKindOf: ZealOperator) and: [cond operator = ':=']) ifTrue: [
		cond operands first compileToVerse: stream indent: 0.
		stream nextPutAll: ' := '.
		cond operands second compileToVerse: stream indent: 0 ]
	ifFalse: [
		cond compileToVerse: stream indent: 0 ] ]
]

{ #category : 'compiling' }
ZealIf >> emitZealCondition: cond on: stream [
	"Emit condition for Zeal output. Comma operator becomes (and ...) in Zeal."
	((cond isKindOf: ZealOperator) and: [cond operator = ',']) ifTrue: [
		stream nextPutAll: '(and'.
		cond operands do: [:o | stream nextPut: $ . self emitZealCondition: o on: stream ].
		stream nextPut: $) ]
	ifFalse: [ ((cond isKindOf: ZealOperator) and: [cond operator = ':=']) ifTrue: [
		cond operands first compileToZeal: stream indent: 0.
		stream nextPutAll: ' := '.
		cond operands second compileToZeal: stream indent: 0 ]
	ifFalse: [
		cond compileToZeal: stream indent: 0 ] ]
]

{ #category : 'accessing' }
ZealIf >> finalElseBody [
	"Walk the else-if chain to find the final non-if else body"
	(elseBody isKindOf: ZealIf) ifTrue: [ ^ elseBody finalElseBody ].
	^ elseBody
]

{ #category : 'accessing' }
ZealIf >> flattenClauses [
	"Collect all clauses including from nested else-if chains into a flat list"
	| result |
	result := OrderedCollection new.
	result addAll: clauses.
	(elseBody isKindOf: ZealIf) ifTrue: [
		result addAll: elseBody flattenClauses ].
	^ result
]
