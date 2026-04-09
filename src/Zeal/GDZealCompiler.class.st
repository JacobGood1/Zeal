Class {
	#name : 'GDZealCompiler',
	#superclass : 'ZealCompiler',
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

{ #category : 'special forms' }
GDZealCompiler class >> buildDefcomp: aListNode [
	"(defcomp name var1 val1 var2 val2 ... (init [...] body))
	 Fields are simply pairs: variable on left, value on right.
	 Tag form: (defcomp dead) — no fields."
	| exprs name fields methods bodyForms i cls |
	exprs := aListNode expressions.
	name := exprs second value value.
	fields := OrderedCollection new.
	methods := OrderedCollection new.
	bodyForms := exprs allButFirst allButFirst.
	i := 1.
	[ i <= bodyForms size ] whileTrue: [
		| item |
		item := bodyForms at: i.
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
				item expressions size > 2 ifTrue: [
					field defaultValue: (self buildExpression: item expressions third) ].
				fields add: field ].
			head = 'init' ifTrue: [
				| params bodyExprs func |
				params := self buildInitParams: item expressions second.
				bodyExprs := self buildBody: item expressions allButFirst allButFirst.
				func := ZealFunction new name: '_init'; parameters: params; body: bodyExprs.
				methods add: func ] ]
		ifFalse: [
			| field fieldName fieldType |
			(item isKindOf: ZealColonChainNode) ifTrue: [
				| resolved |
				resolved := self resolveNameNode: item.
				fieldName := resolved at: #name.
				fieldType := resolved at: #type.
				fieldType ifNil: [
					(resolved at: #annotations) ifNotEmpty: [ :anns |
						(anns detect: [ :a | a beginsWith: '@' ] ifNone: [ nil ])
							ifNotNil: [ :t | fieldType := t ] ] ] ]
			ifFalse: [
				fieldName := item value value.
				fieldType := nil ].
			field := ZealField new name: fieldName; type: fieldType; isMutable: true.
			(i + 1 <= bodyForms size and: [
				((bodyForms at: i + 1) isKindOf: ZealListNode) not ]) ifTrue: [
				| nextItem |
				nextItem := bodyForms at: i + 1.
				(nextItem isKindOf: ZealColonChainNode)
					ifFalse: [
						field defaultValue: (self buildExpression: nextItem).
						fieldType ifNil: [ field type: (self inferTypeFromValue: nextItem) ].
						i := i + 1 ] ].
			fields add: field ].
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

{ #category : 'building' }
GDZealCompiler class >> buildDefcosystem: aListNode [
	"(defcosystem name body...)
	 (defcosystem name [binding1 binding2 ...] body...)
	 Builds a ZealClass for a coroutine-system component (formerly defcosystem) — a stateful
	 component plus its driving system, defined together. Bindings are name:type pairs
	 that get queried by the auto-generated system."
	| exprs name bodyForms bindings cls third stateField timerField |
	exprs := aListNode expressions.
	name := exprs second value value.
	bindings := OrderedCollection new.
	bodyForms := exprs allButFirst allButFirst.
	bodyForms isEmpty ifFalse: [
		third := bodyForms first.
		(third isKindOf: ZealVectorNode) ifTrue: [
			bindings := self parseFsmBindings: third.
			bodyForms := bodyForms allButFirst ] ].
	
	cls := ZealClass new
		name: name;
		superclass: 'Component';
		annotations: { 'gecs_component'. 'fsm'. 'fsm_bindings' -> bindings };
		fields: OrderedCollection new;
		methods: OrderedCollection new.
	
	stateField := ZealField new name: '_state'; type: 'int'; isMutable: true; defaultValue: (ZealLiteral new value: '0').
	stateField parent: cls.
	cls fields add: stateField.
	
	timerField := ZealField new name: '_timer'; type: 'float'; isMutable: true; defaultValue: (ZealLiteral new value: '0.0').
	timerField parent: cls.
	cls fields add: timerField.
	
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

{ #category : 'building' }
GDZealCompiler class >> buildList: aListNode [
	"Check GDZeal forms first, then delegate to ZealCompiler for everything else.
	 If the head is a non-symbol expression (e.g. ((juxt f g) x) — calling the result
	 of another expression), we can't dispatch to a name-based builder; return a
	 placeholder so build doesn't crash. Codegen never visits this output anyway —
	 GDZealCodeGenerator walks the raw parse tree directly."
	| exprs head headStr |
	exprs := aListNode expressions.
	exprs isEmpty ifTrue: [ ^ ZealLiteral new value: '()'; literalType: #unit ].
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	(head isKindOf: ZealColonChainNode) ifTrue: [
		headStr := (ZealColonChainResolver resolve: head value value) at: #name ].
	headStr ifNil: [
		"Expression-as-head — return an opaque placeholder."
		^ ZealFunctionCall new
			functionName: '__expr_call__';
			arguments: OrderedCollection new ].
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
	"Parse GDZeal source -> ZealNode objects, store rawSource.
	 Pre-processes λ to fn so the parser accepts lambda-character source.
	 Stores the ORIGINAL source (with λ) as rawSource so the editor preserves it."
	| preprocessed ast result |
	preprocessed := GDZealCodeGenerator preprocess: aString.
	ast := ZealParser parse: preprocessed.
	result := self buildFromAST: ast.
	(result isKindOf: Collection)
		ifTrue: [ result do: [ :n | n rawSource: aString ] ]
		ifFalse: [ result rawSource: aString ].
	^ result
]

{ #category : 'special forms' }
GDZealCompiler class >> compileFsmSystemFor: aName [
	"Backwards-compat: no bindings"
	^ self compileFsmSystemFor: aName withBindings: #()
]

{ #category : 'special forms' }
GDZealCompiler class >> compileFsmSystemFor: aName withBindings: bindings [
	"Generate the GDScript for a sibling system that ticks an FSM component each frame.
	 bindings is an OrderedCollection of {#name #type} dictionaries.
	 The system queries for [C_<Name>] plus all binding component types,
	 and calls fsm.tick(entity, delta, ...binding-components)."
	| pascalName allComponents |
	pascalName := '' join: ((aName substrings: '-') collect: [ :s | s capitalized ]).
	"Build the list of all components: the FSM itself + bindings"
	allComponents := OrderedCollection new.
	allComponents add: 'C_' , pascalName.
	bindings do: [ :b |
		| typeName |
		typeName := (b at: #type).
		(typeName beginsWith: '@') ifTrue: [ typeName := typeName allButFirst ].
		typeName := 'C_' , ('' join: ((typeName substrings: '-') collect: [ :s | s capitalized ])).
		allComponents add: typeName ].
	
	^ String streamContents: [ :s |
		| compList |
		compList := '[' , (', ' join: allComponents) , ']'.
		s nextPutAll: 'class_name '; nextPutAll: pascalName; nextPutAll: 'System'; lf.
		s nextPutAll: 'extends System'; lf; lf.
		s nextPutAll: 'func query() -> QueryBuilder:'; lf.
		s tab; nextPutAll: 'return q.with_all('; nextPutAll: compList; nextPutAll: ').iterate('; nextPutAll: compList; nextPutAll: ')'; lf; lf.
		s nextPutAll: 'func process(entities: Array[Entity], components: Array, delta: float) -> void:'; lf.
		s tab; nextPutAll: 'var fsm_arr = components[0]'; lf.
		bindings withIndexDo: [ :b :idx |
			s tab; nextPutAll: 'var '; nextPutAll: (b at: #name); nextPutAll: '_arr = components['; nextPutAll: idx asString; nextPutAll: ']'; lf ].
		s tab; nextPutAll: 'for _i in entities.size():'; lf.
		s tab; tab; nextPutAll: 'var entity = entities[_i]'; lf.
		s tab; tab; nextPutAll: 'var fsm = fsm_arr[_i]'; lf.
		"Build tick call with bindings"
		s tab; tab; nextPutAll: 'fsm.tick(entity, delta'.
		bindings do: [ :b |
			s nextPutAll: ', '; nextPutAll: (b at: #name); nextPutAll: '_arr[_i]' ].
		s nextPutAll: ')'; lf ]
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

{ #category : 'parsing' }
GDZealCompiler class >> defcosystemBindings: aSourceString [
	"Extract the bindings from a defcosystem source. Returns OrderedCollection of {#name #type}."
	| parsed first bodyForms third |
	[ parsed := ZealParser parse: aSourceString ] on: Error do: [ ^ #() ].
	parsed children isEmpty ifTrue: [ ^ #() ].
	first := parsed children first.
	(first isKindOf: ZealListNode) ifFalse: [ ^ #() ].
	first expressions size < 3 ifTrue: [ ^ #() ].
	bodyForms := first expressions allButFirst allButFirst.
	bodyForms isEmpty ifTrue: [ ^ #() ].
	third := bodyForms first.
	(third isKindOf: ZealVectorNode) ifFalse: [ ^ #() ].
	^ self parseFsmBindings: third
]

{ #category : 'parsing' }
GDZealCompiler class >> defcosystemName: aSourceString [
	"Extract the name from a defcosystem source. Returns kebab-case name or nil."
	| parsed first |
	[ parsed := ZealParser parse: aSourceString ] on: Error do: [ ^ nil ].
	parsed children isEmpty ifTrue: [ ^ nil ].
	first := parsed children first.
	(first isKindOf: ZealListNode) ifFalse: [ ^ nil ].
	first expressions size < 2 ifTrue: [ ^ nil ].
	^ first expressions second value value
]

{ #category : 'fsm' }
GDZealCompiler class >> errorPlaceholderFor: aTag [
	"Build a synthetic AST node that prints to GDScript as a runtime push_error call,
	 so coroutine misuse surfaces visibly at runtime instead of silently miscompiling."
	| placeholder |
	placeholder := ZealListNode new.
	placeholder expressions: { 
		(self newSymbolNodeWithString: 'push_error').
		(self newSymbolNodeWithString: '"GDZeal: ' , aTag , '"') }.
	^ placeholder
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmContainsWait: aForm [
	"True if aForm is a (wait) call or contains one anywhere"
	(aForm isKindOf: ZealListNode) ifFalse: [ ^ false ].
	aForm expressions isEmpty ifTrue: [ ^ false ].
	((aForm expressions first isKindOf: ZealSymbolNode) and: [
		aForm expressions first value value = 'wait' ]) ifTrue: [ ^ true ].
	aForm expressions allButFirst do: [ :child |
		(self fsmContainsWait: child) ifTrue: [ ^ true ] ].
	^ false
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmEmitBranch: cond then: thenForm else: elseForm ctx: ctx [
	"Single-form then variant. Wraps in a list."
	self fsmEmitBranch: cond thenForms: { thenForm } else: elseForm ctx: ctx
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmEmitBranch: cond thenForms: thenForms else: elseForm ctx: ctx [
	"Emit a branch (if/when with waits inside).
	 Algorithm:
	   1. Mark current state as #branch with the condition; record then-start and else-start indices.
	   2. Allocate then-start state, walk then-forms there, mark its end state's #next = join.
	   3. If else exists: allocate else-start, walk else there, mark its end state's #next = join.
	      Otherwise the branch falls through directly to join when cond is false.
	   4. Allocate join state, set as #current.
	 The codegen for #branch state will emit:
	   if cond: _state = then_start
	   else:    _state = else_start (or join)"
	| current branchState states thenStart thenEndState elseStart elseEndState join |
	current := ctx at: #current.
	states := ctx at: #states.
	branchState := current.
	"Mark current state as a branch decision point"
	branchState at: #kind put: #branch.
	branchState at: #branchCond put: cond.
	
	"Allocate then-start state"
	thenStart := self fsmNewState.
	states add: thenStart.
	branchState at: #thenIndex put: states size - 1.
	"Walk then-forms into thenStart"
	ctx at: #current put: thenStart.
	self fsmWalk: thenForms ctx: ctx.
	thenEndState := ctx at: #current.
	
	"Else branch"
	elseForm ifNotNil: [
		elseStart := self fsmNewState.
		states add: elseStart.
		branchState at: #elseIndex put: states size - 1.
		ctx at: #current put: elseStart.
		self fsmWalk: { elseForm } ctx: ctx.
		elseEndState := ctx at: #current ].
	
	"Allocate join state"
	join := self fsmNewState.
	states add: join.
	branchState at: #joinIndex put: states size - 1.
	"If no else, the branch state's else jumps directly to join"
	elseForm ifNil: [ branchState at: #elseIndex put: states size - 1 ].
	
	"Wire end states to jump to join (only if their kind is still 'normal' — they didn't end with their own transition)"
	(thenEndState at: #kind) = #normal ifTrue: [
		thenEndState at: #next put: states size - 1.
		thenEndState at: #kind put: #joinJump ].
	elseEndState ifNotNil: [
		(elseEndState at: #kind) = #normal ifTrue: [
			elseEndState at: #next put: states size - 1.
			elseEndState at: #kind put: #joinJump ] ].
	
	"Continue from join state"
	ctx at: #current put: join
]

{ #category : 'fsm' }
GDZealCompiler class >> fsmExpandCoroutine: aListNode ctx: ctx [
	"Expand a coroutine call site by inlining its body into ctx with parameter substitution.
	 Cycle detection via stack-membership; depth limit as fail-safe.
	 Errors emit a runtime push_error stmt instead of raising — `self error:` was being
	 silently swallowed when invoked from inside the FSM walker pipeline (handler somewhere
	 was returning nil, causing infinite recursion through the failed cycle check)."
	| head co params body args bindings substitutedBody stack |
	head := aListNode expressions first value value.
	stack := ctx at: #coroutineStack.
	stack size > 64 ifTrue: [
		^ ((ctx at: #current) at: #stmts) 
			add: (self errorPlaceholderFor: 'depth_limit_exceeded') ].
	(stack includes: head) ifTrue: [
		^ ((ctx at: #current) at: #stmts) 
			add: (self errorPlaceholderFor: 'recursive_coroutine_' , head) ].
	co := (ctx at: #coroutines) at: head ifAbsent: [ ^ self ].
	params := co at: #params.
	body := co at: #body.
	args := aListNode expressions allButFirst.
	args size = params size ifFalse: [
		^ ((ctx at: #current) at: #stmts) 
			add: (self errorPlaceholderFor: 'arity_mismatch_' , head) ].
	bindings := Dictionary new.
	params with: args do: [ :p :a | bindings at: p put: a ].
	substitutedBody := body collect: [ :form | self substituteSymbolsIn: form bindings: bindings ].
	stack add: head.
	[ self fsmWalk: substitutedBody ctx: ctx ]
		ensure: [ stack removeLast ]
]

{ #category : 'fsm' }
GDZealCompiler class >> fsmHandleConcurrent: aListNode ctx: ctx kind: kindSym [
	"Handle (sync ...) or (race ...).
	 Each branch becomes its own lane (sub-FSM with its own state space and per-lane fields).
	 The current state becomes a controller state of kind #sync or #race that ticks all lanes
	 each frame and advances when (sync: all done) / (race: any done).
	 Lane states do NOT use #terminal — they advance past the end to a sentinel index so any
	 final stmts run exactly once instead of repeating every tick."
	| branches lanes parentStates parentCurrent controllerState nextState |
	branches := aListNode expressions allButFirst.
	parentStates := ctx at: #states.
	parentCurrent := ctx at: #current.
	lanes := OrderedCollection new.
	branches do: [ :branch |
		| laneId laneStates laneStart laneFinal |
		laneId := ctx at: #nextLaneId.
		ctx at: #nextLaneId put: laneId + 1.
		laneStates := OrderedCollection new.
		laneStart := self fsmNewState.
		laneStates add: laneStart.
		ctx at: #states put: laneStates.
		ctx at: #current put: laneStart.
		((branch isKindOf: ZealListNode) and: [
			branch expressions first value value = 'do' ]) 
				ifTrue: [ self fsmWalk: branch expressions allButFirst ctx: ctx ]
				ifFalse: [ self fsmWalk: { branch } ctx: ctx ].
		"Lane final state stays #normal — defaults to next=size, falling through to sentinel.
		 Loops keep their #loopEnd kind so they cycle forever."
		laneFinal := ctx at: #current.
		lanes add: (Dictionary new
			at: #laneId put: laneId;
			at: #states put: laneStates;
			yourself) ].
	ctx at: #states put: parentStates.
	ctx at: #current put: parentCurrent.
	controllerState := parentCurrent.
	controllerState at: #kind put: kindSym.
	controllerState at: #lanes put: lanes.
	(ctx at: #lanes) addAll: lanes.
	"Allocate fall-through state for after the controller completes"
	nextState := self fsmNewState.
	parentStates add: nextState.
	ctx at: #current put: nextState
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmHandleIf: aListNode ctx: ctx [
	"Handle (if cond then) or (if cond then else).
	 If neither branch contains a wait, emit inline as a regular statement.
	 Otherwise, split into branch states with then/else/join."
	| exprs cond thenForm elseForm hasWait |
	exprs := aListNode expressions.
	cond := exprs second.
	thenForm := exprs third.
	elseForm := exprs size > 3 ifTrue: [ exprs fourth ] ifFalse: [ nil ].
	
	hasWait := (self fsmContainsWait: thenForm) or: [
		elseForm notNil and: [ self fsmContainsWait: elseForm ] ].
	
	hasWait ifFalse: [
		"No waits inside — emit as regular statement"
		((ctx at: #current) at: #stmts) add: aListNode.
		^ self ].
	
	"Has waits — split into branch states"
	self fsmEmitBranch: cond then: thenForm else: elseForm ctx: ctx
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmHandleLoop: aListNode ctx: ctx [
	"Handle (loop body...).
	 Walk the body, then make the current state's #next point back to the loop's first state."
	| loopStart bodyForms current |
	"loopStart = index of the current state (0-based)"
	loopStart := (ctx at: #states) size - 1.
	bodyForms := aListNode expressions allButFirst.
	self fsmWalk: bodyForms ctx: ctx.
	current := ctx at: #current.
	current at: #next put: loopStart.
	current at: #kind put: #loopEnd
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmHandleWait: aListNode ctx: ctx [
	"Handle (wait) or (wait n).
	 (wait) — finalize current state as #waitFrame, start new state.
	 (wait n) — finalize current state as #waitTime with duration n, start new state."
	| current newState exprs |
	current := ctx at: #current.
	exprs := aListNode expressions.
	exprs size = 1 ifTrue: [
		current at: #kind put: #waitFrame ]
	ifFalse: [
		current at: #kind put: #waitTime.
		current at: #waitDuration put: exprs second ].
	newState := self fsmNewState.
	(ctx at: #states) add: newState.
	ctx at: #current put: newState
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmHandleWhen: aListNode ctx: ctx [
	"Handle (when cond body...). Equivalent to (if cond (do body...)).
	 If body has no waits, emit inline."
	| exprs cond bodyForms hasWait |
	exprs := aListNode expressions.
	cond := exprs second.
	bodyForms := exprs allButFirst allButFirst.
	
	hasWait := bodyForms anySatisfy: [ :f | self fsmContainsWait: f ].
	
	hasWait ifFalse: [
		((ctx at: #current) at: #stmts) add: aListNode.
		^ self ].
	
	"Has waits — split. The 'then' is a sequence of forms (no else)."
	self fsmEmitBranch: cond thenForms: bodyForms else: nil ctx: ctx
]

{ #category : 'special forms' }
GDZealCompiler class >> fsmNewState [
	"Create a new empty state dictionary.
	 #stmts — OrderedCollection of statements to emit
	 #kind — #normal, #waitFrame, #waitTime, #terminal, #loopEnd
	 #waitDuration — for #waitTime states (a parse node)
	 #next — explicit next state index (nil = state index + 1)"
	^ Dictionary new
		at: #stmts put: OrderedCollection new;
		at: #kind put: #normal;
		at: #waitDuration put: nil;
		at: #next put: nil;
		yourself
]

{ #category : 'fsm' }
GDZealCompiler class >> fsmSplitBody: bodyForms [
	"Backwards-compat shim — uses an empty coroutine dict."
	^ self fsmSplitBody: bodyForms coroutines: nil
]

{ #category : 'fsm' }
GDZealCompiler class >> fsmSplitBody: bodyForms coroutines: aDict [
	"Split a sequence of forms into states with coroutine expansion support."
	| states currentState ctx current |
	states := OrderedCollection new.
	currentState := self fsmNewState.
	states add: currentState.
	ctx := Dictionary new.
	ctx at: #states put: states.
	ctx at: #current put: currentState.
	ctx at: #nextLaneId put: 0.
	ctx at: #lanes put: OrderedCollection new.
	ctx at: #coroutines put: (aDict ifNil: [ Dictionary new ]).
	ctx at: #coroutineStack put: OrderedCollection new.
	self fsmWalk: bodyForms ctx: ctx.
	current := ctx at: #current.
	(current at: #kind) = #normal ifTrue: [
		current at: #kind put: #terminal ].
	^ ctx
]

{ #category : 'fsm' }
GDZealCompiler class >> fsmWalk: forms ctx: ctx [
	"Walk forms, dispatching to handlers for special FSM forms or to coroutine expansion."
	forms do: [ :form |
		(form isKindOf: ZealListNode) ifTrue: [
			| head co |
			head := form expressions first value value.
			head = 'wait' ifTrue: [ self fsmHandleWait: form ctx: ctx ]
			ifFalse: [
			head = 'loop' ifTrue: [ self fsmHandleLoop: form ctx: ctx ]
			ifFalse: [
			head = 'if' ifTrue: [ self fsmHandleIf: form ctx: ctx ]
			ifFalse: [
			head = 'when' ifTrue: [ self fsmHandleWhen: form ctx: ctx ]
			ifFalse: [
			head = 'sync' ifTrue: [ self fsmHandleConcurrent: form ctx: ctx kind: #sync ]
			ifFalse: [
			head = 'race' ifTrue: [ self fsmHandleConcurrent: form ctx: ctx kind: #race ]
			ifFalse: [
			head = 'do' ifTrue: [
				self fsmWalk: form expressions allButFirst ctx: ctx ]
			ifFalse: [
			"Coroutine call?"
			co := (ctx at: #coroutines) at: head ifAbsent: [ nil ].
			co notNil 
				ifTrue: [ self fsmExpandCoroutine: form ctx: ctx ]
				ifFalse: [
					"Regular form — emit into current state"
					((ctx at: #current) at: #stmts) add: form ] ] ] ] ] ] ] ] ]
		ifFalse: [
			((ctx at: #current) at: #stmts) add: form ] ]
]

{ #category : 'special forms' }
GDZealCompiler class >> inferTypeFromLiteral: aNode [
	"Infer GDScript type from a literal or symbol value"
	| val |
	(aNode isKindOf: ZealSymbolRef) ifTrue: [
		(#('true' 'false') includes: aNode name) ifTrue: [ ^ 'bool' ].
		^ nil ].
	(aNode isKindOf: ZealLiteral) ifFalse: [ ^ nil ].
	val := aNode value asString.
	(val includes: $.) ifTrue: [ ^ 'float' ].
	(val allSatisfy: [:c | c isDigit or: [ c = $- ]]) ifTrue: [ ^ 'int' ].
	((val beginsWith: '"') or: [ val beginsWith: '''' ]) ifTrue: [ ^ 'String' ].
	^ nil
]

{ #category : 'special forms' }
GDZealCompiler class >> inferTypeFromValue: aParseNode [
	"Infer type from a raw parse node value.
	 10.0 → float, 42 → int, true → bool, @vector2/RIGHT → @vector2"
	| val |
	val := aParseNode value value.
	"@class reference — type is the class"
	(val beginsWith: '@') ifTrue: [
		(val includes: $/) 
			ifTrue: [ ^ '@', (val allButFirst copyUpTo: $/) ]
			ifFalse: [ ^ val ] ].
	"Boolean"
	(#('true' 'false') includes: val) ifTrue: [ ^ 'bool' ].
	"Float literal"
	(aParseNode isKindOf: ZealFloatLiteralNode) ifTrue: [ ^ 'float' ].
	"Integer literal"  
	(aParseNode isKindOf: ZealIntegerLiteralNode) ifTrue: [ ^ 'int' ].
	"Number with dot"
	(val includes: $.) ifTrue: [ ^ 'float' ].
	"All digits"
	(val allSatisfy: [:c | c isDigit or: [ c = $- ]]) ifTrue: [ ^ 'int' ].
	"String"
	((val beginsWith: '"') or: [ val beginsWith: '''' ]) ifTrue: [ ^ 'String' ].
	^ nil
]

{ #category : 'parsing' }
GDZealCompiler class >> isDefcosystem: aSourceString [
	"Check if a source string is a defcosystem form"
	| parsed first |
	[ parsed := ZealParser parse: aSourceString ] on: Error do: [ ^ false ].
	parsed children isEmpty ifTrue: [ ^ false ].
	first := parsed children first.
	(first isKindOf: ZealListNode) ifFalse: [ ^ false ].
	first expressions isEmpty ifTrue: [ ^ false ].
	^ first expressions first value value = 'defcosystem'
]

{ #category : 'fsm-coroutines' }
GDZealCompiler class >> newSymbolNodeWithString: aString [
	"Construct a fresh ZealSymbolNode whose value is a fake token responding to #value
	 with aString. Used by symbol substitution during coroutine inlining."
	| token |
	token := Association new value: aString; yourself.
	^ ZealSymbolNode new value: token; yourself
]

{ #category : 'special forms' }
GDZealCompiler class >> parseFsmBindings: aVectorNode [
	"Parse a binding vector like [vel:@velocity health:@health] into 
	 an OrderedCollection of {#name: 'vel', #type: '@velocity'} dictionaries.
	 Bare @type forms get the type name as the binding name."
	| bindings |
	bindings := OrderedCollection new.
	aVectorNode expressions do: [ :item |
		(item isKindOf: ZealColonChainNode) ifTrue: [
			| resolved |
			resolved := self resolveNameNode: item.
			bindings add: (Dictionary new
				at: #name put: (resolved at: #name);
				at: #type put: (((resolved at: #annotations) ifNotEmpty: [ :anns |
					anns detect: [ :a | a beginsWith: '@' ] ifNone: [ resolved at: #type ] ])
					ifNil: [ resolved at: #type ]);
				yourself) ]
		ifFalse: [
			"Bare @type — use the type name (without @) as the binding name"
			| typeStr bindingName |
			typeStr := item value value.
			bindingName := (typeStr beginsWith: '@') 
				ifTrue: [ typeStr allButFirst ]
				ifFalse: [ typeStr ].
			bindings add: (Dictionary new
				at: #name put: bindingName;
				at: #type put: typeStr;
				yourself) ] ].
	^ bindings
]

{ #category : 'helpers' }
GDZealCompiler class >> resolveNameNode: aNode [
	^ ZealCompiler resolveNameNode: aNode
]

{ #category : 'building' }
GDZealCompiler class >> specialFormBuilders [
	"Only GDZeal-specific forms. Shared forms delegate to ZealCompiler."
	^ Dictionary new
		at: 'defcomp' put: #buildDefcomp:;
		at: 'defcosystem' put: #buildDefcosystem:;
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

{ #category : 'fsm-coroutines' }
GDZealCompiler class >> substituteSymbolsIn: aNode bindings: aDict [
	"Walk an AST node, substituting symbol references whose name (or slash prefix) matches
	 a key in aDict. Returns either the original node (if no substitution needed) or a new
	 node tree with structural sharing.
	 Args must be ZealSymbolNode (plain or slash-chain). Complex expressions not supported."
	aDict isEmpty ifTrue: [ ^ aNode ].
	
	"ZealSymbolNode: check for substitution"
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		| sym replacement |
		sym := aNode value value.
		replacement := self substitutedSymbolString: sym bindings: aDict.
		replacement = sym ifTrue: [ ^ aNode ].
		^ self newSymbolNodeWithString: replacement ].
	
	"ZealListNode: recurse into expressions"
	(aNode isKindOf: ZealListNode) ifTrue: [
		| newExprs changed |
		changed := false.
		newExprs := aNode expressions collect: [ :child |
			| newChild |
			newChild := self substituteSymbolsIn: child bindings: aDict.
			newChild ~~ child ifTrue: [ changed := true ].
			newChild ].
		changed ifFalse: [ ^ aNode ].
		^ ZealListNode new expressions: newExprs; yourself ].
	
	"ZealVectorNode: same recursion as ListNode"
	(aNode isKindOf: ZealVectorNode) ifTrue: [
		| newExprs changed |
		changed := false.
		newExprs := aNode expressions collect: [ :child |
			| newChild |
			newChild := self substituteSymbolsIn: child bindings: aDict.
			newChild ~~ child ifTrue: [ changed := true ].
			newChild ].
		changed ifFalse: [ ^ aNode ].
		^ ZealVectorNode new expressions: newExprs; yourself ].
	
	"Other atom types pass through unchanged"
	^ aNode
]

{ #category : 'fsm-coroutines' }
GDZealCompiler class >> substitutedSymbolString: sym bindings: aDict [
	"If sym matches a binding key (exactly, or as a slash-prefix), return substituted string.
	 Otherwise return sym unchanged.
	 paramName 'pos', arg symbol 'position':
	   'pos' -> 'position'
	   'pos/x' -> 'position/x'
	   'other' -> 'other' (unchanged)"
	aDict keysDo: [ :paramName |
		| argSym |
		sym = paramName ifTrue: [
			^ (aDict at: paramName) value value ].
		(sym beginsWith: paramName , '/') ifTrue: [
			argSym := (aDict at: paramName) value value.
			^ argSym , (sym copyFrom: paramName size + 1 to: sym size) ] ].
	^ sym
]
