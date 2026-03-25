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

{ #category : 'verse' }
ZealFunctionCall >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	functionName = '.' ifTrue: [
		"Property access: Obj.Member (no parens)"
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
	functionName = '.call' ifTrue: [
		"Method call: Obj.Member(args...) — always has parens"
		arguments first compileToVerse: stream indent: 0.
		stream nextPut: $..
		arguments second compileToVerse: stream indent: 0.
		stream nextPut: $(.
		arguments size > 2 ifTrue: [
			(arguments copyFrom: 3 to: arguments size)
				do: [:a | a compileToVerse: stream indent: 0 ]
				separatedBy: [ stream nextPutAll: ', ' ] ].
		stream nextPut: $). ^ self ].
	functionName = '[]' ifTrue: [
		arguments first compileToVerse: stream indent: 0.
		stream nextPut: $[.
		arguments allButFirst do: [:a | a compileToVerse: stream indent: 0 ] separatedBy: [ stream nextPutAll: ', ' ].
		stream nextPut: $]. ^ self ].
	functionName = 'archetype' ifTrue: [
		| typeName |
		typeName := (arguments first isKindOf: ZealSymbolRef) 
			ifTrue: [self toSnakeCase: arguments first name] 
			ifFalse: [arguments first compileToVerse].
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

{ #category : 'zeal' }
ZealFunctionCall >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	functionName = '.' ifTrue: [
		| hasArgs |
		hasArgs := arguments size > 2.
		hasArgs ifTrue: [ stream nextPut: $( ].
		arguments first compileToZeal: stream indent: 0.
		stream nextPut: $/.
		arguments size >= 2 ifTrue: [ arguments second compileToZeal: stream indent: 0 ].
		hasArgs ifTrue: [
			(arguments copyFrom: 3 to: arguments size) do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ].
			stream nextPut: $) ].
		^ self ].
	functionName = '.call' ifTrue: [
		"Method call: (obj/method args...)"
		stream nextPut: $(.
		arguments first compileToZeal: stream indent: 0.
		stream nextPut: $/.
		arguments second compileToZeal: stream indent: 0.
		arguments size > 2 ifTrue: [
			(arguments copyFrom: 3 to: arguments size) do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ] ].
		stream nextPut: $). ^ self ].
	functionName = '[]' ifTrue: [
		| recv args isIndex |
		recv := arguments first.
		args := arguments allButFirst.
		"Member failable: obj.method[args] -> obj/method? args or (obj/method? args)"
		((recv isKindOf: ZealFunctionCall) and: [recv functionName = '.']) ifTrue: [
			args isEmpty ifTrue: [
				recv compileToZeal: stream indent: 0. stream nextPut: $?. ^ self ].
			stream nextPut: $(.
			recv compileToZeal: stream indent: 0. stream nextPut: $?.
			args do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ].
			stream nextPut: $). ^ self ].
		"Index: Arr[0] -> arr/0 (inline for simple receiver)"
		isIndex := args allSatisfy: [:a | (a isKindOf: ZealLiteral) and: [a literalType = #integer]].
		((recv isKindOf: ZealSymbolRef) and: [isIndex]) ifTrue: [
			recv compileToZeal: stream indent: 0.
			args do: [:a | stream nextPut: $/. a compileToZeal: stream indent: 0 ].
			^ self ].
		"Failable call: Name[args] -> (name? args)"
		(recv isKindOf: ZealSymbolRef) ifTrue: [
			args isEmpty ifTrue: [
				stream nextPutAll: (self toKebabCase: recv name). stream nextPut: $?. ^ self ].
			stream nextPut: $(.
			stream nextPutAll: (self toKebabCase: recv name). stream nextPut: $?.
			args do: [:a | stream nextPut: $ . a compileToZeal: stream indent: 0 ].
			stream nextPut: $). ^ self ].
		"Complex: prefix form (/idx expr)"
		stream nextPut: $(.
		stream nextPut: $/.
		args do: [:a | a compileToZeal: stream indent: 0 ] separatedBy: [ stream nextPut: $/ ].
		stream nextPut: $ . recv compileToZeal: stream indent: 0.
		stream nextPut: $). ^ self ].
	functionName = 'archetype' ifTrue: [
		| typeName |
		typeName := (arguments first isKindOf: ZealSymbolRef) ifTrue: [self toKebabCase: arguments first name] ifFalse: ['?'].
		stream nextPutAll: '(' , typeName.
		arguments allButFirst do: [:a |
			((a isKindOf: ZealOperator) and: [a operator = ':=']) ifTrue: [
				stream nextPutAll: ' :'.
				stream nextPutAll: (self toKebabCase: a operands first name).
				stream nextPut: $ .
				a operands second compileToZeal: stream indent: 0 ]
			ifFalse: [ stream nextPut: $ . a compileToZeal: stream indent: 0 ] ].
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
