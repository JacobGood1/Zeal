Class {
	#name : 'GDZealCodeGenerator',
	#superclass : 'ZealCodeGenerator',
	#instVars : [
		'registry',
		'currentBindings',
		'currentStateVar',
		'currentTimerVar'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
GDZealCodeGenerator class >> compile: aString [
	"Compile GDZeal source to GDScript string"
	^ self new generate: (ZealParser parse: aString)
]

{ #category : 'compiling' }
GDZealCodeGenerator class >> compile: aString withRegistry: aRegistry [
	"Compile GDZeal source with a shared component registry"
	| gen |
	gen := self new.
	gen setRegistry: aRegistry.
	^ gen generate: (ZealParser parse: aString)
]

{ #category : 'emitting' }
GDZealCodeGenerator >> dedent [
	indentLevel := indentLevel - 1
]

{ #category : 'emitting' }
GDZealCodeGenerator >> emit: aString [
	stream nextPutAll: aString
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitDefineComponents: aListNode [
	"(components [@health @velocity]) -> func define_components() -> Array: return [C_Health.new(), ...]"
	| compVector |
	compVector := aListNode expressions second.
	self emit: 'func define_components() -> Array:'.
	self indent. self nl.
	self emit: 'return ['.
	compVector expressions
		do: [ :c |
			self emit: (self resolveClassRef: c value value).
			self emit: '.new()' ]
		separatedBy: [ self emit: ', ' ].
	self emit: ']'.
	self dedent
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitEntityHook: hookName body: bodyExprs [
	"Emit an entity lifecycle hook: func on_ready() -> void: body"
	self emit: 'func '.
	self emit: hookName.
	self emit: '() -> void:'.
	bodyExprs isEmpty ifTrue: [
		self indent. self nl. self emit: 'pass'. self dedent ]
	ifFalse: [
		self indent.
		bodyExprs do: [ :e | self nl. self visitExpression: e ].
		self dedent ]
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitExport: aListNode [
	"(export name:type default) -> @export var name: type = default"
	| exprs nameNode resolved |
	exprs := aListNode expressions.
	nameNode := exprs second.
	self emit: '@export var '.
	resolved := self resolveColonChain: nameNode value value.
	self emit: (self toSnakeCase: (resolved at: #name)).
	(resolved at: #type) ifNotNil: [ :t |
		self emit: ': '.
		self emit: (self resolveType: t) ].
	exprs size > 2 ifTrue: [
		self emit: ' = '.
		self visitExpression: exprs third ]
]

{ #category : 'codegen-fsm' }
GDZealCodeGenerator >> emitFsmState: state index: i totalStates: total [
	"Emit the body of one match arm. Assumes we're already at the right indent.
	 Uses currentStateVar / currentTimerVar so the same emitter works for the main FSM
	 and for inlined lane bodies inside sync/race controllers.
	 Kinds:
	   normal/waitFrame/loopEnd/joinJump: emit stmts, <state> = next
	   waitTime: stmts run once on entry (sentinel), then countdown
	   terminal: emit stmts, no advance (use pass if empty)
	   branch: emit if cond: <state> = then else: <state> = else
	   sync: tick ALL lanes each frame, advance when ALL done (and-join, no short-circuit)
	   race: tick lanes in order, SHORT-CIRCUIT — skip remaining lanes once one finishes.
	         Both perf win and a semantic fix: prevents tied-frame double-fire."
	| stmts kind nextIdx sv tv |
	stmts := state at: #stmts.
	kind := state at: #kind.
	nextIdx := (state at: #next) ifNil: [ i + 1 ].
	sv := currentStateVar.
	tv := currentTimerVar.
	
	"BRANCH"
	kind = #branch ifTrue: [
		stmts do: [ :stmt | self visitExpression: stmt. self nl ].
		self emit: 'if '. self visitExpression: (state at: #branchCond). self emit: ':'.
		self indent. self nl.
		self emit: sv , ' = '. self emit: (state at: #thenIndex) asString.
		self dedent. self nl.
		self emit: 'else:'.
		self indent. self nl.
		self emit: sv , ' = '. self emit: (state at: #elseIndex) asString.
		self dedent.
		^ self ].
	
	"WAIT-TIME"
	kind = #waitTime ifTrue: [
		self emit: 'if ' , tv , ' <= 0.0:'.
		self indent. self nl.
		stmts do: [ :stmt | self visitExpression: stmt. self nl ].
		self emit: tv , ' = '. self visitExpression: (state at: #waitDuration).
		self dedent. self nl.
		self emit: tv , ' -= delta'. self nl.
		self emit: 'if ' , tv , ' <= 0.0:'.
		self indent. self nl.
		self emit: sv , ' = '. self emit: nextIdx asString.
		self dedent.
		^ self ].
	
	"SYNC controller — inlined lanes, no short-circuit (need ALL to finish)"
	kind = #sync ifTrue: [
		| lanes |
		lanes := state at: #lanes.
		lanes do: [ :lane | self emitInlineLane: lane ].
		self emit: 'if '.
		lanes withIndexDo: [ :lane :idx |
			idx > 1 ifTrue: [ self emit: ' and ' ].
			self emit: 'd_l' , (lane at: #laneId) asString ].
		self emit: ':'.
		self indent. self nl.
		self emitLaneResetBlock: lanes advanceVar: sv toIndex: nextIdx.
		self dedent.
		^ self ].
	
	"RACE controller — short-circuit: stop ticking lanes after the first one finishes.
	 Generates a flag-based flat structure that scales linearly with lane count."
	kind = #race ifTrue: [
		| lanes |
		lanes := state at: #lanes.
		self emit: 'var _won = false'. self nl.
		lanes do: [ :lane |
			| pfx savedSv savedTv laneStates sentinelIdx |
			pfx := '_l' , (lane at: #laneId) asString.
			laneStates := lane at: #states.
			sentinelIdx := laneStates size.
			self emit: 'if not _won:'.
			self indent. self nl.
			savedSv := currentStateVar.
			savedTv := currentTimerVar.
			currentStateVar := pfx , '_state'.
			currentTimerVar := pfx , '_timer'.
			laneStates withIndexDo: [ :st :j |
				j = 1
					ifTrue: [ self emit: 'if ' , currentStateVar , ' == 0:' ]
					ifFalse: [ self emit: 'elif ' , currentStateVar , ' == ' , (j - 1) asString , ':' ].
				self indent. self nl.
				self emitFsmState: st index: j - 1 totalStates: laneStates size.
				self dedent.
				self nl ].
			currentStateVar := savedSv.
			currentTimerVar := savedTv.
			self emit: 'if ' , pfx , '_state >= ' , sentinelIdx asString , ':'.
			self indent. self nl.
			self emit: '_won = true'.
			self dedent.
			self dedent. self nl ].
		self emit: 'if _won:'.
		self indent. self nl.
		self emitLaneResetBlock: lanes advanceVar: sv toIndex: nextIdx.
		self dedent.
		^ self ].
	
	"TERMINAL"
	kind = #terminal ifTrue: [
		stmts isEmpty 
			ifTrue: [ self emit: 'pass' ]
			ifFalse: [ stmts withIndexDo: [ :stmt :idx |
				idx > 1 ifTrue: [ self nl ].
				self visitExpression: stmt ] ].
		^ self ].
	
	"NORMAL/WAITFRAME/LOOPEND/JOINJUMP"
	stmts withIndexDo: [ :stmt :idx |
		self visitExpression: stmt.
		self nl ].
	self emit: sv , ' = '. self emit: nextIdx asString
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> emitIfChain: args first: isFirst [
	"Recursive if/elif/else chain emission"
	| keyword |
	args isEmpty ifTrue: [ ^ self ].
	keyword := isFirst ifTrue: [ 'if ' ] ifFalse: [ 'elif ' ].
	"Single expression remaining = else body"
	args size = 1 ifTrue: [
		self emit: 'else:'.
		self indent. self nl. self visitExpression: args first. self dedent.
		^ self ].
	"Condition + body + rest"
	self emit: keyword.
	self visitExpression: args first.
	self emit: ':'.
	self indent. self nl. self visitExpression: args second. self dedent.
	args size > 2 ifTrue: [
		self nl.
		self emitIfChain: (args copyFrom: 3 to: args size) first: false ]
]

{ #category : 'emitting' }
GDZealCodeGenerator >> emitIndent [
	indentLevel timesRepeat: [ stream nextPut: Character tab ]
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitInit: aListNode [
	"(init [param:type default ...] body) -> func _init(param: type = default):
	 Parameters are paired: [name:type defaultVal name2:type2 defaultVal2]"
	| exprs paramsVec bodyExprs items pairs i |
	exprs := aListNode expressions.
	paramsVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	items := paramsVec expressions.
	"Pair up params: colonChain + default value"
	pairs := OrderedCollection new.
	i := 1.
	[ i <= items size ] whileTrue: [
		| nameNode |
		nameNode := items at: i.
		(nameNode isKindOf: ZealColonChainNode)
			ifTrue: [
				(i + 1 <= items size)
					ifTrue: [ pairs add: { nameNode. items at: i + 1 }. i := i + 2 ]
					ifFalse: [ pairs add: { nameNode. nil }. i := i + 1 ] ]
			ifFalse: [ i := i + 1 ] ].
	self emit: 'func _init('.
	pairs
		do: [ :pair |
			| resolved |
			resolved := self resolveColonChain: pair first value value.
			self emit: (self toSnakeCase: (resolved at: #name)).
			(resolved at: #type) ifNotNil: [ :t |
				self emit: ': '.
				self emit: (self resolveType: t) ].
			pair second ifNotNil: [ :def |
				self emit: ' = '.
				self visitExpression: def ] ]
		separatedBy: [ self emit: ', ' ].
	self emit: '):'.
	self indent.
	bodyExprs do: [ :e | self nl. self visitExpression: e ].
	self dedent
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitInitParam: aNode [
	"Emit _init parameter with default value.
	 Colon chains: name:type is emitted, and next sibling in the vector provides default.
	 For _init, all params must have defaults, so we pair name:type + default."
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: aNode value value.
		self emit: (self toSnakeCase: (resolved at: #name)).
		(resolved at: #type) ifNotNil: [ :t |
			self emit: ': '.
			self emit: (self resolveType: t) ].
		^ self ].
	"Plain value (used as default in paired parsing)"
	self visitExpression: aNode
]

{ #category : 'codegen-fsm' }
GDZealCodeGenerator >> emitInlineLane: lane [
	"Emit one lane's state machine inline (no helper function), followed by its done flag.
	 Used by sync controllers — race needs custom code with the won-flag short-circuit
	 so it doesn't use this helper."
	| pfx laneStates savedSv savedTv sentinelIdx |
	pfx := '_l' , (lane at: #laneId) asString.
	laneStates := lane at: #states.
	savedSv := currentStateVar.
	savedTv := currentTimerVar.
	currentStateVar := pfx , '_state'.
	currentTimerVar := pfx , '_timer'.
	sentinelIdx := laneStates size.
	laneStates withIndexDo: [ :st :j |
		j = 1
			ifTrue: [ self emit: 'if ' , currentStateVar , ' == 0:' ]
			ifFalse: [ self emit: 'elif ' , currentStateVar , ' == ' , (j - 1) asString , ':' ].
		self indent. self nl.
		self emitFsmState: st index: j - 1 totalStates: laneStates size.
		self dedent.
		self nl ].
	self emit: 'var d' , pfx , ' = ' , currentStateVar , ' >= ' , sentinelIdx asString.
	self nl.
	currentStateVar := savedSv.
	currentTimerVar := savedTv
]

{ #category : 'codegen-fsm' }
GDZealCodeGenerator >> emitLaneHelper: lane [
	"Emit a func _tick_lN(delta, <bindings>) -> bool helper for one lane.
	 Returns true when _state has advanced past the last real state (sentinel = laneStates size)."
	| pfx laneStates savedSv savedTv sentinelIdx |
	pfx := '_l' , (lane at: #laneId) asString.
	laneStates := lane at: #states.
	savedSv := currentStateVar.
	savedTv := currentTimerVar.
	currentStateVar := pfx , '_state'.
	currentTimerVar := pfx , '_timer'.
	sentinelIdx := laneStates size.
	
	self nl.
	self emit: 'func _tick' , pfx , '(delta: float'.
	currentBindings do: [ :b |
		self emit: ', '.
		self emit: (b at: #name).
		self emit: ': '.
		self emit: (self resolveType: (b at: #type)) ].
	self emit: ') -> bool:'.
	self indent. self nl.
	self emit: 'match ' , currentStateVar , ':'.
	self indent. self nl.
	laneStates withIndexDo: [ :state :i |
		self emit: (i - 1) asString. self emit: ':'.
		self indent. self nl.
		self emitFsmState: state index: i - 1 totalStates: laneStates size.
		self dedent.
		i < laneStates size ifTrue: [ self nl ] ].
	self dedent. self nl.
	self emit: 'return ' , currentStateVar , ' >= ' , sentinelIdx asString.
	self dedent.
	
	currentStateVar := savedSv.
	currentTimerVar := savedTv
]

{ #category : 'codegen-fsm' }
GDZealCodeGenerator >> emitLaneResetBlock: lanes advanceVar: sv toIndex: nextIdx [
	"Reset all lanes to state 0 / timer 0, then advance the controller's state var.
	 Shared by sync (after the and-join fires) and race (after the won flag fires)."
	lanes do: [ :lane |
		| pfx |
		pfx := '_l' , (lane at: #laneId) asString.
		self emit: pfx , '_state = 0'. self nl.
		self emit: pfx , '_timer = 0.0'. self nl ].
	self emit: sv , ' = '. self emit: nextIdx asString
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitObserverHandler: methodName params: gdParams form: aListNode [
	"Emit observer handler. Maps user param names to GDScript typed params."
	| exprs userParams bodyExprs |
	exprs := aListNode expressions.
	userParams := exprs second expressions collect: [ :p | p value value ].
	bodyExprs := exprs allButFirst allButFirst.
	self emit: 'func '.
	self emit: methodName.
	self emit: '('.
	"Use GDScript param types, but user-chosen names"
	gdParams withIndexCollect: [ :gdp :i |
		| parts userName |
		parts := ': ' split: gdp.
		userName := i <= userParams size
			ifTrue: [ self toSnakeCase: (userParams at: i) ]
			ifFalse: [ parts first ].
		userName , ': ' , parts second ].
	(gdParams withIndexCollect: [ :gdp :i |
		| parts userName |
		parts := ': ' split: gdp.
		userName := i <= userParams size
			ifTrue: [ self toSnakeCase: (userParams at: i) ]
			ifFalse: [ parts first ].
		userName , ': ' , parts second ])
			do: [ :p | self emit: p ]
			separatedBy: [ self emit: ', ' ].
	self emit: ') -> void:'.
	bodyExprs isEmpty ifTrue: [
		self indent. self nl. self emit: 'pass'. self dedent ]
	ifFalse: [
		self indent.
		bodyExprs do: [ :e | self nl. self visitExpression: e ].
		self dedent ]
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitObserverMatch: aListNode [
	"(match (with-all [@health @player])) -> func match() -> QueryBuilder: return q.with_all([...])"
	| queryClauses |
	queryClauses := aListNode expressions allButFirst.
	self emit: 'func match() -> QueryBuilder:'.
	self indent. self nl.
	self emit: 'return q'.
	queryClauses do: [ :clause | self emitQueryClause: clause ].
	self dedent
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitObserverWatch: aListNode [
	"(watch @health) -> func watch() -> Resource: return C_Health"
	self emit: 'func watch() -> Resource:'.
	self indent. self nl.
	self emit: 'return '.
	self emit: (self resolveClassRef: aListNode expressions second value value).
	self dedent
]

{ #category : 'private - params' }
GDZealCodeGenerator >> emitParam: aNode [
	"Emit a function parameter. Colon chain -> typed, symbol -> untyped."
	| sym |
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: aNode value value.
		self emit: (self toSnakeCase: (resolved at: #name)).
		(resolved at: #type) ifNotNil: [ :t |
			self emit: ': '.
			self emit: (self resolveType: t) ].
		^ self ].
	sym := aNode value value.
	sym = '_' ifTrue: [ self emit: '_unused' ]
	ifFalse: [ self emit: (self toSnakeCase: sym) ]
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitQueryClause: aListNode [
	"(with-all [@a @b]) -> .with_all([C_A, C_B])
	 (with-any [@a]) -> .with_any([C_A])
	 (with-none [@a]) -> .with_none([C_A])
	 (iterate [@a @b]) -> .iterate([C_A, C_B])
	 (enabled) -> .enabled()
	 (disabled) -> .disabled()"
	| head args |
	head := aListNode expressions first value value.
	args := aListNode expressions allButFirst.
	self emit: '.'.
	self emit: (self toSnakeCase: head).
	self emit: '('.
	"If there's a vector argument, emit its contents as class refs"
	(args notEmpty and: [ args first isKindOf: ZealVectorNode ]) ifTrue: [
		self emit: '['.
		args first expressions
			do: [ :c | self emit: (self resolveClassRef: c value value) ]
			separatedBy: [ self emit: ', ' ].
		self emit: ']' ].
	self emit: ')'
]

{ #category : 'visiting - slash' }
GDZealCodeGenerator >> emitSlashAccess: segments [
	"Emit chained slash access: a/b/c -> a.b.c, a/@type/b -> (a as Type).b, a/0 -> a[0]"
	| result first |
	first := segments first.
	(first beginsWith: '@')
		ifTrue: [ result := self resolveClassRef: first ]
		ifFalse: [ result := self toSnakeCase: first ].
	segments allButFirst do: [ :seg |
		(seg beginsWith: '@') ifTrue: [
			"Cast: (prev as Type)"
			result := '(' , result , ' as ' , (self resolveClassRef: seg) , ')' ]
		ifFalse: [
			(seg notEmpty and: [ seg first isDigit ]) ifTrue: [
				"Array index"
				result := result , '[' , seg , ']' ]
			ifFalse: [
				"Property access"
				result := result , '.' , (self toSnakeCase: seg) ] ] ].
	self emit: result
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitSystemDeps: aListNode [
	"(deps {:after [@physics-system] :before [@ui-system]})
	 -> func deps() -> Dictionary: return {Runs.After: [...], Runs.Before: [...]}"
	| mapNode |
	mapNode := aListNode expressions second.
	self emit: 'func deps() -> Dictionary:'.
	self indent. self nl.
	self emit: 'return {'.
	mapNode pairs
		do: [ :pair |
			| key |
			key := pair key value value allButFirst. "strip :"
			self emit: 'Runs.'.
			self emit: (self toPascalCase: key).
			self emit: ': '.
			self visitVector: pair value ]
		separatedBy: [ self emit: ', ' ].
	self emit: '}'.
	self dedent
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitSystemProcess: aListNode [
	"(process [entities _ delta] body...) -> func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	 _ in any position adds the GDScript _ prefix for unused params"
	| exprs paramsVec bodyExprs paramNames p1 p2 p3 |
	exprs := aListNode expressions.
	paramsVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	paramNames := paramsVec expressions collect: [ :p | p value value ].
	p1 := paramNames first.
	p2 := paramNames second.
	p3 := paramNames third.
	self emit: 'func process('.
	"First param: entities"
	p1 = '_'
		ifTrue: [ self emit: '_entities' ]
		ifFalse: [ self emit: (self toSnakeCase: p1) ].
	self emit: ': Array[Entity], '.
	"Second param: components"
	p2 = '_'
		ifTrue: [ self emit: '_components' ]
		ifFalse: [ self emit: (self toSnakeCase: p2) ].
	self emit: ': Array, '.
	"Third param: delta"
	p3 = '_'
		ifTrue: [ self emit: '_delta' ]
		ifFalse: [ self emit: (self toSnakeCase: p3) ].
	self emit: ': float) -> void:'.
	self indent.
	bodyExprs do: [ :e | self nl. self visitExpression: e ].
	self dedent
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitSystemQuery: aListNode [
	"(query (with-all [@velocity]) (iterate [@velocity])) -> func query() -> QueryBuilder: return q.with_all([...]).iterate([...])"
	| queryClauses |
	queryClauses := aListNode expressions allButFirst.
	self emit: 'func query() -> QueryBuilder:'.
	self indent. self nl.
	self emit: 'return q'.
	queryClauses do: [ :clause |
		self emitQueryClause: clause ].
	self dedent
]

{ #category : 'generating - GECS helpers' }
GDZealCodeGenerator >> emitSystemSetup: aListNode [
	"(setup body...) -> func setup() -> void: body"
	| bodyExprs |
	bodyExprs := aListNode expressions allButFirst.
	self emit: 'func setup() -> void:'.
	bodyExprs isEmpty ifTrue: [
		self indent. self nl. self emit: 'pass'. self dedent ]
	ifFalse: [
		self indent.
		bodyExprs do: [ :e | self nl. self visitExpression: e ].
		self dedent ]
]

{ #category : 'generating' }
GDZealCodeGenerator >> generate: aZealProgramNode [
	"Main entry point: walk all top-level expressions"
	aZealProgramNode expressions
		do: [ :expr | self visitExpression: expr ]
		separatedBy: [ self nl. self nl ].
	^ self output
]

{ #category : 'generating - expressions' }
GDZealCodeGenerator >> generateAs: aListNode [
	"(as expr @type) -> (expr as Type)
	 (as expr @type field) -> (expr as Type).field
	 (as expr @type field1 field2) -> (expr as Type).field1.field2"
	| exprs |
	exprs := aListNode expressions.
	self emit: '('.
	self visitExpression: exprs second.
	self emit: ' as '.
	self visitExpression: exprs third.
	self emit: ')'.
	"Optional property chain after cast"
	exprs size > 3 ifTrue: [
		4 to: exprs size do: [ :i |
			| seg |
			seg := (exprs at: i) value value.
			(seg notEmpty and: [ seg first isDigit ])
				ifTrue: [ self emit: '[' , seg , ']' ]
				ifFalse: [ self emit: '.' , (self toSnakeCase: seg) ] ] ]
]

{ #category : 'generating - definitions' }
GDZealCodeGenerator >> generateDef: aListNode [
	"(def name:type value) -> const name: type = value"
	| exprs nameNode valueNode |
	exprs := aListNode expressions.
	nameNode := exprs second.
	valueNode := exprs third.
	self emit: 'const '.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: nameNode value value.
		self emit: (self toSnakeCase: (resolved at: #name)).
		self emit: ': '.
		self emit: (self resolveType: (resolved at: #type)).
		self emit: ' = '.
		self visitExpression: valueNode ]
	ifFalse: [
		self emit: (self toSnakeCase: nameNode value value).
		self emit: ' = '.
		self visitExpression: valueNode ]
]

{ #category : 'generators' }
GDZealCodeGenerator >> generateDefcomp: aListNode [
	"(defcomp name var1 val1 var2 val2 ... (init [...] body))
	 Fields are pairs: variable on left, value on right.
	 Tag: (defcomp dead)"
	| exprs name bodyForms i |
	exprs := aListNode expressions.
	name := exprs second value value.
	registry register: name.
	bodyForms := exprs allButFirst allButFirst.
	"Emit class header"
	self emit: 'class_name C_'.
	self emit: (self toPascalCase: name).
	self nl.
	self emit: 'extends Component'.
	bodyForms isEmpty ifTrue: [ ^ self ].
	self nl.
	"Process body"
	i := 1.
	[ i <= bodyForms size ] whileTrue: [
		| item |
		item := bodyForms at: i.
		(item isKindOf: ZealListNode) ifTrue: [
			| head |
			head := item expressions first value value.
			head = 'export' ifTrue: [ self nl. self emitExport: item ].
			head = 'init' ifTrue: [ self nl. self nl. self emitInit: item ] ]
		ifFalse: [
			| fieldName fieldType |
			self nl.
			(item isKindOf: ZealColonChainNode) ifTrue: [
				| resolved |
				resolved := self resolveColonChain: item value value.
				fieldName := resolved at: #name.
				fieldType := resolved at: #type ]
			ifFalse: [
				fieldName := item value value.
				fieldType := nil ].
			self emit: '@export var '.
			self emit: (self toSnakeCase: fieldName).
			(i + 1 <= bodyForms size and: [
				((bodyForms at: i + 1) isKindOf: ZealListNode) not ]) ifTrue: [
				| nextItem |
				nextItem := bodyForms at: i + 1.
				(nextItem isKindOf: ZealColonChainNode)
					ifFalse: [
						fieldType ifNil: [ fieldType := GDZealCompiler inferTypeFromValue: nextItem ].
						fieldType ifNotNil: [ :t |
							self emit: ': '.
							self emit: (self resolveType: t) ].
						self emit: ' = '.
						self visitExpression: nextItem.
						i := i + 1.
						item := nil ] ].
			item ifNotNil: [
				fieldType ifNotNil: [ :t |
					self emit: ': '.
					self emit: (self resolveType: t) ] ] ].
		i := i + 1 ]
]

{ #category : 'generating - GECS' }
GDZealCodeGenerator >> generateDefentity: aListNode [
	"(defentity player (components [@health @velocity]) (on-ready body) ...)
	 -> @tool / class_name Player / extends Entity / define_components / hooks"
	| exprs name bodyForms |
	exprs := aListNode expressions.
	name := exprs second value value.
	bodyForms := exprs allButFirst allButFirst.
	"Emit class header"
	self emit: '@tool'.
	self nl.
	self emit: 'class_name '.
	self emit: (self toPascalCase: name).
	self nl.
	self emit: 'extends Entity'.
	"Process body clauses"
	bodyForms do: [ :form |
		| head |
		(form isKindOf: ZealListNode) ifFalse: [ ^ self ].
		head := form expressions first value value.
		head = 'components' ifTrue: [ self nl. self nl. self emitDefineComponents: form ].
		head = 'on-ready' ifTrue: [ self nl. self nl. self emitEntityHook: 'on_ready' body: form expressions allButFirst ].
		head = 'on-destroy' ifTrue: [ self nl. self nl. self emitEntityHook: 'on_destroy' body: form expressions allButFirst ].
		head = 'on-enable' ifTrue: [ self nl. self nl. self emitEntityHook: 'on_enable' body: form expressions allButFirst ].
		head = 'on-disable' ifTrue: [ self nl. self nl. self emitEntityHook: 'on_disable' body: form expressions allButFirst ] ]
]

{ #category : 'codegen-fsm' }
GDZealCodeGenerator >> generateDeffsm: aListNode [
	"(deffsm name body...)
	 (deffsm name [bindings...] body...)
	 Emits the FSM component with optional bindings as tick parameters.
	 Body may include (sync ...) and (race ...) for concurrent lanes — the lane code
	 is INLINED into the controller arm rather than calling helper functions, saving
	 ~300 ns/controller-frame of GDScript function-call overhead.
	 State dispatch uses if/elif chains rather than match because GDScript's match
	 is significantly slower (~2x) for integer dispatch."
	| exprs name bodyForms bindings third splitResult states lanes |
	exprs := aListNode expressions.
	name := exprs second value value.
	bindings := OrderedCollection new.
	bodyForms := exprs allButFirst allButFirst.
	bodyForms isEmpty ifFalse: [
		third := bodyForms first.
		(third isKindOf: ZealVectorNode) ifTrue: [
			bindings := GDZealCompiler parseFsmBindings: third.
			bodyForms := bodyForms allButFirst ] ].
	
	registry register: name.
	splitResult := GDZealCompiler fsmSplitBody: bodyForms.
	states := splitResult at: #states.
	lanes := splitResult at: #lanes.
	currentBindings := bindings.
	currentStateVar := '_state'.
	currentTimerVar := '_timer'.
	
	"Class header"
	self emit: 'class_name C_'.
	self emit: (self toPascalCase: name).
	self nl.
	self emit: 'extends Component'.
	self nl. self nl.
	
	"State + timer fields"
	self emit: '@export var _state: int = 0'. self nl.
	self emit: '@export var _timer: float = 0.0'. self nl.
	"Per-lane fields (still needed — must persist across frames)"
	lanes do: [ :lane |
		| pfx |
		pfx := '_l' , (lane at: #laneId) asString.
		self emit: '@export var ' , pfx , '_state: int = 0'. self nl.
		self emit: '@export var ' , pfx , '_timer: float = 0.0'. self nl ].
	self nl.
	
	"Tick method signature with bindings as parameters"
	self emit: 'func tick(entity: Entity, delta: float'.
	bindings do: [ :b |
		self emit: ', '.
		self emit: (b at: #name).
		self emit: ': '.
		self emit: (self resolveType: (b at: #type)) ].
	self emit: ') -> void:'.
	self indent. self nl.
	"if/elif dispatch on _state"
	states withIndexDo: [ :state :i |
		i = 1
			ifTrue: [ self emit: 'if _state == 0:' ]
			ifFalse: [ self emit: 'elif _state == ' , (i - 1) asString , ':' ].
		self indent. self nl.
		self emitFsmState: state index: i - 1 totalStates: states size.
		self dedent.
		i < states size ifTrue: [ self nl ] ].
	self dedent
]

{ #category : 'generating - definitions' }
GDZealCodeGenerator >> generateDefn: aListNode [
	"(defn name [params] :retType body...) -> func name(params) -> retType:"
	| exprs nameNode name params bodyExprs retType |
	exprs := aListNode expressions.
	nameNode := exprs second.
	"Resolve name and optional return type from colon chain"
	retType := nil.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: nameNode value value.
		name := resolved at: #name.
		retType := resolved at: #type ]
	ifFalse: [
		name := nameNode value value ].
	"Find params vector and body"
	params := nil.
	bodyExprs := OrderedCollection new.
	exprs allButFirst allButFirst do: [ :e |
		(params isNil and: [ e isKindOf: ZealVectorNode ])
			ifTrue: [ params := e ]
			ifFalse: [
				"Keyword as return type hint"
				(retType isNil and: [ e isKindOf: ZealKeywordNode ])
					ifTrue: [ retType := e value value allButFirst ]
					ifFalse: [ bodyExprs add: e ] ] ].
	"Emit"
	self emit: 'func '.
	self emit: (self toSnakeCase: name).
	self emit: '('.
	params ifNotNil: [
		params expressions
			do: [ :p | self emitParam: p ]
			separatedBy: [ self emit: ', ' ] ].
	self emit: ')'.
	retType ifNotNil: [
		self emit: ' -> '.
		self emit: (self resolveType: retType) ].
	self emit: ':'.
	bodyExprs isEmpty ifTrue: [
		self indent. self nl. self emit: 'pass'. self dedent ]
	ifFalse: [
		self indent.
		bodyExprs do: [ :e | self nl. self visitExpression: e ].
		self dedent ]
]

{ #category : 'generating - GECS' }
GDZealCodeGenerator >> generateDefobserver: aListNode [
	"(defobserver health-observer (watch @health) (match ...) (on-added [...] body) ...)
	 -> class_name O_HealthObserver / extends Observer / watch / match / handlers"
	| exprs name bodyForms |
	exprs := aListNode expressions.
	name := exprs second value value.
	bodyForms := exprs allButFirst allButFirst.
	"Emit class header"
	self emit: 'class_name O_'.
	self emit: (self toPascalCase: name).
	self nl.
	self emit: 'extends Observer'.
	"Process body clauses"
	bodyForms do: [ :form |
		| head |
		(form isKindOf: ZealListNode) ifFalse: [ ^ self ].
		head := form expressions first value value.
		head = 'watch' ifTrue: [ self nl. self nl. self emitObserverWatch: form ].
		head = 'match' ifTrue: [ self nl. self nl. self emitObserverMatch: form ].
		head = 'on-added' ifTrue: [ self nl. self nl. self emitObserverHandler: 'on_component_added' params: #('entity: Entity' 'component: Resource') form: form ].
		head = 'on-removed' ifTrue: [ self nl. self nl. self emitObserverHandler: 'on_component_removed' params: #('entity: Entity' 'component: Resource') form: form ].
		head = 'on-changed' ifTrue: [ self nl. self nl. self emitObserverHandler: 'on_component_changed' params: #('entity: Entity' 'component: Resource' 'property: String' 'new_value: Variant' 'old_value: Variant') form: form ] ]
]

{ #category : 'generating - GECS' }
GDZealCodeGenerator >> generateDefsystem: aListNode [
	"Two forms:
	 Shorthand: (defsystem name [@comp1 @comp2] (with-none [...]) body...)
	 Full: (defsystem name (query ...) (process [...] body...) (deps {...}) (setup body))
	 Detect by: 3rd element is VectorNode -> shorthand, else full form."
	| exprs name rest |
	exprs := aListNode expressions.
	name := exprs second value value.
	rest := exprs allButFirst allButFirst.
	"Emit class header"
	self emit: 'class_name '.
	self emit: (self toPascalCase: name).
	self nl.
	self emit: 'extends System'.
	"Detect form"
	(rest notEmpty and: [ rest first isKindOf: ZealVectorNode ])
		ifTrue: [ self generateDefsystemShorthand: name components: rest first rest: rest allButFirst ]
		ifFalse: [ self generateDefsystemFull: rest ]
]

{ #category : 'generating - GECS' }
GDZealCodeGenerator >> generateDefsystemFull: bodyForms [
	"Full form: (query ...) (process [...] body...) (deps {...}) (setup body)"
	bodyForms do: [ :form |
		(form isKindOf: ZealListNode) ifTrue: [
			| head |
			head := form expressions first value value.
			head = 'query' ifTrue: [ self nl. self nl. self emitSystemQuery: form ].
			head = 'process' ifTrue: [ self nl. self nl. self emitSystemProcess: form ].
			head = 'deps' ifTrue: [ self nl. self nl. self emitSystemDeps: form ].
			head = 'setup' ifTrue: [ self nl. self nl. self emitSystemSetup: form ] ] ]
]

{ #category : 'generating - GECS' }
GDZealCodeGenerator >> generateDefsystemShorthand: name components: compVector rest: restForms [
	"Shorthand: vector = with-all + iterate + auto-bind.
	 compVector entries: @comp or binding:@comp (colon chain).
	 restForms: optional query modifiers (with-none, enabled, etc.) + body expressions.
	 delta is always available as a binding in the body."
	| compRefs bindings queryMods bodyExprs bodyStr usesDelta |
	"Parse component vector into refs and binding names"
	compRefs := OrderedCollection new.
	bindings := OrderedCollection new.
	compVector expressions do: [ :node |
		(node isKindOf: ZealColonChainNode)
			ifTrue: [
				| resolved |
				resolved := self resolveColonChain: node value value.
				bindings add: (self toSnakeCase: (resolved at: #name)).
				compRefs add: ((resolved at: #type) ifNotNil: [ :t | t ] ifNil: [
					(resolved at: #annotations) ifNotEmpty: [ :a | a first ] ifEmpty: [ resolved at: #name ] ]) ]
			ifFalse: [
				| ref refName |
				ref := node value value.
				refName := (ref beginsWith: '@') ifTrue: [ ref allButFirst ] ifFalse: [ ref ].
				bindings add: (self toSnakeCase: refName).
				compRefs add: ref ] ].
	"Split rest into query modifiers vs body"
	queryMods := OrderedCollection new.
	bodyExprs := OrderedCollection new.
	restForms do: [ :form |
		| isQueryMod |
		isQueryMod := false.
		(form isKindOf: ZealListNode) ifTrue: [
			| head |
			head := form expressions first value value.
			(#('with-none' 'with-any' 'with-group' 'without-group' 'enabled' 'disabled') includes: head)
				ifTrue: [ isQueryMod := true ] ].
		isQueryMod
			ifTrue: [ queryMods add: form ]
			ifFalse: [ bodyExprs add: form ] ].
	"Emit query"
	self nl. self nl.
	self emit: 'func query() -> QueryBuilder:'.
	self indent. self nl.
	self emit: 'return q.with_all(['.
	compRefs do: [ :ref | self emit: (self resolveClassRef: ref) ] separatedBy: [ self emit: ', ' ].
	self emit: ']).iterate(['.
	compRefs do: [ :ref | self emit: (self resolveClassRef: ref) ] separatedBy: [ self emit: ', ' ].
	self emit: '])'.
	queryMods do: [ :mod | self emitQueryClause: mod ].
	self dedent.
	"Emit process — always bind delta (no underscore)"
	self nl. self nl.
	self emit: 'func process(entities: Array[Entity], components: Array, delta: float) -> void:'.
	self indent.
	"Bind component arrays"
	1 to: bindings size do: [ :idx |
		self nl.
		self emit: 'var ' , (bindings at: idx) , '_arr = components[' , (idx - 1) printString , ']' ].
	"Loop"
	self nl.
	self emit: 'for _i in entities.size():'.
	self indent.
	self nl.
	self emit: 'var entity = entities[_i]'.
	bindings do: [ :binding |
		self nl.
		self emit: 'var ' , binding , ' = ' , binding , '_arr[_i]' ].
	"Body"
	bodyExprs do: [ :e | self nl. self visitExpression: e ].
	self dedent.
	self dedent
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateDo: aListNode [
	"(do expr1 expr2 ...) -> sequential expressions"
	aListNode expressions allButFirst
		do: [ :e | self visitExpression: e ]
		separatedBy: [ self nl ]
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateFor: aListNode [
	"(for [x coll] body...) -> for x in coll: body"
	| exprs bindingVec bodyExprs items |
	exprs := aListNode expressions.
	bindingVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	items := bindingVec expressions.
	self emit: 'for '.
	self emit: (self toSnakeCase: items first value value).
	self emit: ' in '.
	self visitExpression: items second.
	self emit: ':'.
	self indent.
	bodyExprs do: [ :e | self nl. self visitExpression: e ].
	self dedent
]

{ #category : 'generating - expressions' }
GDZealCodeGenerator >> generateFunctionCall: aListNode [
	"(func args...) -> func(args)"
	| exprs head |
	exprs := aListNode expressions.
	head := exprs first.
	self visitExpression: head.
	self emit: '('.
	exprs allButFirst
		do: [ :arg | self visitExpression: arg ]
		separatedBy: [ self emit: ', ' ].
	self emit: ')'
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateIf: aListNode [
	"(if cond then) or (if cond then else) or (if c1 t1 c2 t2 ... else)"
	| args |
	args := aListNode expressions allButFirst.
	self emitIfChain: args first: true
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateLet: aListNode [
	"(let [var1 val1 var2 val2] body...) -> var declarations + body"
	| exprs bindingVec bodyExprs items i |
	exprs := aListNode expressions.
	bindingVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	items := bindingVec expressions.
	"Emit bindings as var declarations"
	i := 1.
	[ i + 1 <= items size ] whileTrue: [
		| nameNode valNode |
		nameNode := items at: i.
		valNode := items at: i + 1.
		self emit: 'var '.
		(nameNode isKindOf: ZealColonChainNode) ifTrue: [
			| resolved |
			resolved := self resolveColonChain: nameNode value value.
			self emit: (self toSnakeCase: (resolved at: #name)).
			(resolved at: #type) ifNotNil: [ :t |
				self emit: ': '.
				self emit: (self resolveType: t) ] ]
		ifFalse: [
			self emit: (self toSnakeCase: nameNode value value) ].
		self emit: ' = '.
		self visitExpression: valNode.
		self nl.
		i := i + 2 ].
	"Emit body"
	bodyExprs do: [ :e | self visitExpression: e ] separatedBy: [ self nl ]
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateMatch: aListNode [
	"(match expr pat1 body1 pat2 body2 ...) -> match expr: patterns"
	| exprs target pairs |
	exprs := aListNode expressions.
	target := exprs second.
	pairs := exprs allButFirst allButFirst.
	self emit: 'match '.
	self visitExpression: target.
	self emit: ':'.
	self indent.
	1 to: pairs size by: 2 do: [ :i |
		self nl.
		self visitExpression: (pairs at: i).
		self emit: ':'.
		self indent. self nl.
		self visitExpression: (pairs at: i + 1).
		self dedent ].
	self dedent
]

{ #category : 'generating - expressions' }
GDZealCodeGenerator >> generateOperator: aListNode [
	"(+ a b) -> a + b, (+ a b c) -> a + b + c, (not x) -> not x, (= a b) -> a == b"
	| exprs op gdOp operands |
	exprs := aListNode expressions.
	op := exprs first value value.
	operands := exprs allButFirst.
	"Map operators"
	gdOp := op.
	op = '=' ifTrue: [ gdOp := '==' ].
	op = '<>' ifTrue: [ gdOp := '!=' ].
	"Unary not"
	op = 'not' ifTrue: [
		self emit: 'not '.
		self visitExpression: operands first. ^ self ].
	"Unary minus"
	(op = '-' and: [ operands size = 1 ]) ifTrue: [
		self emit: '-'.
		self visitExpression: operands first. ^ self ].
	"Binary / variadic: a op b op c ..."
	operands
		do: [ :o | self visitExpression: o ]
		separatedBy: [ self emit: ' ' , gdOp , ' ' ]
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateReturn: aListNode [
	"(return) -> return, (return expr) -> return expr"
	| exprs |
	exprs := aListNode expressions.
	self emit: 'return'.
	exprs size > 1 ifTrue: [
		self emit: ' '.
		self visitExpression: exprs second ]
]

{ #category : 'generating - definitions' }
GDZealCodeGenerator >> generateSet: aListNode [
	"(set target value) -> target = value
	 (set target += value) -> target += value
	 Target can be a symbol, slash path, or expression like (as e @type field)"
	| exprs targetNode |
	exprs := aListNode expressions.
	targetNode := exprs second.
	"Emit target"
	(targetNode isKindOf: ZealSymbolNode) ifTrue: [
		| target |
		target := targetNode value value.
		(target includes: $/)
			ifTrue: [ self emitSlashAccess: ($/ split: target) ]
			ifFalse: [ self emit: (self toSnakeCase: target) ] ]
	ifFalse: [
		"List target like (as e @node2D position)"
		self visitExpression: targetNode ].
	"3 args: (set target value) -> simple assignment"
	exprs size = 3 ifTrue: [
		self emit: ' = '.
		self visitExpression: exprs third.
		^ self ].
	"4 args: (set target op value) -> compound assignment"
	exprs size >= 4 ifTrue: [
		self emit: ' '.
		self emit: exprs third value value.
		self emit: ' '.
		self visitExpression: exprs fourth ]
]

{ #category : 'generating - definitions' }
GDZealCodeGenerator >> generateSetBang: aListNode [
	"(set! target value) -> target = value"
	| exprs target |
	exprs := aListNode expressions.
	target := exprs second value value.
	"Handle slash paths in target: health/current -> health.current"
	(target includes: $/) ifTrue: [
		self emitSlashAccess: ($/ split: target) ]
	ifFalse: [
		self emit: (self toSnakeCase: target) ].
	self emit: ' = '.
	self visitExpression: exprs third
]

{ #category : 'visiting - slash' }
GDZealCodeGenerator >> generateSlashCall: aListNode [
	"Handle (obj/method args...) -> obj.method(args)"
	| exprs headStr segments args receiver |
	exprs := aListNode expressions.
	headStr := exprs first value value.
	segments := $/ split: headStr.
	args := exprs allButFirst.
	"Build receiver from all segments except last"
	segments size = 1 ifTrue: [
		"Just a function call, no slash"
		self emit: (self toSnakeCase: segments first).
		self emit: '('.
		args do: [ :a | self visitExpression: a ] separatedBy: [ self emit: ', ' ].
		self emit: ')'.
		^ self ].
	"Emit all but last segment as property chain"
	self emitSlashAccess: segments allButLast.
	"Last segment is the method call"
	self emit: '.'.
	self emit: (self toSnakeCase: segments last).
	self emit: '('.
	args do: [ :a | self visitExpression: a ] separatedBy: [ self emit: ', ' ].
	self emit: ')'
]

{ #category : 'generating - definitions' }
GDZealCodeGenerator >> generateVar: aListNode [
	"(var name:type value) -> var name: type = value"
	| exprs nameNode valueNode |
	exprs := aListNode expressions.
	nameNode := exprs second.
	valueNode := exprs size >= 3 ifTrue: [ exprs third ] ifFalse: [ nil ].
	self emit: 'var '.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: nameNode value value.
		self emit: (self toSnakeCase: (resolved at: #name)).
		(resolved at: #type) ifNotNil: [ :t |
			self emit: ': '.
			self emit: (self resolveType: t) ].
		valueNode ifNotNil: [
			self emit: ' = '.
			self visitExpression: valueNode ] ]
	ifFalse: [
		self emit: (self toSnakeCase: nameNode value value).
		valueNode ifNotNil: [
			self emit: ' = '.
			self visitExpression: valueNode ] ]
]

{ #category : 'generating - control flow' }
GDZealCodeGenerator >> generateWhen: aListNode [
	"(when cond body...) -> if cond: body (no else)"
	| exprs |
	exprs := aListNode expressions.
	self emit: 'if '.
	self visitExpression: exprs second.
	self emit: ':'.
	self indent.
	exprs allButFirst allButFirst do: [ :e | self nl. self visitExpression: e ].
	self dedent
]

{ #category : 'emitting' }
GDZealCodeGenerator >> indent [
	indentLevel := indentLevel + 1
]

{ #category : 'initialization' }
GDZealCodeGenerator >> initialize [
	stream := WriteStream on: String new.
	indentLevel := 0.
	registry := GDZealComponentRegistry new
]

{ #category : 'private' }
GDZealCodeGenerator >> isOperator: aString [
	^ #('+' '-' '*' '%' '=' '<>' '<' '>' '<=' '>=' 'and' 'or' 'not' '+=' '-=' '*=' '/=') includes: aString
]

{ #category : 'emitting' }
GDZealCodeGenerator >> nl [
	stream nextPutAll: String crlf.
	self emitIndent
]

{ #category : 'accessing' }
GDZealCodeGenerator >> output [
	^ stream contents
]

{ #category : 'accessing' }
GDZealCodeGenerator >> registry [
	^ registry
]

{ #category : 'private - naming' }
GDZealCodeGenerator >> resolveClassRef: aString [
	"Resolve @name -> class name. Strip @, PascalCase, check component registry for C_ prefix."
	| name |
	name := aString allButFirst. "strip @"
	^ registry resolve: name
]

{ #category : 'private - types' }
GDZealCodeGenerator >> resolveColonChain: aString [
	"GDZeal-aware colon chain resolution. Unlike ZealColonChainResolver,
	 treats @-prefixed segments as types (not annotations).
	 entity:@entity -> name='entity', type='@entity'"
	| resolved type annotations |
	resolved := ZealColonChainResolver resolve: aString.
	type := resolved at: #type.
	annotations := resolved at: #annotations.
	"If type is nil but we have an @annotation, use it as the type"
	(type isNil and: [ annotations notEmpty ]) ifTrue: [
		| atAnno |
		atAnno := annotations detect: [ :a | a beginsWith: '@' ] ifNone: [ nil ].
		atAnno ifNotNil: [
			resolved at: #type put: atAnno.
			resolved at: #annotations put: (annotations reject: [ :a | a = atAnno ]) ] ].
	^ resolved
]

{ #category : 'private - types' }
GDZealCodeGenerator >> resolveType: aTypeString [
	"Map GDZeal type names to GDScript types.
	 int -> int, float -> float, string -> String, bool -> bool,
	 void -> void, @class refs resolved via registry"
	aTypeString ifNil: [ ^ nil ].
	(aTypeString beginsWith: '@') ifTrue: [ ^ self resolveClassRef: aTypeString ].
	aTypeString = 'string' ifTrue: [ ^ 'String' ].
	^ aTypeString
]

{ #category : 'accessing' }
GDZealCodeGenerator >> setRegistry: aRegistry [
	registry := aRegistry
]

{ #category : 'generators' }
GDZealCodeGenerator >> specialForms [
	^ Dictionary new
		at: 'def' put: #generateDef:;
		at: 'var' put: #generateVar:;
		at: 'set' put: #generateSet:;
		at: 'defn' put: #generateDefn:;
		at: 'defcomp' put: #generateDefcomp:;
		at: 'deffsm' put: #generateDeffsm:;
		at: 'defentity' put: #generateDefentity:;
		at: 'defsystem' put: #generateDefsystem:;
		at: 'defobserver' put: #generateDefobserver:;
		at: 'if' put: #generateIf:;
		at: 'when' put: #generateWhen:;
		at: 'for' put: #generateFor:;
		at: 'let' put: #generateLet:;
		at: 'match' put: #generateMatch:;
		at: 'do' put: #generateDo:;
		at: 'return' put: #generateReturn:;
		at: 'as' put: #generateAs:;
		yourself
]

{ #category : 'private - naming' }
GDZealCodeGenerator >> toPascalCase: aString [
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

{ #category : 'private - naming' }
GDZealCodeGenerator >> toSnakeCase: aString [
	"kebab-case -> snake_case"
	^ aString copyReplaceAll: '-' with: '_'
]

{ #category : 'visiting' }
GDZealCodeGenerator >> visitAtom: aNode [
	"Handle atoms: @class refs, /slash access, symbols, keywords, literals"
	| sym |
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		sym := aNode value value.
		"@ class reference (may contain / for static access)"
		(sym beginsWith: '@') ifTrue: [
			(sym includes: $/) ifTrue: [
				"@vector2/RIGHT -> Vector2.RIGHT"
				| segments |
				segments := $/ split: sym.
				self emit: (self resolveClassRef: segments first).
				segments allButFirst do: [ :seg |
					self emit: '.'.
					self emit: seg ].
				^ self ].
			self emit: (self resolveClassRef: sym). ^ self ].
		"/ slash property access"
		(sym includes: $/) ifTrue: [
			self emitSlashAccess: ($/ split: sym). ^ self ].
		"_ placeholder"
		sym = '_' ifTrue: [ self emit: '_'. ^ self ].
		"true/false/null"
		(#('true' 'false' 'null') includes: sym) ifTrue: [
			self emit: sym. ^ self ].
		"Regular symbol -> snake_case"
		(self isOperator: sym)
			ifTrue: [ self emit: sym ]
			ifFalse: [ self emit: (self toSnakeCase: sym) ].
		^ self ].
	"Keyword -> string literal"
	(aNode isKindOf: ZealKeywordNode) ifTrue: [
		self emit: '"' , aNode value value allButFirst , '"'. ^ self ].
	"Colon chain -> resolve name, snake_case"
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: aNode value value.
		self emit: (self toSnakeCase: (resolved at: #name)). ^ self ].
	"Range literal"
	(aNode isKindOf: ZealRangeLiteralNode) ifTrue: [
		self emit: 'range(' , (aNode value value copyReplaceAll: '..' with: ', ') , ')'. ^ self ].
	"All other literals (int, float, hex, string, char)"
	self emit: aNode value value
]

{ #category : 'visiting' }
GDZealCodeGenerator >> visitExpression: aNode [
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self visitList: aNode ].
	(aNode isKindOf: ZealVectorNode) ifTrue: [ ^ self visitVector: aNode ].
	(aNode isKindOf: ZealMapNode) ifTrue: [ ^ self visitMap: aNode ].
	^ self visitAtom: aNode
]

{ #category : 'visiting' }
GDZealCodeGenerator >> visitList: aNode [
	"Dispatch: slash call, special form, operator, or function call"
	| exprs head headStr |
	exprs := aNode expressions.
	exprs isEmpty ifTrue: [ ^ self ].
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	(head isKindOf: ZealColonChainNode) ifTrue: [
		headStr := (ZealColonChainResolver resolve: head value value) at: #name ].
	headStr ifNil: [ ^ self generateFunctionCall: aNode ].
	"Slash dispatch: symbol contains /"
	(headStr includes: $/) ifTrue: [ ^ self generateSlashCall: aNode ].
	"Special forms"
	self specialForms
		at: headStr
		ifPresent: [ :selector | ^ self perform: selector with: aNode ].
	"Operators"
	(self isOperator: headStr) ifTrue: [ ^ self generateOperator: aNode ].
	"Regular function call"
	^ self generateFunctionCall: aNode
]

{ #category : 'visiting' }
GDZealCodeGenerator >> visitMap: aNode [
	"{k1 v1 k2 v2} -> {k1: v1, k2: v2}"
	self emit: '{'.
	aNode pairs
		do: [ :pair |
			self visitExpression: pair key.
			self emit: ': '.
			self visitExpression: pair value ]
		separatedBy: [ self emit: ', ' ].
	self emit: '}'
]

{ #category : 'visiting' }
GDZealCodeGenerator >> visitVector: aNode [
	"[a b c] -> [a, b, c]"
	self emit: '['.
	aNode expressions
		do: [ :e | self visitExpression: e ]
		separatedBy: [ self emit: ', ' ].
	self emit: ']'
]
