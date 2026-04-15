Class {
	#name : 'GodotZealCodeGenerator',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'indentLevel',
		'registry',
		'currentBindings',
		'currentStateVar',
		'currentTimerVar',
		'localScope',
		'fusionSubs'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compilation' }
GodotZealCodeGenerator class >> compile: aString [
	"Compile GDZeal source to GDScript string. Pre-processes λ to fn."
	^ self new generate: (ZealParser parse: (self preprocess: aString))
]

{ #category : 'compilation' }
GodotZealCodeGenerator class >> compile: aString withRegistry: aRegistry [
	"Compile GDZeal source with a shared component registry. Pre-processes λ to fn."
	| gen |
	gen := self new.
	gen setRegistry: aRegistry.
	^ gen generate: (ZealParser parse: (self preprocess: aString))
]

{ #category : 'compilation' }
GodotZealCodeGenerator class >> preprocess: aString [
	"Pre-process GDZeal source before parsing. Replaces λ with fn so the SmaCC
	 parser (which only handles ASCII identifiers) accepts lambda-character source."
	^ aString copyReplaceAll: (Character value: 16r03BB) asString with: 'fn'
]

{ #category : 'scope' }
GodotZealCodeGenerator >> bindLocal: aName [
	"Add a name to the topmost scope frame."
	aName ifNil: [ ^ self ].
	localScope last add: aName asString
]

{ #category : 'fusion' }
GodotZealCodeGenerator >> classifyXform: aNode [
	"Classify a transducer factory call into a fusion-friendly descriptor.
	 Returns a Dictionary {#kind, #fn (for filter/map/etc.), #n (for take/drop)}
	 or nil if not fusible."
	| exprs head kind fnInfo |
	(aNode isKindOf: ZealListNode) ifFalse: [ ^ nil ].
	exprs := aNode expressions.
	exprs isEmpty ifTrue: [ ^ nil ].
	head := exprs first.
	(head isKindOf: ZealSymbolNode) ifFalse: [ ^ nil ].
	kind := head value value.
	"filter/map/keep/take-while/drop-while: need an inline fn body"
	(#('filter' 'map' 'keep' 'take-while' 'drop-while') includes: kind) ifTrue: [
		exprs size = 2 ifFalse: [ ^ nil ].
		fnInfo := self extractFnBody: exprs second.
		fnInfo ifNil: [ ^ nil ].
		^ Dictionary new at: #kind put: kind; at: #fn put: fnInfo; yourself ].
	"take/drop: need a literal or expression for n"
	(#('take' 'drop') includes: kind) ifTrue: [
		exprs size = 2 ifFalse: [ ^ nil ].
		^ Dictionary new at: #kind put: kind; at: #nExpr put: exprs second; yourself ].
	"distinct/dedupe/flatten/indexed: nullary"
	(#('distinct' 'dedupe' 'flatten' 'indexed') includes: kind) ifTrue: [
		exprs size = 1 ifFalse: [ ^ nil ].
		^ Dictionary new at: #kind put: kind; yourself ].
	^ nil
]

{ #category : 'emitting' }
GodotZealCodeGenerator >> dedent [
	indentLevel := indentLevel - 1
]

{ #category : 'emitting' }
GodotZealCodeGenerator >> emit: aString [
	stream nextPutAll: aString
]

{ #category : 'generating - GECS helpers' }
GodotZealCodeGenerator >> emitDefineComponents: aListNode [
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
GodotZealCodeGenerator >> emitEntityHook: hookName body: bodyExprs [
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
GodotZealCodeGenerator >> emitExport: aListNode [
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
GodotZealCodeGenerator >> emitFsmState: state index: i totalStates: total [
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

{ #category : 'fusion' }
GodotZealCodeGenerator >> emitFusionBody: bodyNode param: paramName as: bindName [
	"Emit the lambda body expression. Since the body references the original param
	 name which we bound as `var paramName = _v`, just visit normally."
	self visitExpression: bodyNode
]

{ #category : 'fusion' }
GodotZealCodeGenerator >> emitFusionStep: desc index: idx [
	"Emit one step of the fused loop body. Lambda params get unique names _pN
	 to avoid GDScript redeclaration errors when multiple steps use the same name.
	 A substitution dict temporarily maps original param -> _pN during body emission."
	| kind fnInfo paramName uniqueName |
	kind := desc at: #kind.
	fnInfo := desc at: #fn ifAbsent: [ nil ].
	paramName := fnInfo ifNotNil: [ (fnInfo at: #params) ifEmpty: [ nil ] ifNotEmpty: [ :ps | ps first ] ] ifNil: [ nil ].
	uniqueName := paramName ifNotNil: [ '_p' , idx printString ].
	"filter: if not pred, continue"
	kind = 'filter' ifTrue: [
		self nl.
		uniqueName ifNotNil: [ self emit: 'var ' , uniqueName , ' = _v'. self nl ].
		self emit: 'if not ('.
		self withSubstitution: paramName as: uniqueName do: [ self visitExpression: (fnInfo at: #body) ].
		self emit: '):'. self indent. self nl. self emit: 'continue'. self dedent.
		^ self ].
	"map: _v = body"
	kind = 'map' ifTrue: [
		self nl.
		uniqueName ifNotNil: [ self emit: 'var ' , uniqueName , ' = _v'. self nl ].
		self emit: '_v = '.
		self withSubstitution: paramName as: uniqueName do: [ self visitExpression: (fnInfo at: #body) ].
		^ self ].
	"keep: _v = body; if null, continue"
	kind = 'keep' ifTrue: [
		self nl.
		uniqueName ifNotNil: [ self emit: 'var ' , uniqueName , ' = _v'. self nl ].
		self emit: '_v = '.
		self withSubstitution: paramName as: uniqueName do: [ self visitExpression: (fnInfo at: #body) ].
		self nl. self emit: 'if _v == null:'. self indent. self nl. self emit: 'continue'. self dedent.
		^ self ].
	"take: append + counter + break"
	kind = 'take' ifTrue: [
		self nl. self emit: '_r.append(_v)'.
		self nl. self emit: '_tk' , idx printString , ' += 1'.
		self nl. self emit: 'if _tk' , idx printString , ' >= '.
		self visitExpression: (desc at: #nExpr).
		self emit: ':'. self indent. self nl. self emit: 'break'. self dedent.
		^ self ].
	"drop: counter + continue"
	kind = 'drop' ifTrue: [
		self nl. self emit: '_dk' , idx printString , ' += 1'.
		self nl. self emit: 'if _dk' , idx printString , ' <= '.
		self visitExpression: (desc at: #nExpr).
		self emit: ':'. self indent. self nl. self emit: 'continue'. self dedent.
		^ self ].
	"take-while: if not pred, break"
	kind = 'take-while' ifTrue: [
		self nl.
		uniqueName ifNotNil: [ self emit: 'var ' , uniqueName , ' = _v'. self nl ].
		self emit: 'if not ('.
		self withSubstitution: paramName as: uniqueName do: [ self visitExpression: (fnInfo at: #body) ].
		self emit: '):'. self indent. self nl. self emit: 'break'. self dedent.
		^ self ].
	"drop-while: flag + continue"
	kind = 'drop-while' ifTrue: [
		self nl.
		uniqueName ifNotNil: [ self emit: 'var ' , uniqueName , ' = _v'. self nl ].
		self emit: 'if _dw' , idx printString , ' and ('.
		self withSubstitution: paramName as: uniqueName do: [ self visitExpression: (fnInfo at: #body) ].
		self emit: '):'. self indent. self nl. self emit: 'continue'. self dedent.
		self nl. self emit: '_dw' , idx printString , ' = false'.
		^ self ].
	"distinct/dedupe/flatten/indexed — no lambda, no substitution needed"
	kind = 'distinct' ifTrue: [
		self nl. self emit: 'if _seen' , idx printString , '.has(_v):'.
		self indent. self nl. self emit: 'continue'. self dedent.
		self nl. self emit: '_seen' , idx printString , '[_v] = true'. ^ self ].
	kind = 'dedupe' ifTrue: [
		self nl. self emit: 'if _hprev' , idx printString , ' and _prev' , idx printString , ' == _v:'.
		self indent. self nl. self emit: 'continue'. self dedent.
		self nl. self emit: '_prev' , idx printString , ' = _v'.
		self nl. self emit: '_hprev' , idx printString , ' = true'. ^ self ].
	kind = 'flatten' ifTrue: [
		self nl. self emit: 'if _v is Array:'.
		self indent. self nl. self emit: 'for _sub in _v:'.
		self indent. self nl. self emit: '_r.append(_sub)'. self dedent.
		self nl. self emit: 'continue'. self dedent. ^ self ].
	kind = 'indexed' ifTrue: [
		self nl. self emit: '_v = [_idx' , idx printString , ', _v]'.
		self nl. self emit: '_idx' , idx printString , ' += 1'. ^ self ]
]

{ #category : 'generating - control flow' }
GodotZealCodeGenerator >> emitIfChain: args first: isFirst [
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
GodotZealCodeGenerator >> emitIndent [
	indentLevel timesRepeat: [ stream nextPut: Character tab ]
]

{ #category : 'generating - GECS helpers' }
GodotZealCodeGenerator >> emitInit: aListNode [
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
GodotZealCodeGenerator >> emitInitParam: aNode [
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
GodotZealCodeGenerator >> emitInlineLane: lane [
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
GodotZealCodeGenerator >> emitLaneHelper: lane [
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
GodotZealCodeGenerator >> emitLaneResetBlock: lanes advanceVar: sv toIndex: nextIdx [
	"Reset all lanes to state 0 / timer 0, then advance the controller's state var.
	 Shared by sync (after the and-join fires) and race (after the won flag fires)."
	lanes do: [ :lane |
		| pfx |
		pfx := '_l' , (lane at: #laneId) asString.
		self emit: pfx , '_state = 0'. self nl.
		self emit: pfx , '_timer = 0.0'. self nl ].
	self emit: sv , ' = '. self emit: nextIdx asString
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> emitNullaryTransducer: factoryName from: aListNode [
	"Common dispatch for nullary-shape transducers (form) or (form coll).
	 Z library factory takes no arg; the underscore suffix avoids GDScript reserved words."
	| exprs |
	exprs := aListNode expressions.
	exprs size = 1 ifTrue: [
		self emit: 'Z.' , factoryName , '()'.
		^ self ].
	self emit: 'Z.into([], Z.' , factoryName , '(), '.
	self visitExpression: exprs second.
	self emit: ')'
]

{ #category : 'generating - GECS helpers' }
GodotZealCodeGenerator >> emitObserverHandler: methodName params: gdParams form: aListNode [
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
GodotZealCodeGenerator >> emitObserverMatch: aListNode [
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
GodotZealCodeGenerator >> emitObserverWatch: aListNode [
	"(watch @health) -> func watch() -> Resource: return C_Health"
	self emit: 'func watch() -> Resource:'.
	self indent. self nl.
	self emit: 'return '.
	self emit: (self resolveClassRef: aListNode expressions second value value).
	self dedent
]

{ #category : 'private - params' }
GodotZealCodeGenerator >> emitParam: aNode [
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
GodotZealCodeGenerator >> emitQueryClause: aListNode [
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

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> emitReducer: factoryName from: aListNode [
	"Common emission for whole-sequence reducers (form xs) -> Z.factoryName(xs)."
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.' , factoryName , '('.
	self visitExpression: exprs second.
	self emit: ')'
]

{ #category : 'visiting - slash' }
GodotZealCodeGenerator >> emitSlashAccess: segments [
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
GodotZealCodeGenerator >> emitSystemDeps: aListNode [
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
GodotZealCodeGenerator >> emitSystemProcess: aListNode [
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
GodotZealCodeGenerator >> emitSystemQuery: aListNode [
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
GodotZealCodeGenerator >> emitSystemSetup: aListNode [
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

{ #category : 'transducers' }
GodotZealCodeGenerator >> emitTransducer: factoryName from: aListNode [
	"Common dispatch for transducer forms with shape (form arg) or (form arg coll).
	 Single-arg → Z.factoryName(arg) (returns xform Callable).
	 Two-arg → Z.into([], Z.factoryName(arg), coll) (eager, runs through driver)."
	| exprs |
	exprs := aListNode expressions.
	exprs size = 2 ifTrue: [
		self emit: 'Z.' , factoryName , '('.
		self visitExpression: exprs second.
		self emit: ')'.
		^ self ].
	self emit: 'Z.into([], Z.' , factoryName , '('.
	self visitExpression: exprs second.
	self emit: '), '.
	self visitExpression: exprs third.
	self emit: ')'
]

{ #category : 'fusion' }
GodotZealCodeGenerator >> extractFnBody: aNode [
	"If aNode is (fn [params] body), return {#params -> params, #body -> body}.
	 Returns nil if not a single-expression fn form."
	| exprs |
	(aNode isKindOf: ZealListNode) ifFalse: [ ^ nil ].
	exprs := aNode expressions.
	(exprs size >= 3 and: [
		(exprs first isKindOf: ZealSymbolNode) and: [ exprs first value value = 'fn' ]
	]) ifFalse: [ ^ nil ].
	"Only fuse single-expression bodies"
	exprs size = 3 ifFalse: [ ^ nil ].
	^ Dictionary new
		at: #params put: (exprs second expressions collect: [ :p | self paramName: p ]);
		at: #body put: exprs third;
		yourself
]

{ #category : 'fusion' }
GodotZealCodeGenerator >> fusionSubstitutions [
	^ fusionSubs
]

{ #category : 'generating' }
GodotZealCodeGenerator >> generate: aZealProgramNode [
	"Main entry point: walk all top-level expressions"
	aZealProgramNode expressions
		do: [ :expr | self visitExpression: expr ]
		separatedBy: [ self nl. self nl ].
	^ self output
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateAnyP: aListNode [
	"(any? pred xs) -> Z.any(pred, xs)"
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.any('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ')'
]

{ #category : 'generating - expressions' }
GodotZealCodeGenerator >> generateAs: aListNode [
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

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateAvg: aListNode [
	^ self emitReducer: 'avg' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateChunk: aListNode [
	"(chunk n) -> Z.chunking(n) — transducer, non-overlapping
	 (chunk n step) -> Z.chunking(n, step) — transducer, sliding window
	 The eager forms route through `into`: (into [] (chunk n) xs).
	 Dropping the eager arities here avoids the (chunk n step) vs (chunk n xs)
	 ambiguity at the compile site."
	| exprs |
	exprs := aListNode expressions.
	exprs size = 2 ifTrue: [
		self emit: 'Z.chunking('.
		self visitExpression: exprs second.
		self emit: ')'.
		^ self ].
	"(chunk n step)"
	self emit: 'Z.chunking('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ')'
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateChunkBy: aListNode [
	^ self emitTransducer: 'chunking_by' from: aListNode
]

{ #category : 'transducers-core' }
GodotZealCodeGenerator >> generateComp: aListNode [
	"(comp xform1 xform2 ...) -> Z.comp([xform1, xform2, ...])
	 Composes transducers (or any callables) right-to-left during reducer wrapping —
	 left-most xform runs FIRST on each element."
	| exprs args |
	exprs := aListNode expressions.
	args := exprs allButFirst.
	self emit: 'Z.comp(['.
	args
		do: [ :a | self visitExpression: a ]
		separatedBy: [ self emit: ', ' ].
	self emit: '])'
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateCount: aListNode [
	"(count xs) -> xs.size() (no library call needed; built into GDScript Array)"
	| exprs |
	exprs := aListNode expressions.
	self visitExpression: exprs second.
	self emit: '.size()'
]

{ #category : 'transducers-sources' }
GodotZealCodeGenerator >> generateCycle: aListNode [
	"(cycle xs) -> Z.cycle_(xs) — infinite cycling iterator."
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.cycle_('.
	self visitExpression: exprs second.
	self emit: ')'
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateDedupe: aListNode [
	^ self emitNullaryTransducer: 'dedupe_' from: aListNode
]

{ #category : 'generation' }
GodotZealCodeGenerator >> generateDef: aListNode [
	"(def name:type value) -> const name: type = value
	 Top-level (def name (fn ...)) is not allowed — use (defn name [params] body)
	 for a real function. We refuse it here so the call-site rule (named function
	 vs Callable) stays unambiguous at the module level."
	| exprs nameNode valueNode |
	exprs := aListNode expressions.
	nameNode := exprs second.
	valueNode := exprs third.
	"Reject top-level lambda binding"
	((valueNode isKindOf: ZealListNode)
		and: [ valueNode expressions notEmpty
		and: [ (valueNode expressions first isKindOf: ZealSymbolNode)
		and: [ valueNode expressions first value value = 'fn' ] ] ]) ifTrue: [
			self error: 'top-level (def name (fn ...)) is not allowed — use (defn name [params] body) for a real function' ].
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

{ #category : 'special forms' }
GodotZealCodeGenerator >> generateDefco: aListNode [
	"Register a coroutine for compile-time expansion at defcosystem sites.
	 (defco name [params] body...) — emits no GDScript; pure macro definition."
	| exprs name params body |
	exprs := aListNode expressions.
	name := (exprs at: 2) value value.
	(exprs at: 3) class = ZealVectorNode 
		ifTrue: [
			params := (exprs at: 3) expressions collect: [ :e | e value value ].
			body := (exprs copyFrom: 4 to: exprs size) ]
		ifFalse: [
			params := #().
			body := (exprs copyFrom: 3 to: exprs size) ].
	registry registerCoroutine: name params: params body: body asArray.
	^ ''
]

{ #category : 'generators' }
GodotZealCodeGenerator >> generateDefcomp: aListNode [
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
						fieldType ifNil: [ fieldType := GodotZealCompiler inferTypeFromValue: nextItem ].
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

{ #category : 'generation' }
GodotZealCodeGenerator >> generateDefcosystem: aListNode [
	"(defcosystem name [bindings...] body...)
	 Generates a Component class with _state/_timer fields and a tick method
	 containing the FSM state machine."
	| exprs name bodyForms bindings third splitResult states lanes |
	exprs := aListNode expressions.
	name := exprs second value value.
	bindings := OrderedCollection new.
	bodyForms := exprs allButFirst allButFirst.
	bodyForms isEmpty ifFalse: [
		third := bodyForms first.
		(third isKindOf: ZealVectorNode) ifTrue: [
			bindings := GodotZealCompiler parseFsmBindings: third.
			bodyForms := bodyForms allButFirst ] ].
	registry register: name.
	splitResult := GodotZealCompiler fsmSplitBody: bodyForms coroutines: registry coroutines.
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
	lanes do: [ :lane |
		| pfx |
		pfx := '_l' , (lane at: #laneId) asString.
		self emit: '@export var ' , pfx , '_state: int = 0'. self nl.
		self emit: '@export var ' , pfx , '_timer: float = 0.0'. self nl ].
	self nl.
	"Tick method signature"
	self emit: 'func tick(entity: Entity, delta: float'.
	bindings do: [ :b |
		self emit: ', '.
		self emit: (b at: #name).
		self emit: ': '.
		self emit: (self resolveType: (b at: #type)) ].
	self emit: ') -> void:'.
	"Body — if/elif dispatch on _state. indent THEN nl so the body is properly nested."
	self indent.
	states withIndexDo: [ :state :idx |
		self nl.
		idx = 1
			ifTrue: [ self emit: 'if _state == 0:' ]
			ifFalse: [ self emit: 'elif _state == ' , (idx - 1) asString , ':' ].
		self indent.
		self nl.
		self emitFsmState: state index: idx - 1 totalStates: states size.
		self dedent ].
	self dedent
]

{ #category : 'generating - GECS' }
GodotZealCodeGenerator >> generateDefentity: aListNode [
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

{ #category : 'generation' }
GodotZealCodeGenerator >> generateDefn: aListNode [
	"(defn name [params] :retType body...) -> func name(params) -> retType:
	 When a return type is declared (and isn't void), the last body expression is
	 implicitly returned (unless it's a statement-only form like set/var/if/for/
	 when/match which can't be the operand of return). A single (do ...) body is
	 unwrapped so the do's last child becomes the implicit return.
	 Pushes a fresh scope frame containing the param names so calls inside the
	 body that reference a parameter route through .call (higher-order functions)."
	| exprs nameNode name params bodyExprs retType implicitReturn |
	exprs := aListNode expressions.
	nameNode := exprs second.
	retType := nil.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: nameNode value value.
		name := resolved at: #name.
		retType := resolved at: #type ]
	ifFalse: [
		name := nameNode value value ].
	params := nil.
	bodyExprs := OrderedCollection new.
	exprs allButFirst allButFirst do: [ :e |
		(params isNil and: [ e isKindOf: ZealVectorNode ])
			ifTrue: [ params := e ]
			ifFalse: [
				(retType isNil and: [ e isKindOf: ZealKeywordNode ])
					ifTrue: [ retType := e value value allButFirst ]
					ifFalse: [ bodyExprs add: e ] ] ].
	"Unwrap a top-level (do ...) so its children become the function body."
	(bodyExprs size = 1
		and: [ (bodyExprs first isKindOf: ZealListNode)
		and: [ bodyExprs first expressions notEmpty
		and: [ (bodyExprs first expressions first isKindOf: ZealSymbolNode)
		and: [ bodyExprs first expressions first value value = 'do' ] ] ] ]) ifTrue: [
			bodyExprs := bodyExprs first expressions allButFirst asOrderedCollection ].
	"Auto-return only when retType is meaningful (not void)."
	implicitReturn := retType notNil and: [ retType ~= 'void' and: [ retType ~= 'Void' ] ].
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
	self pushScope.
	[ params ifNotNil: [
		params expressions do: [ :p | self bindLocal: (self paramName: p) ] ].
	  bodyExprs isEmpty ifTrue: [
		self indent. self nl. self emit: 'pass'. self dedent ]
	  ifFalse: [
		self indent.
		bodyExprs doWithIndex: [ :e :i |
			self nl.
			(implicitReturn
				and: [ i = bodyExprs size
				and: [ (self isStatementForm: e) not ] ])
				ifTrue: [ self emit: 'return '. self visitExpression: e ]
				ifFalse: [ self visitExpression: e ] ].
		self dedent ] ]
		ensure: [ self popScope ]
]

{ #category : 'generating - GECS' }
GodotZealCodeGenerator >> generateDefobserver: aListNode [
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

{ #category : 'generation' }
GodotZealCodeGenerator >> generateDefscene: aListNode [
	"(defscene name (spawn [@entity1 @entity2]) (on-ready body...) (on-input body...))
	 Spawns use ClassName.new() since defentity generates class_name — no .tscn needed."
	| exprs name spawns readyBody inputBody |
	exprs := aListNode expressions.
	name := exprs second value value.
	spawns := OrderedCollection new.
	readyBody := OrderedCollection new.
	inputBody := OrderedCollection new.
	exprs allButFirst allButFirst do: [ :form |
		(form isKindOf: ZealListNode) ifTrue: [
			| head |
			head := form expressions first value value.
			head = 'spawn' ifTrue: [
				form expressions second expressions do: [ :e |
					spawns add: e value value ] ].
			head = 'on-ready' ifTrue: [
				readyBody addAll: form expressions allButFirst ].
			head = 'on-input' ifTrue: [
				inputBody addAll: form expressions allButFirst ] ] ].
	self emit: 'extends Node2D'. self nl. self nl.
	self emit: '@onready var world: World = $World'. self nl. self nl.
	self emit: 'func _ready() -> void:'. self indent.
	self nl. self emit: 'ECS.world = world'.
	spawns do: [ :ref |
		| entityName pascal |
		entityName := (ref beginsWith: '@') ifTrue: [ ref allButFirst ] ifFalse: [ ref ].
		pascal := self toPascalCase: entityName.
		self nl.
		self emit: 'world.add_entity(' , pascal , '.new())' ].
	readyBody do: [ :e | self nl. self visitExpression: e ].
	self dedent. self nl. self nl.
	self emit: 'func _process(delta: float) -> void:'. self indent.
	self nl. self emit: 'ECS.process(delta)'.
	self dedent.
	inputBody notEmpty ifTrue: [
		self nl. self nl.
		self emit: 'func _input(event: InputEvent) -> void:'. self indent.
		inputBody do: [ :e | self nl. self visitExpression: e ].
		self dedent ]
]

{ #category : 'generating - GECS' }
GodotZealCodeGenerator >> generateDefsystem: aListNode [
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
GodotZealCodeGenerator >> generateDefsystemFull: bodyForms [
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

{ #category : 'generation' }
GodotZealCodeGenerator >> generateDefsystemShorthand: name components: compVector rest: restForms [
	"Shorthand: vector = with-all + iterate + auto-bind.
	 compVector entries: @comp or binding:@comp (colon chain).
	 restForms: optional query modifiers (with-none, enabled, etc.) + body expressions.
	 delta is always available as a binding in the body.
	 Emits explicit type annotations on bindings (Array[C_Foo], var x: C_Foo) so the
	 GDScript LSP can statically validate field accesses against the component's class."
	| compRefs bindings classNames queryMods bodyExprs |
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
	"Resolve each compRef once into its actual class name (e.g. health -> C_Health)"
	classNames := compRefs collect: [ :ref | self resolveClassRef: ref ].
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
	classNames do: [ :cls | self emit: cls ] separatedBy: [ self emit: ', ' ].
	self emit: ']).iterate(['.
	classNames do: [ :cls | self emit: cls ] separatedBy: [ self emit: ', ' ].
	self emit: '])'.
	queryMods do: [ :mod | self emitQueryClause: mod ].
	self dedent.
	"Emit process — typed bindings so the LSP can statically check field accesses"
	self nl. self nl.
	self emit: 'func process(entities: Array[Entity], components: Array, delta: float) -> void:'.
	self indent.
	"Bind component arrays with explicit Array[C_Foo] types"
	1 to: bindings size do: [ :idx |
		self nl.
		self emit: 'var ' , (bindings at: idx) , '_arr: Array[' , (classNames at: idx) , '] = []'. self nl. self emit: (bindings at: idx) , '_arr.assign(components[' , (idx - 1) printString , '])' ].
	"Loop"
	self nl.
	self emit: 'for _i in entities.size():'.
	self indent.
	self nl.
	self emit: 'var entity = entities[_i]'.
	bindings withIndexDo: [ :binding :idx |
		self nl.
		self emit: 'var ' , binding , ': ' , (classNames at: idx) , ' = ' , binding , '_arr[_i]' ].
	"Body"
	bodyExprs do: [ :e | self nl. self visitExpression: e ].
	self dedent.
	self dedent
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateDistinct: aListNode [
	^ self emitNullaryTransducer: 'distinct_' from: aListNode
]

{ #category : 'generating - control flow' }
GodotZealCodeGenerator >> generateDo: aListNode [
	"(do expr1 expr2 ...) -> sequential expressions"
	aListNode expressions allButFirst
		do: [ :e | self visitExpression: e ]
		separatedBy: [ self nl ]
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateDrop: aListNode [
	^ self emitTransducer: 'dropping' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateDropLast: aListNode [
	"(drop-last) -> Z.dropping_last() (drops last 1)
	 (drop-last n) -> Z.dropping_last(n)
	 (drop-last n xs) -> Z.into([], Z.dropping_last(n), xs)"
	| exprs |
	exprs := aListNode expressions.
	exprs size = 1 ifTrue: [
		self emit: 'Z.dropping_last()'.
		^ self ].
	exprs size = 2 ifTrue: [
		self emit: 'Z.dropping_last('.
		self visitExpression: exprs second.
		self emit: ')'.
		^ self ].
	"eager: (drop-last n xs)"
	self emit: 'Z.into([], Z.dropping_last('.
	self visitExpression: exprs second.
	self emit: '), '.
	self visitExpression: exprs third.
	self emit: ')'
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateDropWhile: aListNode [
	^ self emitTransducer: 'dropping_while' from: aListNode
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateEveryP: aListNode [
	"(every? pred xs) -> Z.every(pred, xs)"
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.every('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ')'
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateFilter: aListNode [
	^ self emitTransducer: 'filtering' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateFlatten: aListNode [
	^ self emitNullaryTransducer: 'flattening' from: aListNode
]

{ #category : 'generation' }
GodotZealCodeGenerator >> generateFn: aListNode [
	"(fn [params...] body...) -> func(params): body
	 The last body expression is implicitly returned (unless it's a statement-only
	 form like set/var/if/for/when/match which can't be the operand of return).
	 A single (do ...) body is unwrapped so the do's last child becomes the
	 implicit return.
	 Pushes a fresh scope frame containing the param names so calls in the body
	 referencing them route through .call instead of name(...)."
	| exprs params bodyExprs singleExpr |
	exprs := aListNode expressions.
	params := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	"Unwrap a top-level (do ...) so its children become the lambda body."
	(bodyExprs size = 1
		and: [ (bodyExprs first isKindOf: ZealListNode)
		and: [ bodyExprs first expressions notEmpty
		and: [ (bodyExprs first expressions first isKindOf: ZealSymbolNode)
		and: [ bodyExprs first expressions first value value = 'do' ] ] ] ]) ifTrue: [
			bodyExprs := bodyExprs first expressions allButFirst asOrderedCollection ].
	self emit: 'func('.
	params expressions
		do: [ :p | self emitParam: p ]
		separatedBy: [ self emit: ', ' ].
	self emit: '):'.
	self pushScope.
	[ params expressions do: [ :p | self bindLocal: (self paramName: p) ].
	  bodyExprs isEmpty
		ifTrue: [ self emit: ' pass' ]
		ifFalse: [
			singleExpr := bodyExprs size = 1 and: [ (self isStatementForm: bodyExprs first) not ].
			singleExpr
				ifTrue: [
					self emit: ' return '.
					self visitExpression: bodyExprs first ]
				ifFalse: [
					self indent.
					bodyExprs doWithIndex: [ :e :i |
						self nl.
						(i = bodyExprs size and: [ (self isStatementForm: e) not ])
							ifTrue: [ self emit: 'return '. self visitExpression: e ]
							ifFalse: [ self visitExpression: e ] ].
					self dedent ] ] ]
		ensure: [ self popScope ]
]

{ #category : 'generation' }
GodotZealCodeGenerator >> generateFor: aListNode [
	"(for [x coll] body...) -> for x in coll: body.
	 The loop variable enters scope for the duration of the body."
	| exprs bindingVec bodyExprs items loopVar |
	exprs := aListNode expressions.
	bindingVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	items := bindingVec expressions.
	loopVar := self toSnakeCase: items first value value.
	self emit: 'for '.
	self emit: loopVar.
	self emit: ' in '.
	self visitExpression: items second.
	self emit: ':'.
	self pushScope.
	[ self bindLocal: loopVar.
	  self indent.
	  bodyExprs do: [ :e | self nl. self visitExpression: e ].
	  self dedent ]
		ensure: [ self popScope ]
]

{ #category : 'generation' }
GodotZealCodeGenerator >> generateFunctionCall: aListNode [
	"(func args...) -> func(args)
	 Special cases:
	 - If func is in lexical scope or is a non-symbol expression → .call(args)
	 - If func is a transducer factory and the remaining args end with a source
	   (bare pipeline: ((filter pred) (map f) xs)) → auto-comp + into."
	| exprs head headStr |
	exprs := aListNode expressions.
	head := exprs first.
	headStr := nil.
	(head isKindOf: ZealSymbolNode) ifTrue: [ headStr := head value value ].
	"Bare pipeline detection: ((xform1) (xform2) ... source)
	 Head is a transducer factory call, last arg is the source."
	((self isTransducerFactory: head) and: [ exprs size >= 2 ]) ifTrue: [
		| xforms source compNode intoNode |
		source := exprs last.
		"Collect all transducer factory forms (head + middle args that are xforms)"
		xforms := OrderedCollection new.
		xforms add: head.
		2 to: exprs size - 1 do: [ :i |
			(self isTransducerFactory: (exprs at: i))
				ifTrue: [ xforms add: (exprs at: i) ] ].
		"Rewrite to (into [] (comp xforms...) source)"
		xforms size = 1
			ifTrue: [
				"Single xform: (into [] xform source)"
				intoNode := self syntheticList: {
					GodotZealCompiler newSymbolNodeWithString: 'into'.
					ZealVectorNode new instVarNamed: 'expressions' put: OrderedCollection new; yourself.
					xforms first.
					source }.
				^ self visitExpression: intoNode ]
			ifFalse: [
				"Multiple xforms: (into [] (comp xform1 xform2 ...) source)"
				compNode := self syntheticList: 
					((OrderedCollection with: (GodotZealCompiler newSymbolNodeWithString: 'comp'))
						addAll: xforms; yourself).
				intoNode := self syntheticList: {
					GodotZealCompiler newSymbolNodeWithString: 'into'.
					ZealVectorNode new instVarNamed: 'expressions' put: OrderedCollection new; yourself.
					compNode.
					source }.
				^ self visitExpression: intoNode ] ].
	"Standard function call"
	self visitExpression: head.
	((headStr isNil) or: [ self isLocal: (self toSnakeCase: headStr) ])
		ifTrue: [ self emit: '.call(' ]
		ifFalse: [ self emit: '(' ].
	exprs allButFirst
		do: [ :arg | self visitExpression: arg ]
		separatedBy: [ self emit: ', ' ].
	self emit: ')'
]

{ #category : 'generating - control flow' }
GodotZealCodeGenerator >> generateIf: aListNode [
	"(if cond then) or (if cond then else) or (if c1 t1 c2 t2 ... else)"
	| args |
	args := aListNode expressions allButFirst.
	self emitIfChain: args first: true
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateIndexed: aListNode [
	^ self emitNullaryTransducer: 'indexing' from: aListNode
]

{ #category : 'transducers-core' }
GodotZealCodeGenerator >> generateInterleave: aListNode [
	"(interleave xs ys ...) -> Z.interleave([xs, ys, ...]) — variadic, stops at shortest."
	| exprs args |
	exprs := aListNode expressions.
	args := exprs allButFirst.
	self emit: 'Z.interleave(['.
	args
		do: [ :a | self visitExpression: a ]
		separatedBy: [ self emit: ', ' ].
	self emit: '])'
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateInterpose: aListNode [
	^ self emitTransducer: 'interposing' from: aListNode
]

{ #category : 'transducers-core' }
GodotZealCodeGenerator >> generateInto: aListNode [
	"(into dest) -> dest.duplicate()
	 (into dest xs) -> Z.into(dest, identity, xs)
	 (into dest xform xs) -> tries fusion first; falls back to Z.into(dest, xform, xs).
	 Fusion emits a tight fused loop wrapped in an IIFE when all xforms in the
	 chain have inline fn bodies (no Callable overhead, no intermediate arrays)."
	| exprs |
	exprs := aListNode expressions.
	exprs size = 2 ifTrue: [
		self visitExpression: exprs second.
		self emit: '.duplicate()'.
		^ self ].
	exprs size = 3 ifTrue: [
		self emit: 'Z.into('.
		self visitExpression: exprs second.
		self emit: ', Z.mapping(func(x): return x), '.
		self visitExpression: exprs third.
		self emit: ')'.
		^ self ].
	"4-arg: (into dest xform xs) — try fusion"
	(self tryFuseInto: exprs third source: exprs fourth) ifTrue: [ ^ self ].
	"Fall back to Z.into"
	self emit: 'Z.into('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ', '.
	self visitExpression: exprs fourth.
	self emit: ')'
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateIntoArray: aListNode [
	^ self emitReducer: 'into_array' from: aListNode
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateIntoMap: aListNode [
	^ self emitReducer: 'into_map' from: aListNode
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateIntoString: aListNode [
	^ self emitReducer: 'into_string' from: aListNode
]

{ #category : 'transducers-sources' }
GodotZealCodeGenerator >> generateIterate: aListNode [
	"(iterate f x) -> Z.iterate_(f, x) — infinite iterator. Use take/into to bound."
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.iterate_('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ')'
]

{ #category : 'transducers-core' }
GodotZealCodeGenerator >> generateJuxt: aListNode [
	"(juxt f1 f2 ...) -> Z.juxt([f1, f2, ...]) — returns a Callable that applied
	 to a value yields [f1(x), f2(x), ...]."
	| exprs args |
	exprs := aListNode expressions.
	args := exprs allButFirst.
	self emit: 'Z.juxt(['.
	args
		do: [ :a | self visitExpression: a ]
		separatedBy: [ self emit: ', ' ].
	self emit: '])'
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateKeep: aListNode [
	^ self emitTransducer: 'keeping' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateKeepIndexed: aListNode [
	^ self emitTransducer: 'keeping_indexed' from: aListNode
]

{ #category : 'generation' }
GodotZealCodeGenerator >> generateLet: aListNode [
	"(let [var1 val1 var2 val2] body...) -> var declarations + body.
	 Each binding name is added to the current scope so subsequent calls to it
	 within the body emit .call(...) instead of name(...)."
	| exprs bindingVec bodyExprs items i |
	exprs := aListNode expressions.
	bindingVec := exprs second.
	bodyExprs := exprs allButFirst allButFirst.
	items := bindingVec expressions.
	i := 1.
	[ i + 1 <= items size ] whileTrue: [
		| nameNode valNode bindName |
		nameNode := items at: i.
		valNode := items at: i + 1.
		self emit: 'var '.
		(nameNode isKindOf: ZealColonChainNode) ifTrue: [
			| resolved |
			resolved := self resolveColonChain: nameNode value value.
			bindName := self toSnakeCase: (resolved at: #name).
			self emit: bindName.
			(resolved at: #type) ifNotNil: [ :t |
				self emit: ': '.
				self emit: (self resolveType: t) ] ]
		ifFalse: [
			bindName := self toSnakeCase: nameNode value value.
			self emit: bindName ].
		self emit: ' = '.
		self visitExpression: valNode.
		self bindLocal: bindName.
		self nl.
		i := i + 2 ].
	bodyExprs do: [ :e | self visitExpression: e ] separatedBy: [ self nl ]
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateMap: aListNode [
	^ self emitTransducer: 'mapping' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateMapcat: aListNode [
	^ self emitTransducer: 'mapcatting' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateMapcatIndexed: aListNode [
	^ self emitTransducer: 'mapcatting_indexed' from: aListNode
]

{ #category : 'generating - control flow' }
GodotZealCodeGenerator >> generateMatch: aListNode [
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

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateMax: aListNode [
	^ self emitReducer: 'max_of' from: aListNode
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateMin: aListNode [
	^ self emitReducer: 'min_of' from: aListNode
]

{ #category : 'generating - expressions' }
GodotZealCodeGenerator >> generateOperator: aListNode [
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

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateProduct: aListNode [
	^ self emitReducer: 'product' from: aListNode
]

{ #category : 'transducers-sources' }
GodotZealCodeGenerator >> generateRange: aListNode [
	"(range n) / (range a b) / (range a b s) -> built-in range(...) (eager Array)."
	| exprs args |
	exprs := aListNode expressions.
	args := exprs allButFirst.
	self emit: 'range('.
	args
		do: [ :a | self visitExpression: a ]
		separatedBy: [ self emit: ', ' ].
	self emit: ')'
]

{ #category : 'transducers-core' }
GodotZealCodeGenerator >> generateReduce: aListNode [
	"(reduce f xs) -> Z.reduce(f, null, xs)
	 (reduce f init xs) -> Z.reduce(f, init, xs)
	 Replaces the older Array.reduce(f) emission — now routes through the library
	 driver so iterators work as sources."
	| exprs |
	exprs := aListNode expressions.
	exprs size = 3 ifTrue: [
		self emit: 'Z.reduce('.
		self visitExpression: exprs second.
		self emit: ', null, '.
		self visitExpression: exprs third.
		self emit: ')'.
		^ self ].
	"3-arg: (reduce f init xs)"
	self emit: 'Z.reduce('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ', '.
	self visitExpression: exprs fourth.
	self emit: ')'
]

{ #category : 'transducers-sources' }
GodotZealCodeGenerator >> generateRepeat: aListNode [
	"(repeat x) -> Z.repeat_(x) — infinite iterator."
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.repeat_('.
	self visitExpression: exprs second.
	self emit: ')'
]

{ #category : 'generating - control flow' }
GodotZealCodeGenerator >> generateReturn: aListNode [
	"(return) -> return, (return expr) -> return expr"
	| exprs |
	exprs := aListNode expressions.
	self emit: 'return'.
	exprs size > 1 ifTrue: [
		self emit: ' '.
		self visitExpression: exprs second ]
]

{ #category : 'generating - definitions' }
GodotZealCodeGenerator >> generateSet: aListNode [
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
GodotZealCodeGenerator >> generateSetBang: aListNode [
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
GodotZealCodeGenerator >> generateSlashCall: aListNode [
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

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateSum: aListNode [
	^ self emitReducer: 'sum' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateTake: aListNode [
	^ self emitTransducer: 'taking' from: aListNode
]

{ #category : 'transducers' }
GodotZealCodeGenerator >> generateTakeWhile: aListNode [
	^ self emitTransducer: 'taking_while' from: aListNode
]

{ #category : 'transducers-reducers' }
GodotZealCodeGenerator >> generateTally: aListNode [
	^ self emitReducer: 'tally' from: aListNode
]

{ #category : 'threading' }
GodotZealCodeGenerator >> generateThreadFirst: aListNode [
	"(-> x (f a) (g b _)) — unified threading macro.
	 _ determines insertion point. If no _ in a form, auto-inserts as first arg.
	 Bare symbols wrap as (sym accumulated). Subsumes both -> and ->>."
	| exprs current |
	exprs := aListNode expressions allButFirst.
	current := exprs first.
	exprs allButFirst do: [ :form |
		(form isKindOf: ZealListNode)
			ifTrue: [
				(self threadFormHasPlaceholder: form)
					ifTrue: [
						"Substitute every _ with current"
						current := self threadSubstitute: form with: current ]
					ifFalse: [
						"No _ — auto-insert as first arg (after function name)"
						| newExprs |
						newExprs := OrderedCollection new.
						newExprs add: form expressions first.
						newExprs add: current.
						newExprs addAll: form expressions allButFirst.
						current := self syntheticList: newExprs ] ]
			ifFalse: [
				"Bare symbol — wrap as (form current)"
				current := self syntheticList: { form. current } ] ].
	self visitExpression: current
]

{ #category : 'transducers-core' }
GodotZealCodeGenerator >> generateTransduce: aListNode [
	"(transduce xform rf init xs) -> Z.transduce(xform, rf, init, xs)
	 The rf must be a reducer Dictionary {step,complete}, typically built via
	 Z.append_rf() or hand-rolled in user code."
	| exprs |
	exprs := aListNode expressions.
	self emit: 'Z.transduce('.
	self visitExpression: exprs second.
	self emit: ', '.
	self visitExpression: exprs third.
	self emit: ', '.
	self visitExpression: exprs fourth.
	self emit: ', '.
	self visitExpression: (exprs at: 5).
	self emit: ')'
]

{ #category : 'generating - definitions' }
GodotZealCodeGenerator >> generateVar: aListNode [
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
GodotZealCodeGenerator >> generateWhen: aListNode [
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
GodotZealCodeGenerator >> indent [
	indentLevel := indentLevel + 1
]

{ #category : 'initialization' }
GodotZealCodeGenerator >> initialize [
	stream := WriteStream on: String new.
	indentLevel := 0.
	registry := GodotZealComponentRegistry new.
	localScope := OrderedCollection new.
	localScope add: Set new.
	fusionSubs := Dictionary new
]

{ #category : 'scope' }
GodotZealCodeGenerator >> isLocal: aName [
	"True if aName is bound in any currently-visible scope frame."
	aName ifNil: [ ^ false ].
	^ localScope anySatisfy: [ :frame | frame includes: aName asString ]
]

{ #category : 'private' }
GodotZealCodeGenerator >> isOperator: aString [
	^ #('+' '-' '*' '%' '=' '<>' '<' '>' '<=' '>=' 'and' 'or' 'not' '+=' '-=' '*=' '/=') includes: aString
]

{ #category : 'generation' }
GodotZealCodeGenerator >> isStatementForm: aNode [
	"True if aNode is a special form that emits as a GDScript statement (not an
	 expression) and therefore can't be the operand of `return`."
	| head |
	(aNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	aNode expressions isEmpty ifTrue: [ ^ false ].
	head := aNode expressions first.
	(head isKindOf: ZealSymbolNode) ifFalse: [ ^ false ].
	^ #('set' 'var' 'if' 'when' 'for' 'while' 'match' 'do' 'return') includes: head value value
]

{ #category : 'threading' }
GodotZealCodeGenerator >> isTransducerFactory: aNode [
	"True if aNode is a (transducer-name arg...) form that returns an xform Callable."
	| head headStr |
	(aNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	aNode expressions isEmpty ifTrue: [ ^ false ].
	head := aNode expressions first.
	(head isKindOf: ZealSymbolNode) ifFalse: [ ^ false ].
	headStr := head value value.
	^ (ZealCodeGenerator transducerFormSelectors includesKey: headStr)
		and: [ "Only the xform-returning arities (no collection as last arg)"
			   aNode expressions size <= 3 "most factories are 1-2 args" ]
]

{ #category : 'emitting' }
GodotZealCodeGenerator >> nl [
	stream nextPutAll: String crlf.
	self emitIndent
]

{ #category : 'accessing' }
GodotZealCodeGenerator >> output [
	^ stream contents
]

{ #category : 'generation' }
GodotZealCodeGenerator >> paramName: aNode [
	"Snake-cased name of a parameter node, stripping any colon-chain type annotation."
	(aNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := self resolveColonChain: aNode value value.
		^ self toSnakeCase: (resolved at: #name) ].
	^ self toSnakeCase: aNode value value
]

{ #category : 'scope' }
GodotZealCodeGenerator >> popScope [
	localScope size > 1 ifTrue: [ localScope removeLast ]
]

{ #category : 'scope' }
GodotZealCodeGenerator >> pushScope [
	"Push a fresh local-scope frame. Names bound while this frame is on top are
	 visible until the matching popScope."
	localScope add: Set new
]

{ #category : 'accessing' }
GodotZealCodeGenerator >> registry [
	^ registry
]

{ #category : 'generation' }
GodotZealCodeGenerator >> resolveClassRef: aString [
	"Resolve @name -> class name. Strip @, PascalCase. Only add C_ prefix for
	 names that are registered as GECS components. Unregistered names (Godot
	 built-ins like Vector2, Color, Node2D) are returned as-is."
	| name |
	name := aString allButFirst. "strip @"
	^ registry resolve: name
]

{ #category : 'private - types' }
GodotZealCodeGenerator >> resolveColonChain: aString [
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
GodotZealCodeGenerator >> resolveType: aTypeString [
	"Map GDZeal type names to GDScript types.
	 int -> int, float -> float, string -> String, bool -> bool,
	 void -> void, @class refs resolved via registry"
	aTypeString ifNil: [ ^ nil ].
	(aTypeString beginsWith: '@') ifTrue: [ ^ self resolveClassRef: aTypeString ].
	aTypeString = 'string' ifTrue: [ ^ 'String' ].
	^ aTypeString
]

{ #category : 'accessing' }
GodotZealCodeGenerator >> setRegistry: aRegistry [
	registry := aRegistry
]

{ #category : 'generation' }
GodotZealCodeGenerator >> specialForms [
	"Dialect-local special forms + transducer protocol + threading macro."
	| dict |
	dict := Dictionary new
		at: 'def' put: #generateDef:;
		at: 'var' put: #generateVar:;
		at: 'set' put: #generateSet:;
		at: 'defn' put: #generateDefn:;
		at: 'defcomp' put: #generateDefcomp:;
		at: 'defcosystem' put: #generateDefcosystem:;
		at: 'defco' put: #generateDefco:;
		at: 'defentity' put: #generateDefentity:;
		at: 'defsystem' put: #generateDefsystem:;
		at: 'defobserver' put: #generateDefobserver:;
		at: 'defscene' put: #generateDefscene:;
		at: 'fn' put: #generateFn:;
		at: 'if' put: #generateIf:;
		at: 'when' put: #generateWhen:;
		at: 'for' put: #generateFor:;
		at: 'let' put: #generateLet:;
		at: 'match' put: #generateMatch:;
		at: 'do' put: #generateDo:;
		at: 'return' put: #generateReturn:;
		at: 'as' put: #generateAs:;
		at: '->' put: #generateThreadFirst:;
		yourself.
	ZealCodeGenerator transducerFormSelectors keysAndValuesDo: [ :name :sel |
		dict at: name put: sel ].
	^ dict
]

{ #category : 'threading' }
GodotZealCodeGenerator >> syntheticList: exprsArray [
	"Build a ZealListNode from an array of child AST nodes."
	| list |
	list := ZealListNode new.
	list instVarNamed: 'expressions' put: exprsArray asOrderedCollection.
	^ list
]

{ #category : 'threading' }
GodotZealCodeGenerator >> threadFormHasPlaceholder: aListNode [
	"True if any direct child of the list is the symbol _"
	^ aListNode expressions anySatisfy: [ :e |
		(e isKindOf: ZealSymbolNode) and: [ e value value = '_' ] ]
]

{ #category : 'threading' }
GodotZealCodeGenerator >> threadSubstitute: aListNode with: replacement [
	"Return a new synthetic list where every _ symbol child is replaced with replacement."
	| newExprs |
	newExprs := aListNode expressions collect: [ :e |
		((e isKindOf: ZealSymbolNode) and: [ e value value = '_' ])
			ifTrue: [ replacement ]
			ifFalse: [ e ] ].
	^ self syntheticList: newExprs
]

{ #category : 'private - naming' }
GodotZealCodeGenerator >> toPascalCase: aString [
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
GodotZealCodeGenerator >> toSnakeCase: aString [
	"kebab-case -> snake_case"
	^ aString copyReplaceAll: '-' with: '_'
]

{ #category : 'fusion' }
GodotZealCodeGenerator >> tryFuseInto: xformNode source: sourceNode [
	"Try to emit a fused loop for (into [] xform source). Returns true if fusion
	 succeeded, false if the caller should fall back to Z.into(). The fused output
	 is wrapped in an IIFE so it works as an expression anywhere."
	| xforms chain hasTake |
	"Extract the xform chain — either a single xform or (comp xform1 xform2 ...)"
	(xformNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	((xformNode expressions first isKindOf: ZealSymbolNode)
		and: [ xformNode expressions first value value = 'comp' ])
		ifTrue: [ xforms := xformNode expressions allButFirst ]
		ifFalse: [ xforms := { xformNode } ].
	"Classify each xform — bail if any non-fusible"
	chain := xforms collect: [ :xf | self classifyXform: xf ].
	(chain anySatisfy: [ :c | c isNil ]) ifTrue: [ ^ false ].
	"Emit the fused IIFE"
	hasTake := chain anySatisfy: [ :c | (c at: #kind) = 'take' or: [ (c at: #kind) = 'take-while' ] ].
	self emit: '(func():'.
	self indent.
	self nl. self emit: 'var _r: Array = []'.
	"State variable declarations"
	chain withIndexDo: [ :desc :i |
		| kind |
		kind := desc at: #kind.
		kind = 'take' ifTrue: [ self nl. self emit: 'var _tk' , i printString , ': int = 0' ].
		kind = 'drop' ifTrue: [ self nl. self emit: 'var _dk' , i printString , ': int = 0' ].
		kind = 'drop-while' ifTrue: [ self nl. self emit: 'var _dw' , i printString , ': bool = true' ].
		kind = 'distinct' ifTrue: [ self nl. self emit: 'var _seen' , i printString , ': Dictionary = {}' ].
		kind = 'dedupe' ifTrue: [ self nl. self emit: 'var _prev' , i printString , ' = null'. self nl. self emit: 'var _hprev' , i printString , ': bool = false' ].
		kind = 'indexed' ifTrue: [ self nl. self emit: 'var _idx' , i printString , ': int = 0' ] ].
	self nl. self emit: 'for _v in '.
	self visitExpression: sourceNode.
	self emit: ':'.
	self indent.
	"Pipeline steps"
	chain withIndexDo: [ :desc :i |
		self emitFusionStep: desc index: i ].
	"Terminal: append (take handles its own append+break)"
	hasTake ifFalse: [
		self nl. self emit: '_r.append(_v)' ].
	self dedent.
	self nl. self emit: 'return _r'.
	self dedent.
	self emit: ').call()'.
	^ true
]

{ #category : 'generation' }
GodotZealCodeGenerator >> visitAtom: aNode [
	"Handle atoms: @class refs, /slash access, symbols, keywords, literals.
	 Fusion substitutions are checked for symbols — when a lambda param has been
	 renamed to _pN during loop fusion, the substitution fires here."
	| sym |
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		sym := aNode value value.
		"@ class reference (may contain / for static access)"
		(sym beginsWith: '@') ifTrue: [
			(sym includes: $/) ifTrue: [
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
		"Fusion substitution: lambda param renamed to _pN during loop fusion"
		(self fusionSubstitutions at: sym ifAbsent: [ nil ]) ifNotNil: [ :sub |
			self emit: sub. ^ self ].
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
GodotZealCodeGenerator >> visitExpression: aNode [
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self visitList: aNode ].
	(aNode isKindOf: ZealVectorNode) ifTrue: [ ^ self visitVector: aNode ].
	(aNode isKindOf: ZealMapNode) ifTrue: [ ^ self visitMap: aNode ].
	^ self visitAtom: aNode
]

{ #category : 'visiting' }
GodotZealCodeGenerator >> visitList: aNode [
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
GodotZealCodeGenerator >> visitMap: aNode [
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
GodotZealCodeGenerator >> visitVector: aNode [
	"[a b c] -> [a, b, c]"
	self emit: '['.
	aNode expressions
		do: [ :e | self visitExpression: e ]
		separatedBy: [ self emit: ', ' ].
	self emit: ']'
]

{ #category : 'fusion' }
GodotZealCodeGenerator >> withSubstitution: originalName as: newName do: aBlock [
	"Temporarily register a symbol substitution so that visitAtom: emits newName
	 whenever it encounters originalName. Used by the fusion pass to rename lambda
	 params to unique _pN names."
	| subs |
	(originalName isNil or: [ newName isNil ]) ifTrue: [ ^ aBlock value ].
	subs := self fusionSubstitutions.
	subs at: originalName put: newName.
	[ aBlock value ] ensure: [ subs removeKey: originalName ifAbsent: [] ]
]
