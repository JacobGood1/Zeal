Class {
	#name : 'VersePP2ToZeal',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'converting' }
VersePP2ToZeal class >> convert: parseResult [
	| results |
	(parseResult isKindOf: PP2Failure) ifTrue: [ ^ ZealCompileError new message: parseResult message ].
	results := parseResult collect: [:item | self convertItem: item].
	results size = 1 ifTrue: [ ^ results first ].
	^ results
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertAnnotated: item [
	| inner |
	inner := self convertItem: item third.
	(inner respondsTo: #annotations:) ifTrue: [
		inner annotations: (inner annotations , {'@' , item second}) ].
	^ inner
]

{ #category : 'expressions' }
VersePP2ToZeal class >> convertArchetype: item [
	"item = {#archetype. typeExpr. fieldInits}
	 fieldInits = array of {name. valueExpr}"
	| typeName fields |
	typeName := self convertExpr: item second.
	fields := item third collect: [:f |
		ZealOperator new 
			operator: ':='; 
			operands: { ZealSymbolRef new name: f first. self convertExpr: f second } ].
	^ ZealFunctionCall new functionName: 'archetype'; arguments: {typeName} , fields
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertClass: item [
	"item = {#class. name. specs. {parents. statements}}"
	| data parentName fields methods cls |
	data := item fourth.
	parentName := data first ifNotNil: [:p | p notEmpty ifTrue: [p first] ifFalse: [nil]] ifNil: [nil].
	fields := OrderedCollection new. methods := OrderedCollection new.
	data second do: [:s |
		| conv |
		conv := self convertItem: s.
		(conv isKindOf: ZealFunction) ifTrue: [ methods add: conv ]
		ifFalse: [ (conv isKindOf: ZealVariable) ifTrue: [
			fields add: (ZealField new name: conv name; type: conv type; defaultValue: conv value; isMutable: conv isMutable; specifiers: conv specifiers) ] ] ].
	cls := ZealClass new name: item second; specifiers: item third asArray;
		superclass: parentName; fields: fields; methods: methods.
	fields do: [:f | f parent: cls]. methods do: [:m | m parent: cls].
	^ cls
]

{ #category : 'expressions' }
VersePP2ToZeal class >> convertCondition: item [
	"Convert a condition - either a regular expression or a binding (name := expr)"
	((item isKindOf: Array) and: [item notEmpty and: [item first = #binding]]) ifTrue: [
		^ ZealOperator new 
			operator: ':=';
			operands: { ZealSymbolRef new name: item second. self convertExpr: item third } ].
	^ self convertExpr: item
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertConst: item [
	"item = {#const. name. type. value} or {#const. name. type. value. specs}"
	| v |
	v := ZealVariable new name: item second; type: item third; isMutable: false;
		value: (item fourth ifNotNil: [:val | self convertExpr: val]).
	item size >= 5 ifTrue: [ v specifiers: item fifth asArray ].
	^ v
]

{ #category : 'expressions' }
VersePP2ToZeal class >> convertElse: item [
	item first = #else ifTrue: [ 
		| body |
		body := item second collect: [:s | self convertItem: s].
		^ body size = 1 ifTrue: [body first] ifFalse: [ZealBlock new body: body] ].
	item first = #elseif ifTrue: [
		| conds cond body |
		conds := item second collect: [:c | self convertExpr: c].
		cond := conds first.
		conds allButFirst do: [:c | cond := ZealOperator new operator: 'and'; operands: {cond. c}].
		body := item third collect: [:s | self convertItem: s].
		body size = 1 ifTrue: [body := body first] ifFalse: [body := ZealBlock new body: body].
		^ ZealIf new clauses: {{cond. body}}; elseBody: (item fourth ifNotNil: [:e | self convertElse: e]) ].
	^ self convertExpr: item
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertEnum: item [
	^ ZealEnum new name: item second; values: item fourth
]

{ #category : 'expressions' }
VersePP2ToZeal class >> convertExpr: item [
	(item isKindOf: Array) ifFalse: [ ^ ZealLiteral new value: item asString; literalType: #raw ].
	item isEmpty ifTrue: [ ^ ZealLiteral new value: '()'; literalType: #unit ].
	item first = #int ifTrue: [ ^ ZealLiteral new value: item second; literalType: #integer ].
	item first = #float ifTrue: [ ^ ZealLiteral new value: item second; literalType: #float ].
	item first = #string ifTrue: [ ^ ZealLiteral new value: item second; literalType: #string ].
	item first = #char ifTrue: [ ^ ZealLiteral new value: item second; literalType: #char ].
	item first = #bool ifTrue: [ ^ ZealLiteral new value: item second; literalType: #boolean ].
	item first = #ident ifTrue: [ ^ ZealSymbolRef new name: item second ].
	item first = #binop ifTrue: [ ^ ZealOperator new operator: item second asString; operands: {self convertExpr: item third. self convertExpr: item fourth} ].
	item first = #unary ifTrue: [ ^ ZealOperator new operator: item second; operands: {self convertExpr: item third} ].
	item first = #call ifTrue: [
		| recv |
		recv := self convertExpr: item second.
		((recv isKindOf: ZealFunctionCall) and: [recv functionName = '.']) ifTrue: [
			^ ZealFunctionCall new functionName: '.'; arguments: recv arguments , (item third collect: [:a | self convertExpr: a]) ].
		(recv isKindOf: ZealSymbolRef) ifTrue: [
			^ ZealFunctionCall new functionName: recv name; arguments: (item third collect: [:a | self convertExpr: a]) ].
		^ ZealFunctionCall new functionName: recv compileToVerse; arguments: (item third collect: [:a | self convertExpr: a]) ].
	item first = #index ifTrue: [
		^ ZealFunctionCall new functionName: '[]'; arguments: {self convertExpr: item second} , (item third collect: [:a | self convertExpr: a]) ].
	item first = #member ifTrue: [
		^ ZealFunctionCall new functionName: '.'; arguments: {self convertExpr: item second. ZealSymbolRef new name: item third} ].
	item first = #query ifTrue: [ ^ ZealOperator new operator: '?'; operands: {self convertExpr: item second} ].
	item first = #archetype ifTrue: [ ^ self convertArchetype: item ].
	item first = #block ifTrue: [ ^ ZealBlock new body: (item second collect: [:s | self convertItem: s]) ].
	item first = #if ifTrue: [ ^ self convertIfExpr: item ].
	item first = #for ifTrue: [ ^ self convertForExpr: item ].
	item first = #loop ifTrue: [ ^ ZealLoop new body: (item second collect: [:s | self convertItem: s]) ].
	item first = #set ifTrue: [ ^ ZealSet new target: item second; operator: item third asString; value: (self convertExpr: item fourth) ].
	item first = #return ifTrue: [ ^ ZealReturn new value: (self convertExpr: item second) ].
	item first = #range ifTrue: [ ^ ZealOperator new operator: '..'; operands: {self convertExpr: item second. self convertExpr: item third} ].
	item first = #array ifTrue: [ ^ ZealArray new elements: (item second collect: [:e | self convertExpr: e]) ].
	item first = #map ifTrue: [ ^ ZealMap new entries: (item second collect: [:e | {self convertExpr: e first. self convertExpr: e second}]) ].
	item first = #case ifTrue: [ ^ ZealCase new target: (self convertExpr: item second); cases: (item third collect: [:e | {self convertExpr: e first. self convertExpr: e second}]) ].
	item = #break ifTrue: [ ^ ZealBreak new ].
	^ ZealLiteral new value: item printString; literalType: #raw
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertField: item [
	^ ZealVariable new name: item second; type: item third; isMutable: false; value: nil
]

{ #category : 'expressions' }
VersePP2ToZeal class >> convertForExpr: item [
	| bindings predicates body |
	bindings := OrderedCollection new. predicates := OrderedCollection new.
	item second do: [:c |
		c first = #forIn ifTrue: [ bindings add: (ZealBinding new name: c second; value: (self convertExpr: c third)) ].
		c first = #forBind ifTrue: [ bindings add: (ZealBinding new name: c second; value: (self convertExpr: c third)) ].
		c first = #forFilter ifTrue: [ predicates add: (self convertExpr: c second) ] ].
	body := item third collect: [:s | self convertItem: s].
	^ ZealFor new bindings: bindings; predicates: predicates; body: body
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertFunc: item [
	"item = {#func. name. declSpecs. params. sigSpecs. retType. body}"
	| func params |
	params := (item fourth ifNil: [#()]) collect: [:p |
		p first = #param ifTrue: [ ZealParameter new name: p second; type: p third ]
		ifFalse: [ p first = #funcParam ifTrue: [ ZealParameter new name: p second; type: p fifth ]
		ifFalse: [ ZealParameter new name: p second ] ] ].
	func := ZealFunction new
		name: item second;
		specifiers: (item third asArray , item fifth asArray);
		effects: item fifth asArray;
		parameters: params;
		type: item sixth;
		body: { self convertExpr: item seventh }.
	params do: [:p | p parent: func].
	func body do: [:b | b parent: func].
	^ func
]

{ #category : 'expressions' }
VersePP2ToZeal class >> convertIfExpr: item [
	| conds cond body |
	conds := item second collect: [:c | self convertCondition: c ].
	body := item third collect: [:s | self convertItem: s].
	body size = 1 ifTrue: [ body := body first ] ifFalse: [ body := ZealBlock new body: body ].
	conds size = 1 
		ifTrue: [ cond := conds first ]
		ifFalse: [ cond := ZealOperator new operator: ','; operands: conds asArray ].
	^ ZealIf new clauses: {{cond. body}}; elseBody: (item fourth ifNotNil: [:e | self convertElse: e])
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertInterface: item [
	| data methods |
	data := item fourth.
	methods := data second collect: [:s | self convertItem: s].
	^ ZealInterface new name: item second; methods: methods
]

{ #category : 'converting' }
VersePP2ToZeal class >> convertItem: item [
	^ [ 
	(item isKindOf: Array) ifFalse: [ ^ ZealLiteral new value: item asString; literalType: #raw ].
	item isEmpty ifTrue: [ ^ ZealLiteral new value: '()'; literalType: #unit ].
	item first = #const ifTrue: [ ^ self convertConst: item ].
	item first = #var ifTrue: [ ^ self convertVar: item ].
	item first = #field ifTrue: [ ^ self convertField: item ].
	item first = #func ifTrue: [ ^ self convertFunc: item ].
	item first = #class ifTrue: [ ^ self convertClass: item ].
	item first = #struct ifTrue: [ ^ self convertStruct: item ].
	item first = #enum ifTrue: [ ^ self convertEnum: item ].
	item first = #interface ifTrue: [ ^ self convertInterface: item ].
	item first = #module ifTrue: [ ^ self convertModule: item ].
	item first = #using ifTrue: [ ^ ZealUsing new path: item second ].
	item first = #annotated ifTrue: [ ^ self convertAnnotated: item ].
	self convertExpr: item
	] on: Error do: [:e | ZealCompileError new message: e messageText ]
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertModule: item [
	| usings defs mod |
	usings := OrderedCollection new. defs := OrderedCollection new.
	item fourth do: [:s |
		| conv |
		conv := self convertItem: s.
		(conv isKindOf: ZealUsing) ifTrue: [usings add: conv] ifFalse: [defs add: conv]].
	mod := ZealModule new name: item second; kind: #inline; usings: usings; definitions: defs.
	usings do: [:u | u parent: mod]. defs do: [:d | d parent: mod].
	^ mod
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertStruct: item [
	| fields |
	fields := item fourth collect: [:s |
		| conv |
		conv := self convertItem: s.
		(conv isKindOf: ZealVariable) ifTrue: [
			ZealField new name: conv name; type: conv type; defaultValue: conv value ]
		ifFalse: [ conv ] ].
	^ ZealStruct new name: item second; fields: fields
]

{ #category : 'definitions' }
VersePP2ToZeal class >> convertVar: item [
	"item = {#var. name. specs. type. value}"
	| typ |
	typ := item fourth.
	(typ isKindOf: String) ifFalse: [ typ := nil ].
	^ ZealVariable new 
		name: item second; 
		specifiers: ((item third isKindOf: Collection) ifTrue: [item third asArray] ifFalse: [#()]);
		type: typ;
		isMutable: true;
		value: (item fifth ifNotNil: [:v | self convertExpr: v])
]
