Class {
	#name : 'ZealTypeInferencer',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
ZealTypeInferencer class >> default [
	"Lazy singleton — most queries are stateless lookups against a fixed set."
	^ self new
]

{ #category : 'api' }
ZealTypeInferencer >> inferTypeFor: aZealNode [
	"Best-effort type inference. Returns a canonical type-name string ('int',
	 'float', 'bool', 'string', or a recognized type symbol) for literal
	 expressions and simple shapes. Returns nil when the type cannot be
	 inferred from the AST alone (in that case the codegen should fall back
	 to its host's `auto` keyword or leave the type implicit).
	 Subclasses may override to recognize host-specific literal forms."
	aZealNode ifNil: [ ^ nil ].

	"Integer literal"
	(aZealNode isKindOf: ZealIntegerLiteralNode) ifTrue: [ ^ 'int' ].

	"Hex literal — also int"
	(aZealNode isKindOf: ZealHexLiteralNode) ifTrue: [ ^ 'int' ].

	"Float literal"
	(aZealNode isKindOf: ZealFloatLiteralNode) ifTrue: [ ^ 'float' ].

	"String literal"
	(aZealNode isKindOf: ZealStringLiteralNode) ifTrue: [ ^ 'string' ].

	"Char literal"
	(aZealNode isKindOf: ZealCharLiteralNode) ifTrue: [ ^ 'char' ].

	"true/false symbol → bool"
	((aZealNode isKindOf: ZealSymbolNode)
		and: [ #('true' 'false') includes: aZealNode value value ])
		ifTrue: [ ^ 'bool' ].

	"Empty vector literal — array of any (caller may refine)"
	(aZealNode isKindOf: ZealVectorNode) ifTrue: [
		aZealNode expressions isEmpty ifTrue: [ ^ '[]any' ].
		"Vector of homogeneous elements — try first element's type"
		^ (self inferTypeFor: aZealNode expressions first) ifNotNil: [ :t | '[]' , t ] ].

	"List form — operator/special-form result types we can confidently infer"
	(aZealNode isKindOf: ZealListNode) ifTrue: [ ^ self inferTypeForList: aZealNode ].

	"Range literal — int range"
	(aZealNode isKindOf: ZealRangeLiteralNode) ifTrue: [ ^ '[]int' ].

	^ nil
]

{ #category : 'api' }
ZealTypeInferencer >> inferTypeForList: aListNode [
	"Infer the result type of a list-form expression. Recognizes:
	 - arithmetic operators (+,-,*,/,%) — numeric promotion (any float operand → float)
	 - comparison operators (=,<>,<,>,<=,>=,not,and,or) → bool
	 - (if c t e) — branch-merge; type from any branch we can infer
	 - (let [...] body) — type of last body expression
	 - (do ...) — type of last expression
	 Otherwise nil."
	| exprs head headStr |
	exprs := aListNode expressions.
	exprs isEmpty ifTrue: [ ^ nil ].
	head := exprs first.
	(head isKindOf: ZealSymbolNode) ifFalse: [ ^ nil ].
	headStr := head value value.

	"Numeric arithmetic"
	(#('+' '-' '*' '/' '%') includes: headStr) ifTrue: [
		| operandTypes |
		operandTypes := exprs allButFirst collect: [ :e | self inferTypeFor: e ].
		(operandTypes anySatisfy: [ :t | t = 'float' or: [ t = 'double' ] ])
			ifTrue: [ ^ 'float' ].
		(operandTypes allSatisfy: [ :t | t = 'int' ])
			ifTrue: [ ^ 'int' ].
		^ nil ].

	"Comparisons / logic → bool"
	(#('=' '<>' '<' '>' '<=' '>=' 'and' 'or' 'not' '!=' '==') includes: headStr)
		ifTrue: [ ^ 'bool' ].

	"if expression — first branch's type wins"
	headStr = 'if' ifTrue: [
		exprs size >= 3 ifTrue: [ ^ self inferTypeFor: exprs third ].
		^ nil ].

	"do — last expression's type"
	headStr = 'do' ifTrue: [
		exprs size >= 2 ifTrue: [ ^ self inferTypeFor: exprs last ].
		^ nil ].

	"let — last body expression's type (skip the bindings vector)"
	headStr = 'let' ifTrue: [
		exprs size >= 3 ifTrue: [ ^ self inferTypeFor: exprs last ].
		^ nil ].

	^ nil
]

{ #category : 'api' }
ZealTypeInferencer >> knownTypes [
	"All type names this inferencer recognizes. Subclasses override to add
	 dialect/host-specific types on top of the primitives."
	^ self primitiveTypes
]

{ #category : 'api' }
ZealTypeInferencer >> primitiveTypes [
	"Type names common to every Zeal dialect — Lisp/Verse-style primitives.
	 Subclasses extend with their host's built-in / engine types."
	^ #('int' 'float' 'double' 'bool' 'logic' 'string' 'char' 'void' 'any' 'type'
	    'Int' 'Float' 'Double' 'Bool' 'Logic' 'String' 'Char' 'Void' 'Any' 'Type')
]

{ #category : 'api' }
ZealTypeInferencer >> recognizesType: aString [
	"Return true if aString names a type the dialect understands. Strips
	 leading array/map shorthand so e.g. `[]int` or `[FString]int` recognize
	 as a type by their element type."
	| s |
	s := aString.
	(s beginsWith: '[]') ifTrue: [ ^ self recognizesType: (s copyFrom: 3 to: s size) ].
	((s beginsWith: '[') and: [ s includes: $] ])
		ifTrue: [
			| close keyT valT |
			close := s indexOf: $].
			keyT := s copyFrom: 2 to: close - 1.
			valT := s copyFrom: close + 1 to: s size.
			^ (self recognizesType: keyT) and: [ self recognizesType: valT ] ].
	^ self knownTypes includes: s
]
