Class {
	#name : 'ZealCompiler',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'building' }
ZealCompiler class >> buildAtom: aNode [
	"Build a ZealLiteral or ZealSymbolRef from an atom node."
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		^ ZealSymbolRef new name: aNode value value ].
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
	(aNode isKindOf: ZealHexLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #hex ].
	(aNode isKindOf: ZealRangeLiteralNode) ifTrue: [
		^ ZealLiteral new value: aNode value value; literalType: #range ].
	"Fallback"
	^ ZealLiteral new value: aNode value value; literalType: #unknown
]

{ #category : 'building' }
ZealCompiler class >> buildBlock: aListNode [
	^ ZealBlock new body: (aListNode expressions allButFirst collect: [:e | self buildExpression: e])
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

{ #category : 'building' }
ZealCompiler class >> buildDef: aListNode [
	| exprs err resolved |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'def') ifNotNil: [ ^ err ].
	resolved := self requireNameFrom: exprs forForm: 'def'.
	(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
	^ ZealVariable new
		name: (resolved at: #name); type: (resolved at: #type);
		specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
		isMutable: false; value: (self buildExpression: exprs third)
]

{ #category : 'building' }
ZealCompiler class >> buildDefclass: aListNode [
	| exprs err resolved rest parentName fields methods cls |
	exprs := aListNode expressions.
	(err := self requireArgs: 2 from: exprs forForm: 'defclass') ifNotNil: [ ^ err ].
	resolved := self requireNameFrom: exprs forForm: 'defclass'.
	(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
	rest := exprs allButFirst allButFirst. parentName := nil.
	(rest notEmpty and: [ rest first isKindOf: ZealListNode ]) ifTrue: [
		rest first expressions isEmpty ifTrue: [ ^ self error: 'defclass ' , (resolved at: #name) , ' parent list is empty' ].
		parentName := rest first expressions first value value. rest := rest allButFirst ].
	fields := OrderedCollection new. methods := OrderedCollection new.
	rest do: [:item | | built |
		built := self buildExpression: item.
		(built isKindOf: ZealCompileError) ifTrue: [ ^ built ].
		(built isKindOf: ZealFunction) ifTrue: [ methods add: built ]
			ifFalse: [ (built isKindOf: ZealVariable)
				ifTrue: [ fields add: (ZealField new name: built name; type: built type; defaultValue: built value; isMutable: built isMutable) ]
				ifFalse: [ fields add: built ] ] ].
	cls := ZealClass new name: (resolved at: #name); specifiers: (resolved at: #specifiers);
		superclass: parentName; fields: fields; methods: methods.
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
		body: (bodyExprs collect: [:e | self buildExpression: e]).
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

{ #category : 'building' }
ZealCompiler class >> buildIf: aListNode [
	| args err clauses elseBody |
	args := aListNode expressions allButFirst.
	(err := self requireArgs: 3 from: aListNode expressions forForm: 'if') ifNotNil: [ ^ err ].
	clauses := OrderedCollection new. elseBody := nil.
	[ args notEmpty ] whileTrue: [
		args size < 2 ifTrue: [ elseBody := self buildExpression: args first. args := #() ]
		ifFalse: [
			((args first isKindOf: ZealKeywordNode) and: [ args first value value = ':else' ]) ifTrue: [
				elseBody := self buildExpression: args second. args := #() ]
			ifFalse: [ clauses add: { self buildExpression: args first. self buildExpression: args second }.
				args := args allButFirst allButFirst ] ] ].
	^ ZealIf new clauses: clauses; elseBody: elseBody
]

{ #category : 'building' }
ZealCompiler class >> buildLet: aListNode [
	| exprs err parsed |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'let') ifNotNil: [ ^ err ].
	(err := self requireVector: exprs second forForm: 'let' label: 'bindings') ifNotNil: [ ^ err ].
	parsed := self parseBindingVectorNode: exprs second.
	^ ZealLet new bindings: parsed first; predicates: parsed second;
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
ZealCompiler class >> buildReturn: aListNode [
	| exprs |
	exprs := aListNode expressions.
	^ ZealReturn new value: (exprs size > 1 ifTrue: [ self buildExpression: exprs second ] ifFalse: [ nil ])
]

{ #category : 'building' }
ZealCompiler class >> buildSet: aListNode [
	| exprs err |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'set') ifNotNil: [ ^ err ].
	(exprs second isKindOf: ZealSymbolNode)
		ifFalse: [ ^ self error: 'set target must be a symbol, got ' , exprs second class name ].
	^ ZealSet new target: exprs second value value; value: (self buildExpression: exprs third)
]

{ #category : 'building' }
ZealCompiler class >> buildUsing: aListNode [
	^ ZealUsing new path: aListNode expressions second value value
]

{ #category : 'building' }
ZealCompiler class >> buildVar: aListNode [
	| exprs err resolved |
	exprs := aListNode expressions.
	(err := self requireArgs: 3 from: exprs forForm: 'var') ifNotNil: [ ^ err ].
	resolved := self requireNameFrom: exprs forForm: 'var'.
	(resolved isKindOf: ZealCompileError) ifTrue: [ ^ resolved ].
	^ ZealVariable new
		name: (resolved at: #name); type: (resolved at: #type);
		specifiers: (resolved at: #specifiers); annotations: (resolved at: #annotations);
		isMutable: true; value: (self buildExpression: exprs third)
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

{ #category : 'compiling' }
ZealCompiler class >> compileToVerse: aString [
	"Parse Zeal source, build objects, compile to Verse string."
	| nodes |
	nodes := self compile: aString.
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

{ #category : 'building' }
ZealCompiler class >> operators [
	^ ZealTheme operators , #('and' 'or' 'not')
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

{ #category : 'building' }
ZealCompiler class >> specialFormBuilders [
	^ Dictionary new
		at: 'def' put: #buildDef:; at: 'var' put: #buildVar:; at: 'set' put: #buildSet:;
		at: 'defn' put: #buildDefn:; at: 'defstruct' put: #buildDefstruct:;
		at: 'defenum' put: #buildDefenum:; at: 'defclass' put: #buildDefclass:;
		at: 'definterface' put: #buildDefinterface:;
		at: 'if' put: #buildIf:; at: 'let' put: #buildLet:;
		at: 'for' put: #buildFor:; at: 'loop' put: #buildLoop:;
		at: 'block' put: #buildBlock:; at: 'do' put: #buildBlock:;
		at: 'defer' put: #buildDefer:; at: 'case' put: #buildCase:;
		at: 'module' put: #buildModule:; at: 'using' put: #buildUsing:;
		at: 'break' put: #buildBreak:; at: 'return' put: #buildReturn:;
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
