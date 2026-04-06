Class {
	#name : 'VZealCodeGenerator',
	#superclass : 'ZealCodeGenerator',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generation' }
VZealCodeGenerator >> emitBinding: nameNode value: valueNode [
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: nameNode value value.
		self emit: (self toPascalCase: (resolved at: #name)).
		self emit: ' : '. self emit: (resolved at: #type). self emit: ' = '.
		self visitExpression: valueNode ]
	ifFalse: [
		self emit: (self toPascalCase: nameNode value value).
		self emit: ' := '. self visitExpression: valueNode ]
]

{ #category : 'generation' }
VZealCodeGenerator >> emitIfChain: args [
	| cond body rest |
	args size < 2 ifTrue: [ ^ self ].
	cond := args first. body := args second. rest := args allButFirst allButFirst.
	self emit: 'if ('. self visitExpression: cond. self emit: '):'.
	self indent. self nl. self visitExpression: body. self dedent.
	rest isEmpty ifTrue: [ ^ self ].
	((rest first isKindOf: ZealKeywordNode) and: [ rest first value value = ':else' ]) ifTrue: [
		self nl. self emit: 'else:'. self indent. self nl.
		self visitExpression: rest second. self dedent. ^ self ].
	rest size = 1 ifTrue: [
		self nl. self emit: 'else:'. self indent. self nl.
		self visitExpression: rest first. self dedent. ^ self ].
	self nl. self emit: 'else '. self emitIfChain: rest
]

{ #category : 'generation' }
VZealCodeGenerator >> emitLetAsBlock: bindings body: bodyExprs [
	self emit: 'block:'. self indent.
	bindings do: [:pair | self nl. self emitBinding: pair first value: pair second ].
	bodyExprs do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> emitLetAsIf: bindings predicates: predicates body: bodyExprs [
	self emit: 'if:'. self indent.
	bindings do: [:pair | self nl. self emitBinding: pair first value: pair second ].
	predicates do: [:p | self nl. self visitExpression: p ].
	self dedent. self nl. self emit: 'then:'. self indent.
	bodyExprs do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> emitParam: aNode [
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: aNode value value.
		self emit: (self toPascalCase: (resolved at: #name)).
		self emit: ':'.
		self emit: (resolved at: #type) ]
	ifFalse: [ self emit: (self toPascalCase: aNode value value) ]
]

{ #category : 'generation' }
VZealCodeGenerator >> generateBlock: aListNode [
	self emit: 'block:'. self indent.
	aListNode expressions allButFirst do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateBreak: aListNode [
	self emit: 'break'
]

{ #category : 'generation' }
VZealCodeGenerator >> generateCase: aListNode [
	| exprs pairs |
	exprs := aListNode expressions. pairs := exprs allButFirst allButFirst.
	self emit: 'case('. self visitExpression: exprs second. self emit: '):'.
	self indent.
	1 to: pairs size by: 2 do: [:i |
		self nl. self visitExpression: (pairs at: i). self emit: ' => '. self visitExpression: (pairs at: i + 1) ].
	self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDef: aListNode [
	| exprs nameNode valueNode |
	exprs := aListNode expressions. nameNode := exprs second. valueNode := exprs third.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: nameNode value value.
		self emit: (self toPascalCase: (resolved at: #name)).
		(resolved at: #specifiers) do: [:s | self emit: '<' , s , '>' ].
		self emit: ' : '. self emit: (resolved at: #type). self emit: ' = '.
		self visitExpression: valueNode ]
	ifFalse: [
		self emit: (self toPascalCase: nameNode value value).
		self emit: ' := '. self visitExpression: valueNode ]
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDefclass: aListNode [
	| exprs nameNode resolved declSpecs parent rest |
	exprs := aListNode expressions. nameNode := exprs second.
	(nameNode isKindOf: ZealColonChainNode)
		ifTrue: [ resolved := ZealColonChainResolver resolve: nameNode value value ]
		ifFalse: [ resolved := Dictionary new at: #name put: nameNode value value; at: #specifiers put: #(); at: #type put: nil; yourself ].
	declSpecs := (resolved at: #specifiers) select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	rest := exprs allButFirst allButFirst. parent := nil.
	(rest notEmpty and: [ rest first isKindOf: ZealListNode ]) ifTrue: [
		parent := rest first. rest := rest allButFirst ].
	self emit: (self toSnakeCase: (resolved at: #name)).
	declSpecs do: [:s | self emit: '<' , s , '>' ].
	self emit: ' := class'.
	parent ifNotNil: [
		self emit: '('.
		parent expressions do: [:p | self emit: (self toSnakeCase: p value value) ] separatedBy: [ self emit: ', ' ].
		self emit: ')' ].
	self emit: ':'. self indent.
	rest do: [:item | self nl. self visitExpression: item ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDefenum: aListNode [
	| exprs values |
	exprs := aListNode expressions.
	values := exprs allButFirst allButFirst.
	self emit: (self toSnakeCase: (exprs second) value value).
	self emit: ' := enum:'.
	self indent.
	values do: [:v |
		self nl.
		self emit: (self toEnumValue: v value value) ].
	self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDefer: aListNode [
	self emit: 'defer:'. self indent.
	aListNode expressions allButFirst do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDefinterface: aListNode [
	| exprs rest |
	exprs := aListNode expressions. rest := exprs allButFirst allButFirst.
	self emit: (self toSnakeCase: (exprs second) value value). self emit: ' := interface:'.
	self indent. rest do: [:item | self nl. self visitExpression: item ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDefn: aListNode [
	| exprs nameNode resolved params bodyExprs declSpecs sigSpecs retType |
	exprs := aListNode expressions. nameNode := exprs second.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		resolved := ZealColonChainResolver resolve: nameNode value value ]
	ifFalse: [
		resolved := Dictionary new at: #name put: nameNode value value;
			at: #type put: nil; at: #specifiers put: #(); at: #annotations put: #(); yourself ].
	declSpecs := (resolved at: #specifiers) select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	sigSpecs := (resolved at: #specifiers) select: [:s | ZealColonChainResolver isSignatureSpecifier: s].
	retType := resolved at: #type.
	params := nil. bodyExprs := OrderedCollection new.
	exprs allButFirst allButFirst do: [:e |
		(params isNil and: [ e isKindOf: ZealVectorNode ])
			ifTrue: [ params := e ] ifFalse: [ bodyExprs add: e ] ].
	self emit: (self toPascalCase: (resolved at: #name)).
	declSpecs do: [:s | self emit: '<' , s , '>' ].
	self emit: '('.
	params ifNotNil: [
		params expressions do: [:p | self emitParam: p ] separatedBy: [ self emit: ', ' ] ].
	self emit: ')'.
	sigSpecs do: [:s | self emit: '<' , s , '>' ].
	retType ifNotNil: [ self emit: ' : ' , retType ].
	self emit: ' ='.
	self indent. bodyExprs do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDefstruct: aListNode [
	| exprs nameNode fields |
	exprs := aListNode expressions. nameNode := exprs second. fields := exprs allButFirst allButFirst.
	self emit: (self toSnakeCase: nameNode value value). self emit: ' := struct:'. self indent.
	fields do: [:fieldVec | self nl.
		(fieldVec isKindOf: ZealVectorNode) ifTrue: [
			| fieldExprs fieldName |
			fieldExprs := fieldVec expressions. fieldName := fieldExprs first.
			(fieldName isKindOf: ZealColonChainNode) ifTrue: [
				| resolved |
				resolved := ZealColonChainResolver resolve: fieldName value value.
				self emit: (self toPascalCase: (resolved at: #name)).
				self emit: ' : '. self emit: (resolved at: #type).
				fieldExprs size > 1 ifTrue: [ self emit: ' = '. self visitExpression: fieldExprs second ] ]
			ifFalse: [
				self emit: (self toPascalCase: fieldName value value).
				fieldExprs size > 1 ifTrue: [ self emit: ' := '. self visitExpression: fieldExprs second ] ] ] ].
	self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateDo: aListNode [
	self generateBlock: aListNode
]

{ #category : 'generation' }
VZealCodeGenerator >> generateFor: aListNode [
	| exprs bindingVec bodyExprs bindings predicates |
	exprs := aListNode expressions. bindingVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	bindings := OrderedCollection new. predicates := OrderedCollection new.
	self parseBindingVector: bindingVec bindings: bindings predicates: predicates.
	self emit: 'for:'. self indent.
	bindings do: [:pair | self nl. self emitBinding: pair first value: pair second ].
	predicates do: [:p | self nl. self visitExpression: p ].
	self dedent. self nl. self emit: 'do:'. self indent.
	bodyExprs do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateFunctionCall: aListNode [
	| exprs |
	exprs := aListNode expressions.
	self visitExpression: exprs first.
	self emit: '('.
	exprs allButFirst do: [:arg | self visitExpression: arg ] separatedBy: [ self emit: ', ' ].
	self emit: ')'
]

{ #category : 'generation' }
VZealCodeGenerator >> generateIf: aListNode [
	self emitIfChain: aListNode expressions allButFirst
]

{ #category : 'generation' }
VZealCodeGenerator >> generateLet: aListNode [
	| exprs bindingVec bodyExprs bindings predicates |
	exprs := aListNode expressions. bindingVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	bindings := OrderedCollection new. predicates := OrderedCollection new.
	self parseBindingVector: bindingVec bindings: bindings predicates: predicates.
	predicates isEmpty
		ifTrue: [ self emitLetAsBlock: bindings body: bodyExprs ]
		ifFalse: [ self emitLetAsIf: bindings predicates: predicates body: bodyExprs ]
]

{ #category : 'generation' }
VZealCodeGenerator >> generateLoop: aListNode [
	self emit: 'loop:'. self indent.
	aListNode expressions allButFirst do: [:e | self nl. self visitExpression: e ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateModule: aListNode [
	| exprs |
	exprs := aListNode expressions.
	self emit: (self toSnakeCase: (exprs second) value value). self emit: ' := module:'.
	self indent. exprs allButFirst allButFirst do: [:item | self nl. self visitExpression: item ]. self dedent
]

{ #category : 'generation' }
VZealCodeGenerator >> generateOperator: aListNode [
	| exprs op |
	exprs := aListNode expressions.
	op := exprs first value value.
	op = 'not' ifTrue: [ self emit: 'not '. self visitExpression: exprs second. ^ self ].
	(op = '-' and: [ exprs size = 2 ]) ifTrue: [ self emit: '-'. self visitExpression: exprs second. ^ self ].
	self visitExpression: exprs second.
	self emit: ' ' , op , ' '.
	self visitExpression: exprs third
]

{ #category : 'generation' }
VZealCodeGenerator >> generateReturn: aListNode [
	self emit: 'return'.
	aListNode expressions size > 1 ifTrue: [
		self emit: ' '. self visitExpression: aListNode expressions second ]
]

{ #category : 'generation' }
VZealCodeGenerator >> generateSet: aListNode [
	| exprs |
	exprs := aListNode expressions.
	self emit: 'set '. self emit: (self toPascalCase: exprs second value value).
	self emit: ' = '. self visitExpression: exprs third
]

{ #category : 'generation' }
VZealCodeGenerator >> generateUsing: aListNode [
	self emit: 'using { '. self emit: aListNode expressions second value value. self emit: ' }'
]

{ #category : 'generation' }
VZealCodeGenerator >> generateVar: aListNode [
	| exprs nameNode valueNode |
	exprs := aListNode expressions. nameNode := exprs second. valueNode := exprs third.
	self emit: 'var '.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: nameNode value value.
		self emit: (self toPascalCase: (resolved at: #name)).
		self emit: ' : '. self emit: (resolved at: #type). self emit: ' = '.
		self visitExpression: valueNode ]
	ifFalse: [
		self emit: (self toPascalCase: nameNode value value).
		self emit: ' := '. self visitExpression: valueNode ]
]

{ #category : 'generation' }
VZealCodeGenerator >> isOperator: aString [
	^ #('+' '-' '*' '/' '=' '<>' '<' '>' '<=' '>=' 'and' 'or' 'not' '+=' '-=' '*=' '_') includes: aString
]

{ #category : 'generation' }
VZealCodeGenerator >> nl [
	stream cr.
	self emitIndent
]

{ #category : 'generation' }
VZealCodeGenerator >> parseBindingVector: aVectorNode bindings: bindings predicates: predicates [
	| items i |
	items := aVectorNode expressions. i := 1.
	[ i <= items size ] whileTrue: [
		| item |
		item := items at: i.
		(item isKindOf: ZealListNode)
			ifTrue: [ predicates add: item. i := i + 1 ]
			ifFalse: [
				(i + 1 <= items size)
					ifTrue: [ bindings add: { item. items at: i + 1 }. i := i + 2 ]
					ifFalse: [ predicates add: item. i := i + 1 ] ] ]
]

{ #category : 'generation' }
VZealCodeGenerator >> specialForms [
	^ Dictionary new
		at: 'def' put: #generateDef:; at: 'var' put: #generateVar:; at: 'set' put: #generateSet:;
		at: 'defn' put: #generateDefn:; at: 'defstruct' put: #generateDefstruct:;
		at: 'defenum' put: #generateDefenum:; at: 'defclass' put: #generateDefclass:;
		at: 'definterface' put: #generateDefinterface:; at: 'if' put: #generateIf:;
		at: 'let' put: #generateLet:; at: 'for' put: #generateFor:;
		at: 'loop' put: #generateLoop:; at: 'block' put: #generateBlock:;
		at: 'defer' put: #generateDefer:; at: 'case' put: #generateCase:;
		at: 'module' put: #generateModule:; at: 'using' put: #generateUsing:;
		at: 'do' put: #generateDo:; at: 'break' put: #generateBreak:;
		at: 'return' put: #generateReturn:; yourself
]

{ #category : 'generation' }
VZealCodeGenerator >> toEnumValue: aString [
	^ self toPascalCase: aString
]

{ #category : 'generation' }
VZealCodeGenerator >> toPascalCase: aString [
	^ String streamContents: [:s |
		| capitalize |
		capitalize := true.
		aString do: [:ch |
			ch = $-
				ifTrue: [ capitalize := true ]
				ifFalse: [
					capitalize
						ifTrue: [ s nextPut: ch asUppercase. capitalize := false ]
						ifFalse: [ s nextPut: ch ] ] ] ]
]

{ #category : 'generation' }
VZealCodeGenerator >> toSnakeCase: aString [
	^ aString copyReplaceAll: '-' with: '_'
]

{ #category : 'generation' }
VZealCodeGenerator >> visitAtom: aNode [
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		| sym |
		sym := aNode value value.
		(self isOperator: sym)
			ifTrue: [ self emit: sym ]
			ifFalse: [ self emit: (self toPascalCase: sym) ].
		^ self ].
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		self emit: (self toPascalCase: ((ZealColonChainResolver resolve: aNode value value) at: #name)).
		^ self ].
	(aNode isKindOf: ZealKeywordNode) ifTrue: [
		self emit: '"' , aNode value value allButFirst , '"'. ^ self ].
	(aNode isKindOf: ZealRangeLiteralNode) ifTrue: [
		self emit: aNode value value. ^ self ].
	self emit: aNode value value
]

{ #category : 'generation' }
VZealCodeGenerator >> visitList: aNode [
	| exprs head headStr |
	exprs := aNode expressions.
	exprs isEmpty ifTrue: [ self emit: '()'. ^ self ].
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	(head isKindOf: ZealColonChainNode) ifTrue: [ headStr := (ZealColonChainResolver resolve: head value value) at: #name ].
	headStr ifNil: [ ^ self generateFunctionCall: aNode ].
	self specialForms at: headStr ifPresent: [:selector | ^ self perform: selector with: aNode ].
	(self isOperator: headStr) ifTrue: [ ^ self generateOperator: aNode ].
	self generateFunctionCall: aNode
]

{ #category : 'generation' }
VZealCodeGenerator >> visitMap: aNode [
	self emit: 'map{'.
	aNode pairs do: [:pair |
		self visitExpression: pair key. self emit: ' => '. self visitExpression: pair value ]
		separatedBy: [ self emit: ', ' ].
	self emit: '}'
]

{ #category : 'generation' }
VZealCodeGenerator >> visitVector: aNode [
	self emit: 'array{'.
	aNode expressions do: [:e | self visitExpression: e ] separatedBy: [ self emit: ', ' ].
	self emit: '}'
]
