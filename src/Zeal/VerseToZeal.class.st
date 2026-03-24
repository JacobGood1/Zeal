Class {
	#name : 'VerseToZeal',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'converting' }
VerseToZeal class >> convert: aVerseNode [
	(aVerseNode isKindOf: VerseProgramNode) ifTrue: [
		| results |
		results := OrderedCollection new.
		aVerseNode statements do: [:s |
			| converted |
			converted := [ self convertStatement: s ] on: Error do: [:e |
				ZealCompileError new message: e messageText ].
			converted ifNotNil: [ results add: converted ] ].
		results isEmpty ifTrue: [ ^ results ].
		results size = 1 ifTrue: [ ^ results first ].
		^ results ].
	^ [ self convertStatement: aVerseNode ] on: Error do: [:e |
		ZealCompileError new message: e messageText ]
]

{ #category : 'definitions' }
VerseToZeal class >> convertAnnotated: aNode [
	| inner |
	inner := self convertStatement: aNode definition.
	(inner respondsTo: #annotations:) ifTrue: [
		inner annotations: (inner annotations , { '@' , aNode annotation value }) ].
	^ inner
]

{ #category : 'expressions' }
VerseToZeal class >> convertBlock: aNode [
	^ ZealBlock new body: (aNode statements collect: [:s | self convertStatement: s])
]

{ #category : 'definitions' }
VerseToZeal class >> convertClass: aNode [
	| specs declSpecs fields methods cls parentName |
	specs := aNode specs ifNil: [#()] ifNotNil: [:s | s collect: [:each | each value]].
	declSpecs := specs select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	parentName := nil.
	[ aNode parents ifNotNil: [:p | (p notNil and: [p notEmpty]) ifTrue: [ parentName := p first value ] ] ] on: Error do: [ ].
	fields := OrderedCollection new.
	methods := OrderedCollection new.
	(aNode statements ifNil: [#()]) do: [:s |
		| converted |
		converted := [ self convertStatement: s ] on: Error do: [:e | ZealCompileError new message: e messageText ].
		(converted isKindOf: ZealFunction) ifTrue: [ methods add: converted ]
		ifFalse: [ (converted isKindOf: ZealVariable) ifTrue: [
			fields add: (ZealField new name: converted name; type: converted type; defaultValue: converted value; isMutable: converted isMutable; specifiers: converted specifiers) ] ] ].
	cls := ZealClass new
		name: aNode name value;
		specifiers: declSpecs;
		superclass: parentName;
		fields: fields;
		methods: methods.
	fields do: [:f | f parent: cls].
	methods do: [:m | m parent: cls].
	^ cls
]

{ #category : 'definitions' }
VerseToZeal class >> convertConstDef: aNode [
	^ ZealVariable new
		name: aNode name value;
		type: (aNode type ifNotNil: [:t | self convertType: t] ifNil: [nil]);
		isMutable: false;
		value: (self convertExpression: aNode value)
]

{ #category : 'definitions' }
VerseToZeal class >> convertEnum: aNode [
	^ ZealEnum new
		name: aNode name value;
		values: (aNode values ifNil: [#()] ifNotNil: [:v | v collect: [:each | each value]])
]

{ #category : 'expressions' }
VerseToZeal class >> convertExpression: aNode [
	aNode isNil ifTrue: [ ^ ZealLiteral new value: 'nil'; literalType: #unknown ].
	(aNode isKindOf: SmaCCErrorNode) ifTrue: [ ^ ZealCompileError new message: 'Parse error'; source: aNode source ].
	(aNode isKindOf: VerseIdentNode) ifTrue: [ ^ ZealSymbolRef new name: aNode value value ].
	(aNode isKindOf: VerseIntLitNode) ifTrue: [ ^ ZealLiteral new value: aNode value value; literalType: #integer ].
	(aNode isKindOf: VerseFloatLitNode) ifTrue: [ ^ ZealLiteral new value: aNode value value; literalType: #float ].
	(aNode isKindOf: VerseStringLitNode) ifTrue: [ ^ ZealLiteral new value: aNode value value; literalType: #string ].
	(aNode isKindOf: VerseHexLitNode) ifTrue: [ ^ ZealLiteral new value: aNode value value; literalType: #hex ].
	(aNode isKindOf: VerseBoolLitNode) ifTrue: [ ^ ZealLiteral new value: aNode value value; literalType: #boolean ].
	(aNode isKindOf: VerseBinOpNode) ifTrue: [ 
		^ ZealOperator new operator: aNode op value; 
			operands: { self convertExpression: aNode left. self convertExpression: aNode right } ].
	(aNode isKindOf: VerseUnaryOpNode) ifTrue: [
		^ ZealOperator new operator: aNode op value;
			operands: { self convertExpression: aNode operand } ].
	(aNode isKindOf: VerseCallNode) ifTrue: [
		| recv name |
		recv := aNode receiver.
		name := (recv isKindOf: VerseIdentNode) ifTrue: [ recv value value ] ifFalse: [ recv source ].
		^ ZealFunctionCall new functionName: name;
			arguments: (aNode args ifNil: [#()] ifNotNil: [:a | a collect: [:e | self convertExpression: e]]) ].
	(aNode isKindOf: VerseMemberAccessNode) ifTrue: [
		^ ZealFunctionCall new functionName: '.';
			arguments: { self convertExpression: aNode receiver. ZealSymbolRef new name: aNode member value } ].
	(aNode isKindOf: VerseSetNode) ifTrue: [
		^ ZealSet new target: aNode target value; value: (self convertExpression: aNode value) ].
	(aNode isKindOf: VerseReturnNode) ifTrue: [
		^ ZealReturn new value: (self convertExpression: aNode value) ].
	(aNode isKindOf: VerseBreakNode) ifTrue: [ ^ ZealBreak new ].
	(aNode isKindOf: VerseIfNode) ifTrue: [ ^ self convertIf: aNode ].
	(aNode isKindOf: VerseForNode) ifTrue: [ ^ self convertFor: aNode ].
	(aNode isKindOf: VerseLoopNode) ifTrue: [ ^ self convertLoop: aNode ].
	(aNode isKindOf: VerseBlockNode) ifTrue: [ ^ self convertBlock: aNode ].
	(aNode isKindOf: VerseArrayLitNode) ifTrue: [
		^ ZealArray new elements: (aNode args ifNil: [#()] ifNotNil: [:a | a collect: [:e | self convertExpression: e]]) ].
	(aNode isKindOf: VerseMapLitNode) ifTrue: [
		^ ZealMap new entries: (aNode entries ifNil: [#()] ifNotNil: [:e |
			e collect: [:pair | { self convertExpression: pair key. self convertExpression: pair value }]]) ].
	(aNode isKindOf: VerseParenNode) ifTrue: [
		| stmts |
		stmts := aNode statements.
		stmts notEmpty ifTrue: [ ^ self convertExpression: stmts first ].
		^ ZealLiteral new value: '()'; literalType: #unit ].
	^ ZealLiteral new value: aNode source; literalType: #raw
]

{ #category : 'definitions' }
VerseToZeal class >> convertFieldDecl: aNode [
	^ ZealVariable new
		name: aNode name value;
		type: (aNode type ifNotNil: [:t | self convertType: t]);
		isMutable: false;
		value: nil
]

{ #category : 'expressions' }
VerseToZeal class >> convertFor: aNode [
	| bindings body |
	bindings := aNode clauses collect: [:c |
		ZealBinding new name: c name value; value: (self convertExpression: c collection) ].
	body := aNode statements collect: [:s | self convertStatement: s].
	^ ZealFor new bindings: bindings; predicates: #(); body: body
]

{ #category : 'definitions' }
VerseToZeal class >> convertFuncDef: aNode [
	| func specs declSpecs sigSpecs params body |
	specs := aNode specs ifNil: [#()] ifNotNil: [:s | s collect: [:each | each value]].
	declSpecs := specs select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	sigSpecs := specs select: [:s | ZealColonChainResolver isSignatureSpecifier: s].
	params := aNode params ifNil: [#()] ifNotNil: [:p |
		p collect: [:each |
			ZealParameter new
				name: each name value;
				type: (each type ifNotNil: [:t | self convertType: t])]].
	body := aNode body ifNotNil: [:b | { self convertExpression: b } ] ifNil: [ #() ].
	"Also check if there are statements (from brace blocks)"
	(aNode respondsTo: #statements) ifTrue: [
		aNode statements notEmpty ifTrue: [
			body := aNode statements collect: [:s | self convertStatement: s ] ] ].
	func := ZealFunction new
		name: aNode name value;
		type: (aNode type ifNotNil: [:t | self convertType: t]);
		specifiers: declSpecs , sigSpecs;
		effects: sigSpecs;
		parameters: params;
		body: body.
	params do: [:p | p parent: func].
	body do: [:b | b parent: func].
	^ func
]

{ #category : 'expressions' }
VerseToZeal class >> convertIf: aNode [
	| allConds cond body |
	allConds := aNode conds ifNil: [#()] ifNotNil: [:c | c collect: [:each | self convertExpression: each]].
	allConds isEmpty ifTrue: [ ^ ZealBlock new body: (aNode statements collect: [:s | self convertStatement: s]) ].
	cond := allConds first.
	allConds allButFirst do: [:c |
		cond := ZealOperator new operator: 'and'; operands: { cond. c } ].
	body := aNode statements collect: [:s | self convertStatement: s].
	body size = 1 ifTrue: [ body := body first ] ifFalse: [ body := ZealBlock new body: body ].
	^ ZealIf new
		clauses: { { cond. body } };
		elseBody: nil
]

{ #category : 'definitions' }
VerseToZeal class >> convertInterface: aNode [
	| methods |
	methods := aNode statements collect: [:s | self convertStatement: s].
	^ ZealInterface new
		name: aNode name value;
		methods: methods
]

{ #category : 'expressions' }
VerseToZeal class >> convertLoop: aNode [
	^ ZealLoop new body: (aNode statements collect: [:s | self convertStatement: s])
]

{ #category : 'definitions' }
VerseToZeal class >> convertModule: aNode [
	| usings defs mod |
	usings := OrderedCollection new.
	defs := OrderedCollection new.
	aNode statements do: [:s |
		| converted |
		converted := self convertStatement: s.
		(converted isKindOf: ZealUsing) ifTrue: [ usings add: converted ]
		ifFalse: [ defs add: converted ] ].
	mod := ZealModule new
		name: aNode name value;
		kind: #inline;
		usings: usings;
		definitions: defs.
	usings do: [:u | u parent: mod].
	defs do: [:d | d parent: mod].
	^ mod
]

{ #category : 'converting' }
VerseToZeal class >> convertStatement: aNode [
	aNode isNil ifTrue: [ ^ ZealCompileError new message: 'nil node' ].
	(aNode isKindOf: SmaCCErrorNode) ifTrue: [ ^ ZealCompileError new message: 'Parse error'; source: aNode source ].
	^ [ 
		(aNode isKindOf: VerseUsingDefNode) ifTrue: [ ^ self convertUsing: aNode ].
		(aNode isKindOf: VerseAnnotatedDefNode) ifTrue: [ ^ self convertAnnotated: aNode ].
		(aNode isKindOf: VerseFieldDeclNode) ifTrue: [ ^ self convertFieldDecl: aNode ].
		(aNode isKindOf: VerseConstDefNode) ifTrue: [ ^ self convertConstDef: aNode ].
		(aNode isKindOf: VerseVarDefNode) ifTrue: [ ^ self convertVarDef: aNode ].
		(aNode isKindOf: VerseFuncDefNode) ifTrue: [ ^ self convertFuncDef: aNode ].
		(aNode isKindOf: VerseClassNode) ifTrue: [ ^ self convertClass: aNode ].
		(aNode isKindOf: VerseStructNode) ifTrue: [ ^ self convertStruct: aNode ].
		(aNode isKindOf: VerseEnumNode) ifTrue: [ ^ self convertEnum: aNode ].
		(aNode isKindOf: VerseInterfaceNode) ifTrue: [ ^ self convertInterface: aNode ].
		(aNode isKindOf: VerseModuleNode) ifTrue: [ ^ self convertModule: aNode ].
		self convertExpression: aNode
	] on: Error do: [:e | ZealCompileError new message: e messageText ]
]

{ #category : 'definitions' }
VerseToZeal class >> convertStruct: aNode [
	| fields |
	fields := OrderedCollection new.
	aNode statements do: [:s |
		| converted |
		converted := self convertStatement: s.
		(converted isKindOf: ZealVariable) ifTrue: [
			fields add: (ZealField new name: converted name; type: converted type; defaultValue: converted value) ]
		ifFalse: [ fields add: converted ] ].
	^ ZealStruct new
		name: aNode name value;
		fields: fields
]

{ #category : 'helpers' }
VerseToZeal class >> convertType: aTypeNode [
	(aTypeNode isKindOf: VerseNamedNode) ifTrue: [ ^ aTypeNode name value ].
	(aTypeNode isKindOf: VerseOptionalNode) ifTrue: [ ^ '?' , (self convertType: aTypeNode inner) ].
	^ aTypeNode source
]

{ #category : 'definitions' }
VerseToZeal class >> convertUsing: aNode [
	| segments path |
	segments := aNode path ifNil: [ #() ] ifNotNil: [:p | p collect: [:s | s value ] ].
	path := '/' , ('/' join: segments).
	^ ZealUsing new path: path
]

{ #category : 'definitions' }
VerseToZeal class >> convertVarDef: aNode [
	^ ZealVariable new
		name: aNode name value;
		type: (aNode type ifNotNil: [:t | self convertType: t] ifNil: [nil]);
		isMutable: true;
		value: (self convertExpression: aNode value)
]

{ #category : 'helpers' }
VerseToZeal class >> extractSpecifiers: aNode [
	"Extract specifier strings from a node that has spec tokens"
	| specs |
	specs := OrderedCollection new.
	(aNode respondsTo: #specs) ifTrue: [
		aNode specs do: [:s | specs add: s value ] ].
	^ specs asArray
]

{ #category : 'helpers' }
VerseToZeal class >> mergeStatements: nodes [
	"Post-process: merge MemberAccess followed by args into a function call.
	 Handles GLR splitting Console.Print(x) into [MemberAccess, Paren]"
	| result i |
	result := OrderedCollection new.
	i := 1.
	[ i <= nodes size ] whileTrue: [
		| current |
		current := nodes at: i.
		"Check if this is a member access/ident/call followed by paren-like args"
		((current isKindOf: ZealFunctionCall) and: [ current functionName = '.' ]) ifTrue: [
			"MemberAccess - check if next node looks like args (literal/block from paren)"
			(i + 1 <= nodes size and: [ (nodes at: i + 1) isKindOf: ZealLiteral ]) ifTrue: [
				| member recv arg |
				recv := current arguments first.
				member := current arguments second name.
				arg := nodes at: i + 1.
				result add: (ZealFunctionCall new 
					functionName: '.';
					arguments: { recv. ZealSymbolRef new name: member. arg }).
				i := i + 2 ]
			ifFalse: [ result add: current. i := i + 1 ] ]
		ifFalse: [ result add: current. i := i + 1 ] ].
	^ result
]
