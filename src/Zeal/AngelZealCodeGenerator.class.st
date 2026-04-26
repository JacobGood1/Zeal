Class {
	#name : 'AngelZealCodeGenerator',
	#superclass : 'ZealCodeGenerator',
	#instVars : [
		'localScope',
		'currentClass'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealCodeGenerator >> addLocal: aName [
	localScope isEmpty ifTrue: [ self pushScope ].
	localScope first add: aName
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitDefBinding: nameNode value: valueNode [
	"Emit one `const Type Name = value` line."
	| name typeStr inferred |
	typeStr := nil.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: nameNode value value.
		name := resolved at: #name.
		typeStr := self resolveType: (resolved at: #type) ]
	ifFalse: [ name := nameNode value value ].
	(typeStr isNil and: [ valueNode notNil ]) ifTrue: [
		inferred := self typeInferencer ifNotNil: [ :inf | inf inferTypeFor: valueNode ].
		inferred ifNotNil: [ typeStr := self resolveType: inferred ] ].
	self emit: 'const '.
	typeStr ifNotNil: [ self emit: typeStr. self emit: ' ' ].
	typeStr ifNil: [ self emit: 'auto ' ].
	self emit: (self toPascalCase: name).
	valueNode ifNotNil: [
		self emit: ' = '.
		self visitExpression: valueNode ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitIfChain: args first: isFirst [
	"Recursively emit if / else if / else chain."
	args isEmpty ifTrue: [ ^ self ].
	args size = 1 ifTrue: [
		self emit: ' else {'.
		self indent. self nl. self visitStatement: args first. self dedent.
		self nl. self emit: '}'.
		^ self ].
	isFirst ifFalse: [ self emit: ' else if (' ] ifTrue: [ self emit: 'if (' ].
	self visitExpression: args first.
	self emit: ') {'.
	self indent. self nl. self visitStatement: args second. self dedent.
	self nl. self emit: '}'.
	args size > 2 ifTrue: [
		self emitIfChain: (args copyFrom: 3 to: args size) first: false ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitParam: aParamNode [
	"Emit one typed parameter. Registers the param in the current scope."
	| name typeStr |
	typeStr := nil.
	(aParamNode isKindOf: ZealColonChainNode)
		ifTrue: [
			| resolved |
			resolved := self resolveColonChain: aParamNode value value.
			name := resolved at: #name.
			typeStr := self resolveType: (resolved at: #type) ]
		ifFalse: [ name := aParamNode value value ].
	typeStr ifNotNil: [ self emit: typeStr. self emit: ' ' ].
	typeStr ifNil: [ self emit: 'auto ' ].
	self emit: (self toPascalCase: name).
	self addLocal: (self toPascalCase: name)
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitReturnControl: aListNode [
	"Emit a control form (if/when/do/let) as a statement, but with each branch's
	 last expression in return position."
	| head |
	head := aListNode expressions first value value.
	head = 'if' ifTrue: [ ^ self emitReturnIf: aListNode ].
	head = 'when' ifTrue: [ ^ self emitReturnWhen: aListNode ].
	head = 'do' ifTrue: [ ^ self emitReturnDo: aListNode ].
	head = 'let' ifTrue: [ ^ self emitReturnLet: aListNode ].
	"Fallback — shouldn't happen if isReturnControlForm: gated correctly."
	self visitStatement: aListNode
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitReturnDo: aListNode [
	"(do e1 e2 ... eN) in return position — first N-1 are statements, last
	 goes in return position. Wrapped in a block scope to mirror generateDo:."
	| body |
	body := aListNode expressions allButFirst.
	self emit: '{'.
	self indent.
	body doWithIndex: [ :e :idx |
		self nl.
		idx = body size
			ifTrue: [ self visitReturnPosition: e ]
			ifFalse: [ self visitStatement: e ] ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitReturnIf: aListNode [
	"(if c1 t1 c2 t2 ... else) — emit if/else-if/else with each branch body
	 in return position."
	| args |
	args := aListNode expressions allButFirst.
	self emitReturnIfChain: args first: true
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitReturnIfChain: args first: isFirst [
	"Like emitIfChain:first: but each then/else body emitted in return position."
	args isEmpty ifTrue: [ ^ self ].
	args size = 1 ifTrue: [
		self emit: ' else {'.
		self indent. self nl. self visitReturnPosition: args first. self dedent.
		self nl. self emit: '}'.
		^ self ].
	isFirst ifFalse: [ self emit: ' else if (' ] ifTrue: [ self emit: 'if (' ].
	self visitExpression: args first.
	self emit: ') {'.
	self indent. self nl. self visitReturnPosition: args second. self dedent.
	self nl. self emit: '}'.
	args size > 2 ifTrue: [
		self emitReturnIfChain: (args copyFrom: 3 to: args size) first: false ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitReturnLet: aListNode [
	"(let [bindings] body...) in return position — bindings emitted as `var`s,
	 last body expr in return position."
	| args binding body bindings |
	args := aListNode expressions allButFirst.
	binding := args first.
	body := args allButFirst.
	(binding isKindOf: ZealVectorNode) ifFalse: [
		self emit: '/* let: first arg must be a vector */'. ^ self ].
	bindings := binding expressions.
	self emit: '{'.
	self pushScope.
	self indent.
	1 to: bindings size by: 2 do: [ :i |
		| nameNode valNode name typeStr pascal |
		nameNode := bindings at: i.
		valNode := i + 1 <= bindings size ifTrue: [ bindings at: i + 1 ] ifFalse: [ nil ].
		typeStr := nil.
		(nameNode isKindOf: ZealColonChainNode)
			ifTrue: [
				| resolved |
				resolved := self resolveColonChain: nameNode value value.
				name := resolved at: #name.
				typeStr := self resolveType: (resolved at: #type) ]
			ifFalse: [ name := nameNode value value ].
		pascal := self toPascalCase: name.
		self nl.
		typeStr ifNotNil: [ self emit: typeStr. self emit: ' ' ] ifNil: [ self emit: 'auto ' ].
		self emit: pascal.
		valNode ifNotNil: [ self emit: ' = '. self visitExpression: valNode ].
		stream nextPut: $;.
		self addLocal: pascal ].
	body doWithIndex: [ :e :idx |
		self nl.
		idx = body size
			ifTrue: [ self visitReturnPosition: e ]
			ifFalse: [ self visitStatement: e ] ].
	self dedent.
	self nl. self emit: '}'.
	self popScope
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitReturnWhen: aListNode [
	"(when cond body...) — only the last body expr is in return position;
	 earlier bodies are statements. If the condition fails the function
	 implicitly returns the default value (caller's problem)."
	| args body |
	args := aListNode expressions allButFirst.
	self emit: 'if ('.
	self visitExpression: args first.
	self emit: ') {'.
	self indent.
	body := args allButFirst.
	body doWithIndex: [ :e :idx |
		self nl.
		idx = body size
			ifTrue: [ self visitReturnPosition: e ]
			ifFalse: [ self visitStatement: e ] ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> emitVarBinding: nameNode value: valueNode [
	"Emit one `Type Name = value` line. Type is taken from a colon-chain on the
	 name, or inferred via the dialect's typeInferencer when absent.
	 Registers the resulting Pascal-cased name in the current scope."
	| name typeStr pascalName inferred |
	typeStr := nil.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: nameNode value value.
		name := resolved at: #name.
		typeStr := self resolveType: (resolved at: #type) ]
	ifFalse: [ name := nameNode value value ].
	(typeStr isNil and: [ valueNode notNil ]) ifTrue: [
		inferred := self typeInferencer ifNotNil: [ :inf | inf inferTypeFor: valueNode ].
		inferred ifNotNil: [ typeStr := self resolveType: inferred ] ].
	pascalName := self toPascalCase: name.
	typeStr ifNotNil: [ self emit: typeStr. self emit: ' ' ].
	typeStr ifNil: [ self emit: 'auto ' ].
	self emit: pascalName.
	valueNode ifNotNil: [
		self emit: ' = '.
		self visitExpression: valueNode ].
	self addLocal: pascalName
]

{ #category : 'api' }
AngelZealCodeGenerator >> generate: aZealProgramNode [
	"Top-level entry: emit each top-level form followed by a blank line."
	aZealProgramNode expressions
		do: [ :expr | self visitTopLevel: expr ]
		separatedBy: [ self nl. self nl ].
	^ self output
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateAngelRaw: aListNode [
	"angel-raw special form: emits the inner string literal verbatim."
	| arg s |
	aListNode expressions size < 2 ifTrue: [ ^ self ].
	arg := aListNode expressions second.
	s := arg value value.
	(s size >= 2 and: [ s first = $" and: [ s last = $" ] ]) ifTrue: [
		s := s copyFrom: 2 to: s size - 1 ].
	s := (s copyReplaceAll: '\"' with: (String with: $")) copyReplaceAll: '\\' with: '\'.
	self emit: s
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateAs: aListNode [
	"(as expr type) -> cast<Type>(expr)"
	| args typeStr |
	args := aListNode expressions allButFirst.
	typeStr := (args second isKindOf: ZealSymbolNode)
		ifTrue: [ self resolveType: args second value value ]
		ifFalse: [ self resolveType: (args second value value) ].
	self emit: 'cast<'.
	self emit: typeStr.
	self emit: '>('.
	self visitExpression: args first.
	self emit: ')'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateDef: aListNode [
	"(def name [:type] value) -> const Type Name = value
	 (def n1 v1 n2 v2 …) -> const T1 N1 = V1; const T2 N2 = V2; …
	 Type is taken from a colon-chain on the name, or inferred via the
	 dialect's typeInferencer when absent."
	| exprs pairs |
	exprs := aListNode expressions allButFirst.
	exprs isEmpty ifTrue: [ ^ self ].
	pairs := OrderedCollection new.
	1 to: exprs size by: 2 do: [ :i |
		pairs add: ((exprs at: i)
			-> (i + 1 <= exprs size ifTrue: [ exprs at: i + 1 ] ifFalse: [ nil ])) ].
	pairs doWithIndex: [ :pair :idx |
		idx > 1 ifTrue: [ stream nextPut: $;. self nl ].
		self emitDefBinding: pair key value: pair value ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateDefclass: aListNode [
	"(defclass Name:Parent body...) -> class Name : Parent { body... }
	 (defclass Name body...) -> class Name { body... }
	 Body forms may be (var …), (defn …), or nested special forms."
	| exprs nameNode name parent body pascalName |
	exprs := aListNode expressions.
	nameNode := exprs second.
	parent := nil.
	(nameNode isKindOf: ZealColonChainNode)
		ifTrue: [
			| resolved |
			resolved := self resolveColonChain: nameNode value value.
			name := resolved at: #name.
			parent := self resolveType: (resolved at: #type) ]
		ifFalse: [ name := nameNode value value ].
	pascalName := self toPascalCase: name.
	body := exprs allButFirst allButFirst.
	self emit: 'class '.
	self emit: pascalName.
	parent ifNotNil: [ self emit: ' : '. self emit: parent ].
	self emit: ' {'.
	self indent.
	body do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateDefn: aListNode [
	"(defn name:retType [params] body...) -> retType Name(...) { body }
	 With non-void retType, the last body expr is emitted in return position
	 — recursing into if/when/do/let so each branch leaf gets `return`."
	| exprs nameNode retType name params bodyExprs pascalName implicitReturn |
	exprs := aListNode expressions.
	nameNode := exprs second.
	retType := 'void'.
	(nameNode isKindOf: ZealColonChainNode)
		ifTrue: [
			| resolved |
			resolved := self resolveColonChain: nameNode value value.
			name := resolved at: #name.
			(resolved at: #type) ifNotNil: [ :t | retType := self resolveType: t ] ]
		ifFalse: [ name := nameNode value value ].
	pascalName := self toPascalCase: name.
	params := nil.
	bodyExprs := OrderedCollection new.
	exprs allButFirst allButFirst do: [ :e |
		(params isNil and: [ e isKindOf: ZealVectorNode ])
			ifTrue: [ params := e ]
			ifFalse: [ bodyExprs add: e ] ].
	"Unwrap a single top-level (do ...) so its children become the body."
	(bodyExprs size = 1
		and: [ (bodyExprs first isKindOf: ZealListNode)
		and: [ bodyExprs first expressions notEmpty
		and: [ (bodyExprs first expressions first isKindOf: ZealSymbolNode)
		and: [ bodyExprs first expressions first value value = 'do' ] ] ] ]) ifTrue: [
			bodyExprs := bodyExprs first expressions allButFirst asOrderedCollection ].
	implicitReturn := retType notNil and: [ retType ~= 'void' and: [ retType ~= 'Void' ] ].

	self pushScope.
	self emit: retType.
	self emit: ' '.
	self emit: pascalName.
	self emit: '('.
	params ifNotNil: [
		params expressions
			do: [ :p | self emitParam: p ]
			separatedBy: [ self emit: ', ' ] ].
	self emit: ')'.
	self emit: ' {'.
	self indent.
	bodyExprs doWithIndex: [ :expr :idx |
		self nl.
		(implicitReturn and: [ idx = bodyExprs size ])
			ifTrue: [ self visitReturnPosition: expr ]
			ifFalse: [ self visitStatement: expr ] ].
	self dedent.
	self nl.
	self emit: '}'.
	self popScope
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateDefnamespace: aListNode [
	"(defnamespace name body...) -> namespace Name { body... }
	 With no body, emits an empty namespace block."
	| exprs nameNode body name |
	exprs := aListNode expressions.
	nameNode := exprs second.
	(nameNode isKindOf: ZealColonChainNode)
		ifTrue: [ name := (self resolveColonChain: nameNode value value) at: #name ]
		ifFalse: [ name := nameNode value value ].
	body := exprs allButFirst allButFirst.
	self emit: 'namespace '.
	self emit: (self toPascalCase: name).
	self emit: ' {'.
	self indent.
	body do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateDefstruct: aListNode [
	"(defstruct Name field1:type1 field2:type2 ...) -> struct Name { type1 Field1; type2 Field2; };
	 Fields are colon-chain symbols in the body — one per form."
	| exprs nameNode name body pascalName |
	exprs := aListNode expressions.
	nameNode := exprs second.
	(nameNode isKindOf: ZealColonChainNode)
		ifTrue: [ name := (self resolveColonChain: nameNode value value) at: #name ]
		ifFalse: [ name := nameNode value value ].
	pascalName := self toPascalCase: name.
	body := exprs allButFirst allButFirst.
	self emit: 'struct '.
	self emit: pascalName.
	self emit: ' {'.
	self indent.
	body do: [ :field |
		| fname ftype resolved |
		self nl.
		(field isKindOf: ZealColonChainNode)
			ifTrue: [
				resolved := self resolveColonChain: field value value.
				fname := resolved at: #name.
				ftype := self resolveType: (resolved at: #type) ]
			ifFalse: [ fname := field value value. ftype := 'auto' ].
		self emit: ftype.
		self emit: ' '.
		self emit: (self toPascalCase: fname).
		stream nextPut: $; ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateDo: aListNode [
	"(do expr1 expr2 ...) -> { expr1; expr2; ... } — a sequence block"
	| body |
	body := aListNode expressions allButFirst.
	self emit: '{'.
	self indent.
	body do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateFor: aListNode [
	"(for [x coll] body...) -> for (auto X : Coll) { body... }
	 (for [x:Type coll] body...) -> for (Type X : Coll) { body... }
	 (for [i 0..N] body...) -> for (int I = 0; I < N; I++) { body... } (range case)"
	| args binding bodyExprs varNode collNode varName typeStr pascalVar |
	args := aListNode expressions allButFirst.
	binding := args first.
	bodyExprs := args allButFirst.
	(binding isKindOf: ZealVectorNode) ifFalse: [
		"Fallback: emit as a while-ish placeholder if the shape isn't [v coll]"
		self emit: '/* for: unsupported shape */'. ^ self ].
	varNode := binding expressions first.
	collNode := binding expressions second.
	typeStr := nil.
	(varNode isKindOf: ZealColonChainNode)
		ifTrue: [
			| resolved |
			resolved := self resolveColonChain: varNode value value.
			varName := resolved at: #name.
			typeStr := self resolveType: (resolved at: #type) ]
		ifFalse: [ varName := varNode value value ].
	pascalVar := self toPascalCase: varName.

	"Range literal -> C-style for"
	(collNode isKindOf: ZealRangeLiteralNode) ifTrue: [
		| parts lo hi |
		parts := $. split: collNode value value.
		lo := parts first.
		hi := (parts reject: [ :p | p isEmpty ]) last.
		self emit: 'for (int '.
		self emit: pascalVar.
		self emit: ' = '. self emit: lo.
		self emit: '; '. self emit: pascalVar. self emit: ' < '. self emit: hi.
		self emit: '; '. self emit: pascalVar. self emit: '++) {'.
		self pushScope. self addLocal: pascalVar.
		self indent.
		bodyExprs do: [ :e | self nl. self visitStatement: e ].
		self dedent.
		self nl. self emit: '}'.
		self popScope. ^ self ].

	"Regular range-based for"
	self emit: 'for ('.
	typeStr ifNotNil: [ self emit: typeStr. self emit: ' ' ] ifNil: [ self emit: 'auto ' ].
	self emit: pascalVar.
	self emit: ' : '.
	self visitExpression: collNode.
	self emit: ') {'.
	self pushScope. self addLocal: pascalVar.
	self indent.
	bodyExprs do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'.
	self popScope
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateFunctionCall: aListNode [
	"(Fn args...) -> Fn(args)"
	| exprs |
	exprs := aListNode expressions.
	self visitExpression: exprs first.
	self emit: '('.
	exprs allButFirst
		do: [ :a | self visitExpression: a ]
		separatedBy: [ self emit: ', ' ].
	self emit: ')'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateIf: aListNode [
	"(if cond then) / (if cond then else) / (if c1 t1 c2 t2 ... else)"
	| args |
	args := aListNode expressions allButFirst.
	self emitIfChain: args first: true
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateLet: aListNode [
	"(let [n1 v1 n2 v2 ...] body...) -> { Type N1 = v1; Type N2 = v2; body... }
	 Emits a block scope so the bindings don't leak."
	| args binding body bindings |
	args := aListNode expressions allButFirst.
	binding := args first.
	body := args allButFirst.
	(binding isKindOf: ZealVectorNode) ifFalse: [
		self emit: '/* let: first arg must be a vector */'. ^ self ].
	bindings := binding expressions.
	self emit: '{'.
	self pushScope.
	self indent.
	1 to: bindings size by: 2 do: [ :i |
		| nameNode valNode name typeStr pascal |
		nameNode := bindings at: i.
		valNode := i + 1 <= bindings size ifTrue: [ bindings at: i + 1 ] ifFalse: [ nil ].
		typeStr := nil.
		(nameNode isKindOf: ZealColonChainNode)
			ifTrue: [
				| resolved |
				resolved := self resolveColonChain: nameNode value value.
				name := resolved at: #name.
				typeStr := self resolveType: (resolved at: #type) ]
			ifFalse: [ name := nameNode value value ].
		pascal := self toPascalCase: name.
		self nl.
		typeStr ifNotNil: [ self emit: typeStr. self emit: ' ' ] ifNil: [ self emit: 'auto ' ].
		self emit: pascal.
		valNode ifNotNil: [ self emit: ' = '. self visitExpression: valNode ].
		stream nextPut: $;.
		self addLocal: pascal ].
	body do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'.
	self popScope
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateOperator: aListNode [
	"(+ a b c) -> a + b + c    (not x) -> !x    (- x) -> -x    (= a b) -> a == b"
	| exprs op mapped operands |
	exprs := aListNode expressions.
	op := exprs first value value.
	operands := exprs allButFirst.
	mapped := self mapOperator: op.
	op = 'not' ifTrue: [
		self emit: '!'.
		self visitExpression: operands first. ^ self ].
	(op = '-' and: [ operands size = 1 ]) ifTrue: [
		self emit: '-'.
		self visitExpression: operands first. ^ self ].
	operands
		do: [ :o | self visitExpression: o ]
		separatedBy: [ self emit: ' ' , mapped , ' ' ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateReturn: aListNode [
	"(return expr) -> return expr     (return) -> return"
	| args |
	args := aListNode expressions allButFirst.
	self emit: 'return'.
	args isEmpty ifFalse: [ self emit: ' '. self visitExpression: args first ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateSet: aListNode [
	"(set name value) -> Name = value
	 (set name += value) / (set name -= value) — operator detection via 2nd arg symbol."
	| exprs nameNode secondNode |
	exprs := aListNode expressions.
	nameNode := exprs second.
	secondNode := exprs size >= 3 ifTrue: [ exprs third ] ifFalse: [ nil ].
	self visitExpression: nameNode.
	(secondNode notNil
		and: [ (secondNode isKindOf: ZealSymbolNode)
		and: [ #('+=' '-=' '*=' '/=' '%=' '|=' '&=' '^=') includes: secondNode value value ] ])
		ifTrue: [
			self emit: ' '.
			self emit: secondNode value value.
			self emit: ' '.
			exprs size >= 4 ifTrue: [ self visitExpression: exprs fourth ].
			^ self ].
	self emit: ' = '.
	secondNode ifNotNil: [ self visitExpression: secondNode ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateVar: aListNode [
	"(var name value) — single binding, with optional :type
	 (var n1 v1 n2 v2 ...) — multi-binding; emits one declaration per pair
	   separated by `;` so each becomes its own AngelScript local."
	| exprs pairs |
	exprs := aListNode expressions allButFirst.
	exprs isEmpty ifTrue: [ ^ self ].
	"Even number → list of (name, value) pairs. Odd → last one's a bare name (no init)."
	pairs := OrderedCollection new.
	1 to: exprs size by: 2 do: [ :i |
		pairs add: ((exprs at: i)
			-> (i + 1 <= exprs size ifTrue: [ exprs at: i + 1 ] ifFalse: [ nil ])) ].
	pairs doWithIndex: [ :pair :idx |
		idx > 1 ifTrue: [ stream nextPut: $;. self nl ].
		self emitVarBinding: pair key value: pair value ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateWhen: aListNode [
	"(when cond body...) -> if (cond) { body... }"
	| args body |
	args := aListNode expressions allButFirst.
	self emit: 'if ('.
	self visitExpression: args first.
	self emit: ') {'.
	self indent.
	body := args allButFirst.
	body do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> generateWhile: aListNode [
	"(while cond body...) -> while (cond) { body... }"
	| args |
	args := aListNode expressions allButFirst.
	self emit: 'while ('.
	self visitExpression: args first.
	self emit: ') {'.
	self indent.
	args allButFirst do: [ :e | self nl. self visitStatement: e ].
	self dedent.
	self nl. self emit: '}'
]

{ #category : 'api' }
AngelZealCodeGenerator >> initialize [
	super initialize.
	localScope := OrderedCollection new.
	currentClass := nil
]

{ #category : 'api' }
AngelZealCodeGenerator >> isLocal: aName [
	^ localScope anySatisfy: [ :frame | frame includes: aName ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> isOperator: aString [
	^ self operatorSet includes: aString
]

{ #category : 'api' }
AngelZealCodeGenerator >> isReturnControlForm: aNode [
	"True if aNode is an if/when/do/let — control structures whose last leaf
	 should be wrapped in `return` when in return position."
	(aNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	aNode expressions isEmpty ifTrue: [ ^ false ].
	(aNode expressions first isKindOf: ZealSymbolNode) ifFalse: [ ^ false ].
	^ #('if' 'when' 'do' 'let') includes: aNode expressions first value value
]

{ #category : 'api' }
AngelZealCodeGenerator >> isStatementShaped: aNode [
	"A ZealListNode whose head symbol names a form that emits its own block/structure."
	(aNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	aNode expressions isEmpty ifTrue: [ ^ false ].
	((aNode expressions first) isKindOf: ZealSymbolNode) ifFalse: [ ^ false ].
	^ self statementForms includes: aNode expressions first value value
]

{ #category : 'api' }
AngelZealCodeGenerator >> mapOperator: aZealOp [
	"Translate Zeal operator token to AngelScript operator token."
	aZealOp = '=' ifTrue: [ ^ '==' ].
	aZealOp = '<>' ifTrue: [ ^ '!=' ].
	aZealOp = 'and' ifTrue: [ ^ '&&' ].
	aZealOp = 'or' ifTrue: [ ^ '||' ].
	aZealOp = 'not' ifTrue: [ ^ '!' ].
	^ aZealOp
]

{ #category : 'api' }
AngelZealCodeGenerator >> nl [
	"Emit a newline followed by current indent"
	stream nextPut: Character lf.
	self emitIndent
]

{ #category : 'api' }
AngelZealCodeGenerator >> operatorSet [
	"Tokens that translate to AngelScript binary/unary operators."
	^ #('+' '-' '*' '/' '%' '=' '<>' '!=' '<' '>' '<=' '>=' 'and' 'or' 'not' '&' '|' '^' '<<' '>>')
]

{ #category : 'api' }
AngelZealCodeGenerator >> popScope [
	localScope isEmpty ifFalse: [ localScope removeFirst ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> pushScope [
	localScope addFirst: Set new
]

{ #category : 'api' }
AngelZealCodeGenerator >> resolveColonChain: aChainString [
	"Parse a colon-chain string via ZealColonChainResolver, returning a dictionary
	 with at least :name and :type keys (type may be nil)."
	^ ZealColonChainResolver resolve: aChainString
]

{ #category : 'api' }
AngelZealCodeGenerator >> resolveType: aTypeString [
	"Map AngelZeal type tokens to AngelScript type names.
	 - Primitive aliases: string→FString, name→FName, vector→FVector, etc.
	 - Array shorthand: []T → TArray<T> (recursive: [][]T → TArray<TArray<T>>)
	 - Map shorthand: [K]V → TMap<K, V>
	 - Set shorthand: ?T → not used here (left as-is for caller)
	 - Anything else passes through unchanged."
	aTypeString ifNil: [ ^ nil ].
	(aTypeString beginsWith: '[]') ifTrue: [
		^ 'TArray<' , (self resolveType: (aTypeString copyFrom: 3 to: aTypeString size)) , '>' ].
	((aTypeString beginsWith: '[') and: [ aTypeString includes: $] ]) ifTrue: [
		| closeIdx keyT valT |
		closeIdx := aTypeString indexOf: $].
		keyT := aTypeString copyFrom: 2 to: closeIdx - 1.
		valT := aTypeString copyFrom: closeIdx + 1 to: aTypeString size.
		^ 'TMap<' , (self resolveType: keyT) , ', ' , (self resolveType: valT) , '>' ].
	aTypeString = 'string' ifTrue: [ ^ 'FString' ].
	aTypeString = 'name' ifTrue: [ ^ 'FName' ].
	aTypeString = 'bool' ifTrue: [ ^ 'bool' ].
	aTypeString = 'int' ifTrue: [ ^ 'int' ].
	aTypeString = 'float' ifTrue: [ ^ 'float' ].
	aTypeString = 'double' ifTrue: [ ^ 'double' ].
	aTypeString = 'void' ifTrue: [ ^ 'void' ].
	aTypeString = 'vector' ifTrue: [ ^ 'FVector' ].
	aTypeString = 'vector2' ifTrue: [ ^ 'FVector2D' ].
	aTypeString = 'rotator' ifTrue: [ ^ 'FRotator' ].
	aTypeString = 'transform' ifTrue: [ ^ 'FTransform' ].
	^ aTypeString
]

{ #category : 'api' }
AngelZealCodeGenerator >> specialForms [
	"AngelZeal's syntactic keywords."
	^ Dictionary new
		at: 'def' put: #generateDef:;
		at: 'var' put: #generateVar:;
		at: 'set' put: #generateSet:;
		at: 'defn' put: #generateDefn:;
		at: 'defclass' put: #generateDefclass:;
		at: 'defstruct' put: #generateDefstruct:;
		at: 'defnamespace' put: #generateDefnamespace:;
		at: 'if' put: #generateIf:;
		at: 'when' put: #generateWhen:;
		at: 'for' put: #generateFor:;
		at: 'while' put: #generateWhile:;
		at: 'let' put: #generateLet:;
		at: 'do' put: #generateDo:;
		at: 'return' put: #generateReturn:;
		at: 'as' put: #generateAs:;
		at: 'angel-raw' put: #generateAngelRaw:;
		yourself
]

{ #category : 'api' }
AngelZealCodeGenerator >> statementForms [
	^ #('if' 'when' 'for' 'while' 'do' 'let' 'defn' 'defclass' 'defstruct' 'defnamespace' 'angel-raw')
]

{ #category : 'api' }
AngelZealCodeGenerator >> toPascalCase: aString [
	"kebab-case -> PascalCase. Capitalize first letter and after hyphens."
	^ String streamContents: [ :s |
		| capitalize |
		capitalize := true.
		aString do: [ :ch |
			ch = $-
				ifTrue: [ capitalize := true ]
				ifFalse: [
					capitalize
						ifTrue: [ s nextPut: ch asUppercase. capitalize := false ]
						ifFalse: [ s nextPut: ch ] ] ] ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> typeInferencer [
	^ AngelZealTypeInferencer default
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitAtom: aNode [
	"Emit an atom: symbol (identifier), keyword (string), colon chain (name),
	 range literal, or primitive literal."
	| sym |
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		sym := aNode value value.
		sym = '_' ifTrue: [ self emit: '_'. ^ self ].
		(#('true' 'false' 'null') includes: sym) ifTrue: [ self emit: sym. ^ self ].
		(self isLocal: sym) ifTrue: [ self emit: sym. ^ self ].
		self emit: (self toPascalCase: sym). ^ self ].
	(aNode isKindOf: ZealKeywordNode) ifTrue: [
		"Keyword (:foo) becomes a literal FName — common AngelScript convention."
		self emit: 'FName("' , aNode value value allButFirst , '")'. ^ self ].
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: aNode value value.
		self emit: (self toPascalCase: (resolved at: #name)). ^ self ].
	(aNode isKindOf: ZealRangeLiteralNode) ifTrue: [
		"AngelScript has no range literal — emit a synthetic helper call so the
		 consumer can decide what to do. Most for-loops rewrite this elsewhere."
		self emit: 'Range('.
		self emit: (aNode value value copyReplaceAll: '..' with: ', ').
		self emit: ')'. ^ self ].
	self emit: aNode value value
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitExpression: aNode [
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self visitList: aNode ].
	(aNode isKindOf: ZealVectorNode) ifTrue: [ ^ self visitVector: aNode ].
	(aNode isKindOf: ZealMapNode) ifTrue: [ ^ self visitMap: aNode ].
	^ self visitAtom: aNode
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitList: aNode [
	"Dispatch a list form: special form → operator → function call."
	| exprs head headStr |
	exprs := aNode expressions.
	exprs isEmpty ifTrue: [ ^ self ].
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	(head isKindOf: ZealColonChainNode) ifTrue: [
		headStr := (ZealColonChainResolver resolve: head value value) at: #name ].
	headStr ifNil: [ ^ self generateFunctionCall: aNode ].

	self specialForms
		at: headStr
		ifPresent: [ :selector | ^ self perform: selector with: aNode ].

	(self isOperator: headStr) ifTrue: [ ^ self generateOperator: aNode ].

	^ self generateFunctionCall: aNode
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitMap: aNode [
	"{k1 v1 k2 v2} -> inline struct initializer. AngelScript doesn't have a
	 general map literal, so we emit a synthetic Dict(...) constructor call
	 — the user is expected to define one, or this gets rewritten upstream."
	| exprs |
	exprs := aNode expressions.
	self emit: 'Dict('.
	1 to: exprs size by: 2 do: [ :i |
		i > 1 ifTrue: [ self emit: ', ' ].
		self visitExpression: (exprs at: i).
		self emit: ' => '.
		(i + 1 <= exprs size) ifTrue: [ self visitExpression: (exprs at: i + 1) ] ].
	self emit: ')'
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitReturnPosition: aNode [
	"Emit aNode as the producer of a function's return value. Recurses into
	 if/when/do/let so each branch's leaf becomes `return X;`. For statement-only
	 forms (set/var/return/angel-raw) emits as plain statements. Plain expressions
	 get wrapped in `return X;`."
	(self isReturnControlForm: aNode)
		ifTrue: [ ^ self emitReturnControl: aNode ].
	((aNode isKindOf: ZealListNode) and: [ aNode expressions notEmpty
		and: [ (aNode expressions first isKindOf: ZealSymbolNode)
		and: [ #('return' 'set' 'var' 'def' 'angel-raw') includes: aNode expressions first value value ] ] ])
		ifTrue: [ ^ self visitStatement: aNode ].
	self emit: 'return '.
	self visitExpression: aNode.
	stream nextPut: $;
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitStatement: aNode [
	"Emit a node at statement position: visit, then append ; unless it emits
	 its own block structure (if/when/for/let/defn/…)."
	self visitExpression: aNode.
	(self isStatementShaped: aNode) ifFalse: [ stream nextPut: $; ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitTopLevel: aNode [
	"At top level a list form may be a statement (var/def) — needs a trailing
	 semicolon — or a declaration (defn/defclass) which emits its own block.
	 Expression atoms at top level are not valid AngelScript; emit with ; anyway."
	self visitExpression: aNode.
	(self isStatementShaped: aNode) ifFalse: [ stream nextPut: $; ]
]

{ #category : 'api' }
AngelZealCodeGenerator >> visitVector: aNode [
	"[x y z] -> {x, y, z} — AngelScript initializer-list syntax."
	self emit: '{'.
	aNode expressions
		do: [ :e | self visitExpression: e ]
		separatedBy: [ self emit: ', ' ].
	self emit: '}'
]
