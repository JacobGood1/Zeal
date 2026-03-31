Class {
	#name : 'ZealCompiler',
	#superclass : 'Object',
	#classInstVars : [
		'currentResolver'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'building' }
ZealCompiler class >> buildArchetype: aListNode [
	"(were-cat :console c :name n) -> were_cat{Console := C, Name := N}"
	| exprs headStr typeName fields i |
	exprs := aListNode expressions.
	headStr := exprs first value value.
	typeName := ZealSymbolRef new name: headStr.
	fields := OrderedCollection new.
	i := 2.
	[ i <= exprs size ] whileTrue: [
		| kw val |
		kw := exprs at: i.
		(kw isKindOf: ZealKeywordNode) ifTrue: [
			val := (i + 1 <= exprs size) ifTrue: [ self buildExpression: (exprs at: i + 1) ] ifFalse: [ ZealLiteral new value: 'true'; literalType: #boolean ].
			fields add: (ZealOperator new operator: ':='; operands: { ZealSymbolRef new name: kw value value allButFirst. val }).
			i := i + 2 ]
		ifFalse: [ i := i + 1 ] ].
	^ ZealFunctionCall new functionName: 'archetype'; arguments: {typeName} , fields
]

{ #category : 'building' }
ZealCompiler class >> buildAtom: aNode [
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		| sym |
		sym := aNode value value.
		(sym indexOf: $/) > 0 ifTrue: [
			| parts result |
			parts := sym splitOn: $/.
			result := ZealSymbolRef new name: parts first.
			parts allButFirst do: [:p |
				| recvType |
				"Use type resolver if available to decide member vs index"
				recvType := currentResolver ifNotNil: [:r | r typeOfExpression: result].
				(p allSatisfy: [:ch | ch isDigit]) 
					ifTrue: [ 
						"Numeric: always index"
						result := ZealFunctionCall new functionName: '[]'; arguments: {result. ZealLiteral new value: p; literalType: #integer} ]
					ifFalse: [ 
						"Check type: indexable -> [], object -> ."
						(self isIndexableType: recvType)
							ifTrue: [ result := ZealFunctionCall new functionName: '[]'; arguments: {result. ZealSymbolRef new name: p} ]
							ifFalse: [ result := ZealFunctionCall new functionName: '.'; arguments: {result. ZealSymbolRef new name: p} ] ] ].
			^ result ].
		^ ZealSymbolRef new name: sym ].
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		^ ZealSymbolRef new name: aNode value value ].
	(aNode isKindOf: ZealKeywordNode) ifTrue: [
		^ ZealLiteral new value: '"' , aNode value value allButFirst , '"'; literalType: #string ].
	(aNode isKindOf: ZealIntegerLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #integer ].
	(aNode isKindOf: ZealFloatLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #float ].
	(aNode isKindOf: ZealStringLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #string ].
	(aNode isKindOf: ZealCharLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #char ].
	(aNode isKindOf: ZealHexLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #hex ].
	(aNode isKindOf: ZealRangeLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #range ].
	^ ZealLiteral new value: aNode value value; literalType: #unknown
]

{ #category : 'building' }
ZealCompiler class >> buildBlock: aListNode [
	^ ZealBlock new body: (aListNode expressions allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'building' }
ZealCompiler class >> buildBody: astExprs [
	"Build body expressions, flattening any multi-binding results"
	| body |
	body := OrderedCollection new.
	astExprs do: [:e |
		| built |
		built := self buildExpression: e.
		(built isKindOf: OrderedCollection)
			ifTrue: [ body addAll: built ]
			ifFalse: [ body add: built ] ].
	^ body
]

{ #category : 'building' }
ZealCompiler class >> buildBreak: aListNode [
	^ ZealBreak new
]

{ #category : 'building' }
ZealCompiler class >> buildCase: aListNode [
	| exprs err rest pairs |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'case') ifNotNil: [ ^ err ].
	rest := exprs allButFirst allButFirst.
	rest size odd ifTrue: [ ^ self error: 'case patterns and bodies must come in pairs, got ' , rest size printString ].
	pairs := OrderedCollection new.
	1 to: rest size by: 2 do: [:i |
		pairs add: { self buildExpression: (rest at: i). self buildExpression: (rest at: i + 1) } ].
	^ ZealCase new target: (self buildExpression: exprs second); cases: pairs
]

{ #category : 'builders' }
ZealCompiler class >> buildDef: aListNode [
	"(def name:type value) or (def name:type) for abstract fields"
	| exprs results i |
	exprs := aListNode expressions allButFirst.
	exprs isEmpty ifTrue: [ ^ self error: 'def requires a name' ].
	
	"Single arg: abstract field declaration (def name:type)"
	exprs size = 1 ifTrue: [
		| resolved |
		resolved := self resolveNameNode: exprs first.
		(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
		^ ZealVariable new
			name: (resolved at: #name); type: (resolved at: #type);
			specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
			isMutable: false; value: nil ].
	
	"Multiple args: name/value pairs"
	results := OrderedCollection new.
	i := 1.
	[ i + 1 <= exprs size ] whileTrue: [
		| nameNode valueExpr resolved value type |
		nameNode := exprs at: i.
		valueExpr := exprs at: i + 1.
		resolved := self resolveNameNode: nameNode.
		(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
		value := self buildExpression: valueExpr.
		type := resolved at: #type.
		type ifNil: [ type := self inferType: value ].
		results add: (ZealVariable new
			name: (resolved at: #name); type: type;
			specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
			isMutable: false; value: value).
		i := i + 2 ].
	"Odd trailing name without value: abstract field"
	i = exprs size ifTrue: [
		| resolved |
		resolved := self resolveNameNode: (exprs at: i).
		(resolved isKindOf: ZealCompileError) ifFalse: [
			results add: (ZealVariable new
				name: (resolved at: #name); type: (resolved at: #type);
				specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
				isMutable: false; value: nil) ] ].
	results size = 1 ifTrue: [ ^ results first ].
	^ results
]

{ #category : 'special forms' }
ZealCompiler class >> buildDefclass: aListNode [
	"(defclass name:specs [parents...] body...)
	 [parents] is optional — if second arg is a vector, it's the extension list"
	| exprs err resolved rest parents fields methods cls |
	exprs := aListNode expressions.
	(err := self requireArgs: 2 from: exprs forForm: 'defclass') ifNotNil: [ ^ err ].
	resolved := self requireNameFrom: exprs forForm: 'defclass'.
	(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
	rest := exprs allButFirst allButFirst. 
	parents := OrderedCollection new.
	
	"Check for [extensions] vector"
	(rest notEmpty and: [ rest first isKindOf: ZealVectorNode ]) ifTrue: [
		rest first expressions do: [:e | parents add: e value value ].
		rest := rest allButFirst ]
	ifFalse: [
		"Check for common mistake: (parent) instead of [parent]"
		(rest notEmpty and: [ rest first isKindOf: ZealListNode ]) ifTrue: [
			| firstList |
			firstList := rest first.
			(firstList expressions size = 1 and: [ firstList expressions first isKindOf: ZealSymbolNode ]) ifTrue: [
				^ ZealCompileError new error: 'defclass ', (resolved at: #name), ' uses (', firstList expressions first value value, ') for parents — use square brackets [', firstList expressions first value value, '] instead' ] ] ].
	
	fields := OrderedCollection new. methods := OrderedCollection new.
	rest do: [:item | | built |
		built := self buildExpression: item.
		(built isKindOf: ZealCompileError) ifTrue: [ ^ built ].
		(built isKindOf: ZealFunction) ifTrue: [ methods add: built ]
			ifFalse: [ (built isKindOf: ZealVariable)
				ifTrue: [ fields add: (ZealField new name: built name; type: built type; defaultValue: built value; isMutable: built isMutable) ]
				ifFalse: [ fields add: built ] ] ].
	cls := ZealClass new name: (resolved at: #name); specifiers: (resolved at: #specifiers);
		superclass: (parents isEmpty ifTrue: [nil] ifFalse: [parents first]);
		interfaces: (parents size > 1 ifTrue: [parents allButFirst] ifFalse: [#()]);
		fields: fields; methods: methods.
	fields do: [:f | f parent: cls]. methods do: [:m | m parent: cls]. ^ cls
]

{ #category : 'building' }
ZealCompiler class >> buildDefenum: aListNode [
	| exprs err |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'defenum') ifNotNil: [ ^ err ].
	^ ZealEnum new name: exprs second value value;
		values: (exprs allButFirst allButFirst collect: [:v | v value value])
]

{ #category : 'building' }
ZealCompiler class >> buildDefer: aListNode [
	^ ZealDefer new body: (aListNode expressions allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'building' }
ZealCompiler class >> buildDefinterface: aListNode [
	| exprs rest methods |
	exprs := aListNode expressions.
	rest := exprs allButFirst allButFirst.
	methods := rest collect: [:e | self buildExpression: e].
	^ ZealInterface new
		name: exprs second value value;
		methods: methods
]

{ #category : 'building' }
ZealCompiler class >> buildDefn: aListNode [
	| exprs err resolved declSpecs sigSpecs params bodyExprs func |
	exprs := aListNode expressions.
	(err := self requireArgs: 2 from: exprs forForm: 'defn') ifNotNil: [ ^ err ].
	resolved := self requireNameFrom: exprs forForm: 'defn'.
	(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
	declSpecs := (resolved at: #specifiers) select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	sigSpecs := (resolved at: #specifiers) select: [:s | ZealColonChainResolver isSignatureSpecifier: s].
	params := nil. bodyExprs := OrderedCollection new.
	exprs allButFirst allButFirst do: [:e |
		(params isNil and: [ e isKindOf: ZealVectorNode ])
			ifTrue: [ params := e ]
			ifFalse: [ bodyExprs add: e ] ].
	(params isNil and: [ bodyExprs isEmpty ]) ifTrue: [
		^ self error: 'defn ' , (resolved at: #name) , ' has no parameter list or body: ' , (self usageFor: 'defn') ].
	func := ZealFunction new
		name: (resolved at: #name); type: (resolved at: #type);
		specifiers: declSpecs , sigSpecs; annotations: (resolved at: #annotations);
		effects: sigSpecs;
		body: (self buildBody: bodyExprs).
	params ifNotNil: [
		func parameters: (params expressions collect: [:p |
			| r |
			((p isKindOf: ZealSymbolNode) or: [ p isKindOf: ZealColonChainNode ])
				ifFalse: [ ^ self error: 'defn ' , (resolved at: #name) , ' parameter must be name or name:type, got ' , p class name ].
			r := self resolveNameNode: p.
			ZealParameter new name: (r at: #name); type: (r at: #type) ]) ].
	func parameters do: [:p | p parent: func].
	func body do: [:b | b parent: func].
	^ func
]

{ #category : 'building' }
ZealCompiler class >> buildDefstruct: aListNode [
	| exprs err fields |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'defstruct') ifNotNil: [ ^ err ].
	fields := exprs allButFirst allButFirst collect: [:fv |
		| fieldExprs resolved field |
		(err := self requireVector: fv forForm: 'defstruct' label: 'field') ifNotNil: [ ^ err ].
		fieldExprs := fv expressions.
		fieldExprs isEmpty ifTrue: [ ^ self error: 'defstruct has an empty field []' ].
		resolved := self resolveNameNode: fieldExprs first.
		field := ZealField new name: (resolved at: #name); type: (resolved at: #type).
		fieldExprs size > 1 ifTrue: [ field defaultValue: (self buildExpression: fieldExprs second) ].
		field ].
	^ ZealStruct new name: exprs second value value; fields: fields
]

{ #category : 'building' }
ZealCompiler class >> buildExpression: aNode [
	"Dispatch AST node to appropriate builder."
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self buildList: aNode ].
	(aNode isKindOf: ZealVectorNode) ifTrue: [ ^ self buildVector: aNode ].
	(aNode isKindOf: ZealMapNode) ifTrue: [ ^ self buildMap: aNode ].
	^ self buildAtom: aNode
]

{ #category : 'building' }
ZealCompiler class >> buildFailableCall: aListNode [
	| exprs headStr name args |
	exprs := aListNode expressions.
	headStr := exprs first value value.
	name := headStr allButLast.
	args := exprs allButFirst collect: [:e | self buildExpression: e ].
	
	(name indexOf: $/) > 0 ifTrue: [
		| parts receiver member memberAccess |
		parts := name splitOn: $/.
		receiver := ZealSymbolRef new name: parts first.
		member := ZealSymbolRef new name: parts second.
		memberAccess := ZealFunctionCall new functionName: '.'; arguments: {receiver. member}.
		^ ZealFunctionCall new functionName: '[]'; arguments: {memberAccess} , args ].
	
	^ ZealFunctionCall new functionName: '[]'; arguments: {ZealSymbolRef new name: name} , args
]

{ #category : 'building' }
ZealCompiler class >> buildFor: aListNode [
	| exprs err parsed |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'for') ifNotNil: [ ^ err ].
	(err := self requireVector: exprs second forForm: 'for' label: 'bindings') ifNotNil: [ ^ err ].
	parsed := self parseBindingVectorNode: exprs second.
	^ ZealFor new bindings: parsed first; predicates: parsed second;
		body: (exprs allButFirst allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'building' }
ZealCompiler class >> buildFromAST: aProgramNode [
	"Walk the SmaCC AST and build ZealNode objects."
	| results |
	results := OrderedCollection new.
	aProgramNode expressions do: [:expr |
		results add: (self buildExpression: expr) ].
	results size = 1 ifTrue: [ ^ results first ].
	^ results
]

{ #category : 'building' }
ZealCompiler class >> buildFunctionCall: aListNode [
	| exprs head headStr |
	exprs := aListNode expressions.
	head := exprs first.
	headStr := (head isKindOf: ZealColonChainNode)
		ifTrue: [ (ZealColonChainResolver resolve: head value value) at: #name ]
		ifFalse: [ head value value ].
	^ ZealFunctionCall new
		functionName: headStr;
		arguments: (exprs allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'special forms' }
ZealCompiler class >> buildIf: aListNode [
	"Unified if form:
	 If-style:  (if cond body...) or (if cond1 body1 cond2 body2 :else elseBody)
	 Let-style: (if [bindings...] body...) — bindings with optional predicates"
	| exprs firstArg |
	exprs := aListNode expressions.
	exprs size < 3 ifTrue: [ ^ self error: 'if requires at least a condition/bindings and a body' source: aListNode ].
	firstArg := exprs second.
	
	"If first arg is a vector [...], it's let-style"
	(firstArg isKindOf: ZealVectorNode)
		ifTrue: [ ^ self buildIfLet: aListNode ]
		ifFalse: [ ^ self buildIfExpr: aListNode ]
]

{ #category : 'builders' }
ZealCompiler class >> buildIfExpr: aListNode [
	"(if cond then) — simple if
	 (if cond then else) — if/else (positional, no keyword needed)
	 (if cond1 body1 cond2 body2 :else elseBody) — multi-clause with :else
	 (if [bindings] body) — let-style (handled by buildIf:)"
	| args elseIdx clauses elseBody |
	args := aListNode expressions allButFirst.
	
	"Find :else position"
	elseIdx := args detectIndex: [:a | 
		(a isKindOf: ZealKeywordNode) and: [ a value value = ':else' ]] 
		ifNone: [ 0 ].
	
	elseIdx > 0 ifTrue: [
		"Has :else — pairs of (cond body) before :else, then else body"
		| beforeElse afterElse |
		beforeElse := args copyFrom: 1 to: elseIdx - 1.
		afterElse := args copyFrom: elseIdx + 1 to: args size.
		clauses := OrderedCollection new.
		1 to: beforeElse size by: 2 do: [:i |
			i + 1 <= beforeElse size ifTrue: [
				clauses add: { self buildExpression: (beforeElse at: i). self buildExpression: (beforeElse at: i + 1) } ] ].
		elseBody := afterElse size = 1
			ifTrue: [ self buildExpression: afterElse first ]
			ifFalse: [ ZealBlock new body: (afterElse collect: [:e | self buildExpression: e]) ] ]
	ifFalse: [
		"No :else — positional"
		args size = 2 ifTrue: [
			"(if cond then) — simple if, no else"
			clauses := OrderedCollection with: { self buildExpression: args first. self buildExpression: args second }.
			elseBody := nil ]
		ifFalse: [ args size = 3 ifTrue: [
			"(if cond then else) — simple if/else"
			clauses := OrderedCollection with: { self buildExpression: args first. self buildExpression: args second }.
			elseBody := self buildExpression: args third ]
		ifFalse: [
			"(if cond body...) — multi-expression body, no else"
			| bodyExprs |
			clauses := OrderedCollection new.
			bodyExprs := args allButFirst collect: [:e | self buildExpression: e].
			clauses add: { self buildExpression: args first. 
				bodyExprs size = 1 ifTrue: [ bodyExprs first ] ifFalse: [ ZealBlock new body: bodyExprs ] }.
			elseBody := nil ] ] ].
	
	^ ZealIf new clauses: clauses; elseBody: elseBody
]

{ #category : 'special forms' }
ZealCompiler class >> buildIfLet: aListNode [
	"Let-style if: (if [x 10 (> x 2)] body...)
	 Vector contains bindings and optional predicates."
	| exprs parsed |
	exprs := aListNode expressions.
	parsed := self parseBindingVectorNode: exprs second.
	^ ZealLet new 
		bindings: parsed first; 
		predicates: parsed second;
		body: (exprs allButFirst allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'building' }
ZealCompiler class >> buildList: aListNode [
	| exprs head headStr |
	exprs := aListNode expressions.
	exprs isEmpty ifTrue: [ ^ ZealLiteral new value: '()'; literalType: #unit ].
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	(head isKindOf: ZealColonChainNode) ifTrue: [ headStr := (ZealColonChainResolver resolve: head value value) at: #name ].
	headStr ifNil: [ ^ self buildFunctionCall: aListNode ].
	
	self specialFormBuilders at: headStr ifPresent: [:sel | ^ self perform: sel with: aListNode ].
	(self operators includes: headStr) ifTrue: [ ^ self buildOperator: aListNode ].
	
	"? failable suffix: (find? x) or (obj/method? x)"
	(headStr endsWith: '?') ifTrue: [ ^ self buildFailableCall: aListNode ].
	
	"/ prefix: (/length obj) -> member access, (/0 obj) -> index access"
	(headStr beginsWith: '/') ifTrue: [ ^ self buildPrefixAccess: aListNode ].
	
	"/ in middle: (console/print args...) -> member call"
	(headStr indexOf: $/) > 0 ifTrue: [ ^ self buildMemberCall: aListNode ].
	
	"Keyword args: (type-name :field val ...) -> archetype"
	(exprs size >= 2 and: [(exprs second isKindOf: ZealKeywordNode)]) ifTrue: [ ^ self buildArchetype: aListNode ].
	
	^ self buildFunctionCall: aListNode
]

{ #category : 'building' }
ZealCompiler class >> buildLoop: aListNode [
	^ ZealLoop new body: (aListNode expressions allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'building' }
ZealCompiler class >> buildMap: aMapNode [
	^ ZealMap new
		entries: (aMapNode pairs collect: [:pair |
			{ self buildExpression: pair key. self buildExpression: pair value } ])
]

{ #category : 'builders' }
ZealCompiler class >> buildMemberCall: aListNode [
	"(console/print args...) → Console.Print(args...) — always a method CALL"
	| exprs headStr parts receiver member args |
	exprs := aListNode expressions.
	headStr := exprs first value value.
	parts := headStr splitOn: $/.
	receiver := ZealSymbolRef new name: parts first.
	member := ZealSymbolRef new name: parts second.
	args := exprs allButFirst collect: [:e | self buildExpression: e ].
	^ ZealFunctionCall new 
		functionName: '.call'; 
		arguments: {receiver. member} , args
]

{ #category : 'building' }
ZealCompiler class >> buildModule: aListNode [
	| exprs err resolved usings defs mod |
	exprs := aListNode expressions.
	(err := self requireArgs: 2 from: exprs forForm: 'module') ifNotNil: [ ^ err ].
	resolved := self requireNameFrom: exprs forForm: 'module'.
	(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
	usings := OrderedCollection new. defs := OrderedCollection new.
	exprs allButFirst allButFirst do: [:e | | built |
		built := self buildExpression: e.
		(built isKindOf: ZealUsing) ifTrue: [ usings add: built ] ifFalse: [ defs add: built ] ].
	mod := ZealModule new name: (resolved at: #name); kind: #inline; usings: usings; definitions: defs.
	usings do: [:u | u parent: mod].
	defs do: [:d | d parent: mod].
	^ mod
]

{ #category : 'building' }
ZealCompiler class >> buildOperator: aListNode [
	| exprs op |
	exprs := aListNode expressions.
	op := exprs first value value.
	^ ZealOperator new
		operator: op;
		operands: (exprs allButFirst collect: [:e | self buildExpression: e])
]

{ #category : 'building' }
ZealCompiler class >> buildPrefixAccess: aListNode [
	"(/length obj) -> Obj.Length (member access)
	 (/0 obj) -> Obj[0] (index access)
	 (/length obj args...) -> Obj.Length(args...) (member call)"
	| exprs headStr accessor args obj |
	exprs := aListNode expressions.
	headStr := exprs first value value.
	accessor := headStr allButFirst. "strip leading /"
	exprs size < 2 ifTrue: [ ^ ZealCompileError new message: accessor , ' requires an object argument' ].
	obj := self buildExpression: exprs second.
	args := exprs size > 2 ifTrue: [ (exprs copyFrom: 3 to: exprs size) collect: [:e | self buildExpression: e] ] ifFalse: [ #() ].
	
	"Check if accessor is a number (index access)"
	(accessor allSatisfy: [:ch | ch isDigit]) ifTrue: [
		^ ZealFunctionCall new functionName: '[]'; arguments: {obj. ZealLiteral new value: accessor; literalType: #integer} , args ].
	
	"Member access or member call"
	^ ZealFunctionCall new functionName: '.'; arguments: {obj. ZealSymbolRef new name: accessor} , args
]

{ #category : 'building' }
ZealCompiler class >> buildReturn: aListNode [
	| exprs |
	exprs := aListNode expressions.
	^ ZealReturn new value: (exprs size > 1 ifTrue: [ self buildExpression: exprs second ] ifFalse: [ nil ])
]

{ #category : 'building' }
ZealCompiler class >> buildSet: aListNode [
	| exprs err target |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'set') ifNotNil: [ ^ err ].
	(exprs second isKindOf: ZealSymbolNode)
		ifFalse: [ ^ self error: 'set target must be a symbol, got ' , exprs second class name ].
	target := exprs second value value.
	
	"Check for compound assignment: (set x += 1) — 4 args"
	(exprs size >= 4 and: [(#('+=' '-=' '*=') includes: exprs third value value)]) ifTrue: [
		^ ZealSet new target: target; operator: exprs third value value; value: (self buildExpression: exprs fourth) ].
	
	"Simple assignment: (set x value) — 3 args"
	^ ZealSet new target: target; value: (self buildExpression: exprs third)
]

{ #category : 'building' }
ZealCompiler class >> buildStr: aListNode [
	"(str 'hello ' name ' world') -> string interpolation literal"
	| parts |
	parts := aListNode expressions allButFirst collect: [:e | self buildExpression: e ].
	^ ZealLiteral new 
		value: (String streamContents: [:s |
			s nextPut: $".
			parts do: [:p |
				((p isKindOf: ZealLiteral) and: [p literalType = #string]) 
					ifTrue: [ 
						| inner |
						inner := p value.
						(inner first = $" and: [inner last = $"]) ifTrue: [ inner := inner copyFrom: 2 to: inner size - 1 ].
						s nextPutAll: inner ]
					ifFalse: [ 
						s nextPut: ${.
						s nextPutAll: (ZealCodeGenerator new toPascalCase: 
							((p isKindOf: ZealSymbolRef) ifTrue: [p name] ifFalse: [p compileToVerse])).
						s nextPut: $} ] ].
			s nextPut: $" ]);
		literalType: #string
]

{ #category : 'building' }
ZealCompiler class >> buildUsing: aListNode [
	^ ZealUsing new path: aListNode expressions second value value
]

{ #category : 'builders' }
ZealCompiler class >> buildVar: aListNode [
	"(var name:type value) or (var name:type) for abstract fields"
	| exprs results i |
	exprs := aListNode expressions allButFirst.
	exprs isEmpty ifTrue: [ ^ self error: 'var requires a name' ].
	
	"Single arg: abstract field (var name:type)"
	exprs size = 1 ifTrue: [
		| resolved |
		resolved := self resolveNameNode: exprs first.
		(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
		^ ZealVariable new
			name: (resolved at: #name); type: (resolved at: #type);
			specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
			isMutable: true; value: nil ].
	
	results := OrderedCollection new.
	i := 1.
	[ i + 1 <= exprs size ] whileTrue: [
		| nameNode valueExpr resolved value type |
		nameNode := exprs at: i.
		valueExpr := exprs at: i + 1.
		resolved := self resolveNameNode: nameNode.
		(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
		value := self buildExpression: valueExpr.
		type := resolved at: #type.
		type ifNil: [ type := self inferType: value ].
		results add: (ZealVariable new
			name: (resolved at: #name); type: type;
			specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
			isMutable: true; value: value).
		i := i + 2 ].
	"Odd trailing name: abstract field"
	i = exprs size ifTrue: [
		| resolved |
		resolved := self resolveNameNode: (exprs at: i).
		(resolved isKindOf: ZealCompileError) ifFalse: [
			results add: (ZealVariable new
				name: (resolved at: #name); type: (resolved at: #type);
				specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
				isMutable: true; value: nil) ] ].
	results size = 1 ifTrue: [ ^ results first ].
	^ results
]

{ #category : 'building' }
ZealCompiler class >> buildVector: aVectorNode [
	^ ZealArray new
		elements: (aVectorNode expressions collect: [:e | self buildExpression: e])
]

{ #category : 'compiling' }
ZealCompiler class >> compile: aString [
	"Parse Zeal source and return ZealNode objects."
	| ast |
	ast := ZealParser parse: aString.
	^ self buildFromAST: ast
]

{ #category : 'compiler' }
ZealCompiler class >> compileToVerse: aString [
	"Parse Zeal source, build objects, compile to Verse string."
	| nodes |
	nodes := self compile: aString.
	(nodes isKindOf: Collection) ifFalse: [ nodes := { nodes } ].
	^ String streamContents: [:s |
		nodes do: [:n | n compileToVerse: s indent: 0 ] separatedBy: [ s cr; cr ] ]
]

{ #category : 'compiling' }
ZealCompiler class >> compileToVerseWithComments: aString [
	| nodes |
	nodes := self compile: aString.
	(nodes isKindOf: Collection)
		ifTrue: [ ^ String streamContents: [:s |
			nodes do: [:n | n compileToVerseWithComments: s indent: 0 ] separatedBy: [ s cr; cr ] ] ]
		ifFalse: [ ^ nodes compileToVerseWithComments ]
]

{ #category : 'accessing' }
ZealCompiler class >> currentResolver [ ^ currentResolver
]

{ #category : 'accessing' }
ZealCompiler class >> currentResolver: aResolver [ currentResolver := aResolver
]

{ #category : 'errors' }
ZealCompiler class >> error: msg [
	^ ZealCompileError new message: msg
]

{ #category : 'errors' }
ZealCompiler class >> error: msg source: src [
	^ ZealCompileError new message: msg; source: src
]

{ #category : 'compiling' }
ZealCompiler class >> fromVerse: aString [
	| preprocessed parsed |
	preprocessed := VersePreprocessor process: aString.
	parsed := VersePP2Grammar new parse: preprocessed.
	^ VersePP2ToZeal convert: parsed
]

{ #category : 'type inference' }
ZealCompiler class >> inferMapType: aMapNode [
	"Infer map type from first key-value pair"
	| pairs keyType valType |
	pairs := aMapNode pairs.
	pairs isEmpty ifTrue: [ ^ '[any]any' ].
	keyType := self inferType: pairs first key.
	valType := self inferType: pairs first value.
	keyType ifNil: [ keyType := 'any' ].
	valType ifNil: [ valType := 'any' ].
	^ '[', keyType, ']', valType
]

{ #category : 'type inference' }
ZealCompiler class >> inferType: aZealNode [
	"Type inference from a value expression"
	"Literals"
	(aZealNode isKindOf: ZealLiteral) ifTrue: [
		aZealNode literalType = #integer ifTrue: [ ^ 'int' ].
		aZealNode literalType = #float ifTrue: [ ^ 'float' ].
		aZealNode literalType = #string ifTrue: [ ^ 'string' ].
		aZealNode literalType = #char ifTrue: [ ^ 'char' ].
		aZealNode literalType = #boolean ifTrue: [ ^ 'logic' ] ].
	
	"Boolean symbols"
	(aZealNode isKindOf: ZealSymbolRef) ifTrue: [
		(aZealNode name = 'true' or: [aZealNode name = 'false']) ifTrue: [ ^ 'logic' ] ].
	
	"Arrays — infer element type from first element"
	(aZealNode isKindOf: ZealArray) ifTrue: [
		aZealNode elements notEmpty ifTrue: [
			| elemType |
			elemType := self inferType: aZealNode elements first.
			elemType ifNotNil: [ ^ '[]' , elemType ] ].
		^ '[]any' ].
	
	"Operators"
	(aZealNode isKindOf: ZealOperator) ifTrue: [
		(#('+' '-' '*' '/') includes: aZealNode operator) ifTrue: [ ^ self inferType: aZealNode operands first ].
		(#('=' '<>' '<' '>' '<=' '>=' 'and' 'or' 'not') includes: aZealNode operator) ifTrue: [ ^ 'logic' ] ].
	
	"Constructor/archetype calls: (class-name :field1 val1 :field2 val2)
	 A function call where the name starts with lowercase and has keyword args"
	(aZealNode isKindOf: ZealFunctionCall) ifTrue: [
		^ self inferTypeFromCall: aZealNode ].
	
	"Maps"
	(aZealNode isKindOf: ZealMap) ifTrue: [
		^ self inferMapType: aZealNode ].
	
	^ nil
]

{ #category : 'type inference' }
ZealCompiler class >> inferTypeFromCall: aFunctionCall [
	"Infer type from a function call.
	 Archetype: functionName = 'archetype', first arg is the type name."
	| fname |
	
	"Archetype instantiation: (class-name :field val ...)"
	aFunctionCall functionName = 'archetype' ifTrue: [
		| firstArg |
		firstArg := aFunctionCall arguments first.
		(firstArg isKindOf: ZealSymbolRef) ifTrue: [
			^ firstArg instVarNamed: 'name' ] ].
	
	"Direct call where name looks like a type and has keyword args"
	fname := aFunctionCall functionName.
	fname ifNil: [ ^ nil ].
	(aFunctionCall arguments anySatisfy: [:a | 
		(a isKindOf: ZealOperator) and: [a operator = ':=']]) ifTrue: [ ^ fname ].
	
	^ nil
]

{ #category : 'building' }
ZealCompiler class >> isIndexableType: aType [
	aType ifNil: [ ^ false ].
	(aType beginsWith: '[]') ifTrue: [ ^ true ].
	(aType beginsWith: '[') ifTrue: [ ^ true ].
	aType = 'string' ifTrue: [ ^ true ].
	^ false
]

{ #category : 'building' }
ZealCompiler class >> operators [
	^ ZealTheme operators , #('and' 'or' 'not' '?')
]

{ #category : 'building' }
ZealCompiler class >> parseBindingVectorNode: aVectorNode [
	"Return { bindings. predicates } from a binding vector."
	| items i bindings predicates |
	items := aVectorNode expressions.
	bindings := OrderedCollection new. predicates := OrderedCollection new.
	i := 1.
	[ i <= items size ] whileTrue: [
		| item |
		item := items at: i.
		(item isKindOf: ZealListNode)
			ifTrue: [ predicates add: (self buildExpression: item). i := i + 1 ]
			ifFalse: [
				(i + 1 <= items size)
					ifTrue: [ | r |
						r := self resolveNameNode: item.
						bindings add: (ZealBinding new name: (r at: #name); type: (r at: #type); value: (self buildExpression: (items at: i + 1))).
						i := i + 2 ]
					ifFalse: [ predicates add: (self buildExpression: item). i := i + 1 ] ] ].
	^ { bindings. predicates }
]

{ #category : 'compiling' }
ZealCompiler class >> parseOnly: aString [
	^ ZealParser parse: aString
]

{ #category : 'validation' }
ZealCompiler class >> requireArgs: min from: exprs forForm: formName [
	exprs size < min ifTrue: [ 
		^ self error: formName , ' requires at least ' , (min - 1) printString , ' argument(s): ' , (self usageFor: formName) ].
	^ nil
]

{ #category : 'validation' }
ZealCompiler class >> requireNameFrom: exprs forForm: formName [
	| nameNode |
	nameNode := exprs second.
	((nameNode isKindOf: ZealSymbolNode) or: [ nameNode isKindOf: ZealColonChainNode ])
		ifFalse: [ ^ self error: formName , ' name must be a symbol or name:type, got ' , nameNode class name ].
	^ self resolveNameNode: nameNode
]

{ #category : 'validation' }
ZealCompiler class >> requireVector: aNode forForm: formName label: label [
	(aNode isKindOf: ZealVectorNode) 
		ifFalse: [ ^ self error: formName , ' ' , label , ' must be a vector [...], got ' , aNode class name ].
	^ nil
]

{ #category : 'building' }
ZealCompiler class >> resolveNameNode: aNode [
	"Return dict with #name, #type, #specifiers from symbol or colonChain"
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		^ ZealColonChainResolver resolve: aNode value value ].
	^ Dictionary new
		at: #name put: aNode value value;
		at: #type put: nil;
		at: #specifiers put: #();
		at: #annotations put: #();
		yourself
]

{ #category : 'compiler' }
ZealCompiler class >> specialFormBuilders [
	^ Dictionary new
		at: 'def' put: #buildDef:; at: 'var' put: #buildVar:; at: 'set' put: #buildSet:;
		at: 'defn' put: #buildDefn:; at: 'defstruct' put: #buildDefstruct:;
		at: 'defenum' put: #buildDefenum:; at: 'defclass' put: #buildDefclass:;
		at: 'definterface' put: #buildDefinterface:;
		at: 'if' put: #buildIf:;
		at: 'for' put: #buildFor:; at: 'loop' put: #buildLoop:;
		at: 'block' put: #buildBlock:; at: 'do' put: #buildBlock:;
		at: 'defer' put: #buildDefer:; at: 'case' put: #buildCase:;
		at: 'module' put: #buildModule:; at: 'using' put: #buildUsing:;
		at: 'break' put: #buildBreak:; at: 'return' put: #buildReturn:;
		at: 'str' put: #buildStr:;
		yourself
]

{ #category : 'validation' }
ZealCompiler class >> usageFor: formName [
	| usages |
	usages := Dictionary new
		at: 'def' put: '(def name:type value)';
		at: 'var' put: '(var name:type value)';
		at: 'set' put: '(set name value)';
		at: 'defn' put: '(defn name:type [params] body)';
		at: 'defstruct' put: '(defstruct name [field:type val] ...)';
		at: 'defenum' put: '(defenum name val1 val2 ...)';
		at: 'defclass' put: '(defclass name:specs (parent) fields methods)';
		at: 'definterface' put: '(definterface name methods...)';
		at: 'if' put: '(if cond body) or (if cond body else)';
		at: 'let' put: '(let [name val ...] body)';
		at: 'for' put: '(for [name val ...] body)';
		at: 'case' put: '(case expr pattern body ...)';
		at: 'module' put: '(module name ...)';
		yourself.
	^ usages at: formName ifAbsent: [ formName ]
]
