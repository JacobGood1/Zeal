Class {
	#name : 'ZealFunctionCall',
	#superclass : 'ZealExpression',
	#instVars : [
		'functionName',
		'arguments'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealFunctionCall >> arguments [ ^ arguments ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFunctionCall >> arguments: a [ arguments := a
]

{ #category : 'compiling' }
ZealFunctionCall >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	functionName = '.' ifTrue: [
		arguments first compileToVerse: stream indent: 0.
		stream nextPut: $..
		arguments size >= 2 ifTrue: [
			arguments second compileToVerse: stream indent: 0.
			arguments size > 2 ifTrue: [
				stream nextPut: $(.
				(arguments copyFrom: 3 to: arguments size)
					do: [:a | a compileToVerse: stream indent: 0 ]
					separatedBy: [ stream nextPutAll: ', ' ].
				stream nextPut: $) ] ]. ^ self ].
	functionName = '[]' ifTrue: [
		arguments first compileToVerse: stream indent: 0.
		stream nextPut: $[.
		arguments allButFirst do: [:a | a compileToVerse: stream indent: 0 ] separatedBy: [ stream nextPutAll: ', ' ].
		stream nextPut: $]. ^ self ].
	functionName = 'archetype' ifTrue: [
		| typeName |
		typeName := (arguments first isKindOf: ZealSymbolRef) ifTrue: [arguments first name] ifFalse: [arguments first compileToVerse].
		stream nextPutAll: typeName; nextPut: ${.
		arguments allButFirst 
			do: [:a | 
				((a isKindOf: ZealOperator) and: [a operator = ':=']) ifTrue: [
					a operands first compileToVerse: stream indent: 0.
					stream nextPutAll: ' := '.
					a operands second compileToVerse: stream indent: 0 ]
				ifFalse: [ a compileToVerse: stream indent: 0 ] ]
			separatedBy: [ stream nextPutAll: ', ' ].
		stream nextPut: $}. ^ self ].
	stream nextPutAll: (self toPascalCase: functionName).
	stream nextPut: $(.
	self arguments do: [:a | a compileToVerse: stream indent: 0 ] separatedBy: [ stream nextPutAll: ', ' ].
	stream nextPut: $)
]

{ #category : 'compiling' }
ZealFunctionCall >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	functionName = '.' ifTrue: [
		"member access: (receiver/method args...) like Clojure namespace"
		| recv member |
		recv := arguments first.
		member := arguments size >= 2 ifTrue: [arguments second] ifFalse: [nil].
		stream nextPut: $(.
		recv compileToZeal: stream indent: 0.
		member ifNotNil: [ stream nextPut: $/. member compileToZeal: stream indent: 0 ].
		arguments size > 2 ifTrue: [
			(arguments copyFrom: 3 to: arguments size) do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ] ].
		stream nextPut: $). ^ self ].
	functionName = '[]' ifTrue: [
		stream nextPutAll: '(nth '.
		arguments do: [:a | a compileToZeal: stream indent: 0 ] separatedBy: [ stream nextPut: $  ].
		stream nextPut: $). ^ self ].
	functionName = 'archetype' ifTrue: [
		| typeName |
		typeName := (arguments first isKindOf: ZealSymbolRef) ifTrue: [self toKebabCase: arguments first name] ifFalse: ['?'].
		stream nextPutAll: '(' , typeName.
		arguments allButFirst do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ].
		stream nextPut: $). ^ self ].
	stream nextPutAll: '(' , (self toKebabCase: functionName).
	arguments do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealFunctionCall >> functionName [ ^ functionName
]

{ #category : 'accessing' }
ZealFunctionCall >> functionName: s [ functionName := s
]
