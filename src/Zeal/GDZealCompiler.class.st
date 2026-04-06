Class {
	#name : 'GDZealCompiler',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'building - forms' }
GDZealCompiler class >> buildAs: aListNode [
	"(as expr @type field...) -> ZealFunctionCall with 'as' + property chain"
	| exprs |
	exprs := aListNode expressions.
	^ ZealFunctionCall new
		functionName: 'as';
		arguments: (exprs allButFirst collect: [ :e | self buildExpression: e ])
]

{ #category : 'helpers' }
GDZealCompiler class >> buildBody: exprs [
	"Build body expressions"
	^ exprs collect: [ :e | self buildExpression: e ]
]

{ #category : 'building - GECS' }
GDZealCompiler class >> buildDefcomp: aListNode [
	"Handles shorthand + explicit export forms.
	 Shorthand: (defcomp health current:float 100.0 maximum:float 100.0 (init ...))
	 Explicit: (defcomp health (export current:float 100.0) (init ...))
	 Tag: (defcomp dead)"
	| exprs name fields methods cls bodyForms i |
	exprs := aListNode expressions.
	name := exprs second value value.
	fields := OrderedCollection new.
	methods := OrderedCollection new.
	bodyForms := exprs allButFirst allButFirst.
	i := 1.
	[ i <= bodyForms size ] whileTrue: [
		| item |
		item := bodyForms at: i.
		"Shorthand field: colonChain + default"
		(item isKindOf: ZealColonChainNode) ifTrue: [
			| resolved field |
			resolved := self resolveNameNode: item.
			field := ZealField new
				name: (resolved at: #name);
				type: (resolved at: #type);
				isMutable: true.
			(resolved at: #type) ifNil: [
				(resolved at: #annotations) ifNotEmpty: [ :anns |
					(anns detect: [ :a | a beginsWith: '@' ] ifNone: [ nil ])
						ifNotNil: [ :t | field type: t ] ] ].
			(i + 1 <= bodyForms size
				and: [ ((bodyForms at: i + 1) isKindOf: ZealColonChainNode) not
				and: [ ((bodyForms at: i + 1) isKindOf: ZealListNode) not ] ]) ifTrue: [
				field defaultValue: (self buildExpression: (bodyForms at: i + 1)).
				i := i + 1 ].
			fields add: field ]
		ifFalse: [
			(item isKindOf: ZealListNode) ifTrue: [
				| head |
				head := item expressions first value value.
				head = 'export' ifTrue: [
					| resolved field |
					resolved := self resolveNameNode: item expressions second.
					field := ZealField new
						name: (resolved at: #name);
						type: (resolved at: #type);
						isMutable: true.
					(resolved at: #type) ifNil: [
						(resolved at: #annotations) ifNotEmpty: [ :anns |
							(anns detect: [ :a | a beginsWith: '@' ] ifNone: [ nil ])
								ifNotNil: [ :t | field type: t ] ] ].
					item expressions size > 2 ifTrue: [
						field defaultValue: (self buildExpression: item expressions third) ].
					fields add: field ].
				head = 'init' ifTrue: [
					| params bodyExprs func |
					params := self buildInitParams: item expressions second.
					bodyExprs := self buildBody: item expressions allButFirst allButFirst.
					func := ZealFunction new name: '_init'; parameters: params; body: bodyExprs.
					methods add: func ] ] ].
		i := i + 1 ].
	cls := ZealClass new
		name: name;
		superclass: 'Component';
		annotations: #('gecs_component');
		fields: fields;
		methods: methods.
	fields do: [ :f | f parent: cls ].
	methods do: [ :m | m parent: cls ].
	^ cls
]

{ #category : 'building - GECS' }
GDZealCompiler class >> buildDefentity: aListNode [
	"(defentity player (components [@health @velocity]) (on-ready body)) -> ZealClass"
	| exprs name methods cls componentRefs |
	exprs := aListNode expressions.
	name := exprs second value value.
	methods := OrderedCollection new.
	componentRefs := #().
	exprs allButFirst allButFirst do: [ :item |
		(item isKindOf: ZealListNode) ifTrue: [
			| head |
			head := item expressions first value value.
			head = 'components' ifTrue: [
				componentRefs := item expressions second expressions
					collect: [ :c | c value value ] ].
			(#('on-ready' 'on-destroy' 'on-enable' 'on-disable') includes: head) ifTrue: [
				methods add: (ZealFunction new
					name: head;
					parameters: #();
					body: (self buildBody: item expressions allButFirst)) ] ] ].
	cls := ZealClass new
		name: name;
		superclass: 'Entity';
		annotations: (Array with: 'gecs_entity' with: ('components=' , (',' join: componentRefs)));
		fields: #();
		methods: methods.
	methods do: [ :m | m parent: cls ].
	^ cls
]

{ #category : 'building - GECS' }
GDZealCompiler class >> buildDefobserver: aListNode [
	"(defobserver health-observer (watch @health) (match ...) (on-changed [...] body)) -> ZealClass"
	| exprs name methods cls watchRef |
	exprs := aListNode expressions.
	name := exprs second value value.
	methods := OrderedCollection new.
	watchRef := nil.
	exprs allButFirst allButFirst do: [ :item |
		(item isKindOf: ZealListNode) ifTrue: [
			| head |
			head := item expressions first value value.
			head = 'watch' ifTrue: [
				watchRef := item expressions second value value.
				methods add: (ZealFunction new
					name: 'watch';
					parameters: #();
					body: { ZealSymbolRef new name: watchRef }) ].
			head = 'match' ifTrue: [
				methods add: (ZealFunction new
					name: 'match';
					parameters: #();
					body: (self buildBody: item expressions allButFirst)) ].
			(#('on-added' 'on-removed' 'on-changed') includes: head) ifTrue: [
				| paramNames |
				paramNames := item expressions second expressions collect: [ :p | p value value ].
				methods add: (ZealFunction new
					name: head;
					parameters: (paramNames collect: [ :p | ZealParameter new name: p ]);
					body: (self buildBody: item expressions allButFirst allButFirst)) ] ] ].
	cls := ZealClass new
		name: name;
		superclass: 'Observer';
		annotations: (watchRef ifNotNil: [ Array with: 'gecs_observer' with: 'watch=' , watchRef ] ifNil: [ #('gecs_observer') ]);
		fields: #();
		methods: methods.
	methods do: [ :m | m parent: cls ].
	^ cls
]

{ #category : 'building - GECS' }
GDZealCompiler class >> buildDefsystem: aListNode [
	"Handles both shorthand and full form.
	 Shorthand: (defsystem name [@comp1 @comp2] (with-none [...]) body...)
	 Full: (defsystem name (query ...) (process [...] body...) ...)"
	| exprs name rest cls methods |
	exprs := aListNode expressions.
	name := exprs second value value.
	rest := exprs allButFirst allButFirst.
	methods := OrderedCollection new.
	"Detect: vector after name = shorthand"
	(rest notEmpty and: [ rest first isKindOf: ZealVectorNode ]) ifTrue: [
		| compVector queryMods bodyExprs |
		compVector := rest first.
		queryMods := OrderedCollection new.
		bodyExprs := OrderedCollection new.
		rest allButFirst do: [ :form |
			| isQM |
			isQM := false.
			(form isKindOf: ZealListNode) ifTrue: [
				| head |
				head := form expressions first value value.
				(#('with-none' 'with-any' 'with-group' 'without-group' 'enabled' 'disabled') includes: head)
					ifTrue: [ isQM := true ] ].
			isQM ifTrue: [ queryMods add: form ] ifFalse: [ bodyExprs add: form ] ].
		"Build query method (stores raw for codegen)"
		methods add: (ZealFunction new name: 'query'; parameters: #(); body: { compVector } , queryMods).
		"Build process method"
		methods add: (ZealFunction new name: 'process'; parameters: #(); body: (self buildBody: bodyExprs)) ]
	ifFalse: [
		"Full form"
		rest do: [ :item |
			(item isKindOf: ZealListNode) ifTrue: [
				| head |
				head := item expressions first value value.
				head = 'query' ifTrue: [
					methods add: (ZealFunction new name: 'query'; parameters: #(); body: (self buildBody: item expressions allButFirst)) ].
				head = 'process' ifTrue: [
					| paramNames |
					paramNames := item expressions second expressions collect: [ :p | p value value ].
					methods add: (ZealFunction new
						name: 'process';
						parameters: (paramNames collect: [ :p | ZealParameter new name: p ]);
						body: (self buildBody: item expressions allButFirst allButFirst)) ].
				head = 'deps' ifTrue: [
					methods add: (ZealFunction new name: 'deps'; parameters: #(); body: { self buildExpression: item expressions second }) ].
				head = 'setup' ifTrue: [
					methods add: (ZealFunction new name: 'setup'; parameters: #(); body: (self buildBody: item expressions allButFirst)) ] ] ] ].
	cls := ZealClass new
		name: name;
		superclass: 'System';
		annotations: #('gecs_system');
		fields: #();
		methods: methods.
	methods do: [ :m | m parent: cls ].
	^ cls
]

{ #category : 'compiling' }
GDZealCompiler class >> buildExpression: aNode [
	"Dispatch — lists go through our buildList, atoms/vectors/maps delegate to ZealCompiler"
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self buildList: aNode ].
	^ ZealCompiler buildExpression: aNode
]

{ #category : 'compiling' }
GDZealCompiler class >> buildFromAST: aZealProgramNode [
	"Walk AST and build ZealNode objects"
	| results |
	results := aZealProgramNode expressions collect: [ :expr |
		self buildExpression: expr ].
	results size = 1 ifTrue: [ ^ results first ].
	^ results
]

{ #category : 'helpers' }
GDZealCompiler class >> buildInitParams: aVectorNode [
	"Parse init params: [name:type default name:type default ...]"
	| items params i |
	items := aVectorNode expressions.
	params := OrderedCollection new.
	i := 1.
	[ i <= items size ] whileTrue: [
		| node |
		node := items at: i.
		(node isKindOf: ZealColonChainNode) ifTrue: [
			| resolved param |
			resolved := self resolveNameNode: node.
			param := ZealParameter new
				name: (resolved at: #name);
				type: (resolved at: #type).
			"Handle @type in annotations"
			(resolved at: #type) ifNil: [
				(resolved at: #annotations) ifNotEmpty: [ :anns |
					(anns detect: [ :a | a beginsWith: '@' ] ifNone: [ nil ])
						ifNotNil: [ :t | param type: t ] ] ].
			"Next item might be default value"
			(i + 1 <= items size and: [ (items at: i + 1) isKindOf: ZealColonChainNode ]) not
				ifTrue: [
					i + 1 <= items size ifTrue: [
						param defaultValue: (self buildExpression: (items at: i + 1)).
						i := i + 1 ] ].
			params add: param ]
		ifFalse: [ "Skip non-colon-chain items" ].
		i := i + 1 ].
	^ params
]

{ #category : 'compiling' }
GDZealCompiler class >> buildList: aListNode [
	"Check GDZeal forms first, then delegate to ZealCompiler for everything else"
	| exprs head headStr |
	exprs := aListNode expressions.
	exprs isEmpty ifTrue: [ ^ ZealLiteral new value: '()'; literalType: #unit ].
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	(head isKindOf: ZealColonChainNode) ifTrue: [
		headStr := (ZealColonChainResolver resolve: head value value) at: #name ].
	headStr ifNil: [ ^ ZealCompiler buildFunctionCall: aListNode ].
	"GDZeal-specific forms"
	self specialFormBuilders at: headStr ifPresent: [ :sel | ^ self perform: sel with: aListNode ].
	"Everything else -> ZealCompiler"
	^ ZealCompiler buildList: aListNode
]

{ #category : 'building - forms' }
GDZealCompiler class >> buildMatch: aListNode [
	"(match expr pat1 body1 pat2 body2 ...) -> ZealCase"
	| exprs target cases pairs |
	exprs := aListNode expressions.
	target := self buildExpression: exprs second.
	pairs := exprs allButFirst allButFirst.
	cases := OrderedCollection new.
	1 to: pairs size by: 2 do: [ :i |
		cases add: { self buildExpression: (pairs at: i). self buildExpression: (pairs at: i + 1) } ].
	^ ZealCase new target: target; cases: cases
]

{ #category : 'building - forms' }
GDZealCompiler class >> buildWhen: aListNode [
	"(when cond body...) -> ZealIf with no else"
	| exprs cond body |
	exprs := aListNode expressions.
	cond := self buildExpression: exprs second.
	body := self buildBody: exprs allButFirst allButFirst.
	^ ZealIf new
		clauses: { { cond. body } };
		elseBody: nil
]

{ #category : 'compiling' }
GDZealCompiler class >> compile: aString [
	"Parse GDZeal source -> ZealNode objects, store rawSource"
	| ast result |
	ast := ZealParser parse: aString.
	result := self buildFromAST: ast.
	"Store raw source on top-level definitions"
	(result isKindOf: Collection)
		ifTrue: [ result do: [ :n | n rawSource: aString ] ]
		ifFalse: [ result rawSource: aString ].
	^ result
]

{ #category : 'compiling' }
GDZealCompiler class >> compileToGDScript: aString [
	"Full pipeline: parse -> ZealNode objects -> GDScript string"
	^ GDZealCodeGenerator compile: aString
]

{ #category : 'compiling' }
GDZealCompiler class >> compileToGDScript: aString withRegistry: aRegistry [
	"Full pipeline with shared component registry"
	^ GDZealCodeGenerator compile: aString withRegistry: aRegistry
]

{ #category : 'helpers' }
GDZealCompiler class >> resolveNameNode: aNode [
	^ ZealCompiler resolveNameNode: aNode
]

{ #category : 'compiling' }
GDZealCompiler class >> specialFormBuilders [
	"Only GDZeal-specific forms. Shared forms delegate to ZealCompiler."
	^ Dictionary new
		at: 'defcomp' put: #buildDefcomp:;
		at: 'defentity' put: #buildDefentity:;
		at: 'defsystem' put: #buildDefsystem:;
		at: 'defobserver' put: #buildDefobserver:;
		at: 'when' put: #buildWhen:;
		at: 'match' put: #buildMatch:;
		at: 'as' put: #buildAs:;
		yourself
]

{ #category : 'helpers' }
GDZealCompiler class >> stripClassPrefix: aName [
	^ ZealCompiler stripClassPrefix: aName
]
