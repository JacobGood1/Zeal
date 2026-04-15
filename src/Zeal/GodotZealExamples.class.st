Class {
	#name : 'GodotZealExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'examples - class refs' }
GodotZealExamples >> exampleClassRefBuiltin [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '@node2D'.
	self assert: result trimBoth equals: 'Node2D'.
	^ result
]

{ #category : 'examples - class refs' }
GodotZealExamples >> exampleClassRefComponent [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	result := gen generate: (ZealParser parse: '@health').
	self assert: result trimBoth equals: 'C_Health'.
	^ result
]

{ #category : 'examples - class refs' }
GodotZealExamples >> exampleClassRefKebab [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '@some-class'.
	self assert: result trimBoth equals: 'SomeClass'.
	^ result
]

{ #category : 'examples - definitions' }
GodotZealExamples >> exampleDef [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(def max-hp:int 100)'.
	self assert: result trimBoth equals: 'const max_hp: int = 100'.
	^ result
]

{ #category : 'examples - defco' }
GodotZealExamples >> exampleDefcoArityMismatch [
	<gtExample>
	"Calling a coroutine with the wrong number of args emits push_error, not silent miscompile."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defco greet [name] (print name))
(defcosystem test (greet "alice" "bob"))'.
	self assert: (result includesSubstring: 'push_error').
	self assert: (result includesSubstring: 'arity_mismatch_greet').
	^ result
]

{ #category : 'examples - defco' }
GodotZealExamples >> exampleDefcoNested [
	<gtExample>
	"A coroutine that calls another coroutine fully expands at compile time."
	| result count i pat |
	result := GodotZealCompiler compileToGDScript: '(defco beep (print "beep") (wait 0.1))
(defco double-beep (beep) (beep))
(defcosystem test (double-beep) (print "done"))'.
	"Two beeps inlined plus final print = three states"
	pat := 'print("beep")'.
	count := 0. i := 1.
	[ i := result indexOfSubCollection: pat startingAt: i. i > 0 ] whileTrue: [
		count := count + 1. i := i + pat size ].
	self assert: count equals: 2.
	self assert: (result includesSubstring: 'print("done")').
	self assert: (result includesSubstring: '_state == 0').
	self assert: (result includesSubstring: '_state == 1').
	self assert: (result includesSubstring: '_state == 2').
	^ result
]

{ #category : 'examples - defco' }
GodotZealExamples >> exampleDefcoRecursionGuard [
	<gtExample>
	"A directly recursive coroutine should NOT hang the compiler — it must emit a
	 push_error placeholder so the misuse surfaces at runtime."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defco a (a))
(defcosystem test (a))'.
	self assert: (result includesSubstring: 'push_error').
	self assert: (result includesSubstring: 'recursive_coroutine_a').
	^ result
]

{ #category : 'examples - defco' }
GodotZealExamples >> exampleDefcoSimple [
	<gtExample>
	"A no-arg coroutine inlines its body into the calling defcosystem."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defco greet (print "hi") (wait 1))
(defcosystem test (greet) (print "done"))'.
	self assert: (result includesSubstring: 'print("hi")').
	self assert: (result includesSubstring: '_timer = 1').
	self assert: (result includesSubstring: 'print("done")').
	self assert: (result includesSubstring: '_state == 0').
	self assert: (result includesSubstring: '_state == 1').
	self assert: (result includesSubstring: '_state = 1').
	^ result
]

{ #category : 'examples - defco' }
GodotZealExamples >> exampleDefcoWithParams [
	<gtExample>
	"A coroutine with parameters substitutes them into the inlined body."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defco wait-and-print [msg seconds] (print msg) (wait seconds))
(defcosystem test (wait-and-print "start" 0.5) (wait-and-print "end" 1.0) (print "done"))'.
	self assert: (result includesSubstring: 'print("start")').
	self assert: (result includesSubstring: 'print("end")').
	self assert: (result includesSubstring: 'print("done")').
	self assert: (result includesSubstring: '_timer = 0.5').
	self assert: (result includesSubstring: '_timer = 1.0').
	"Three states: two waits + final print"
	self assert: (result includesSubstring: '_state == 0').
	self assert: (result includesSubstring: '_state == 1').
	self assert: (result includesSubstring: '_state == 2').
	^ result
]

{ #category : 'examples - components' }
GodotZealExamples >> exampleDefcompFields [
	<gtExample>
	"Standard (defcomp name field val ...) produces a Component class with @export fields."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcomp velocity
  direction @vector2/RIGHT
  speed:float 200.0)'.
	self assert: (result includesSubstring: 'class_name C_Velocity').
	self assert: (result includesSubstring: '@export var direction: Vector2 = Vector2.RIGHT').
	self assert: (result includesSubstring: '@export var speed: float = 200.0').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefcompHealth [
	<gtExample>
	| source result |
	source := '(defcomp health
  current:float 100.0
  maximum:float 100.0
  (init [max-health:float 100.0]
    (set maximum max-health)
    (set current max-health)))'.
	result := GodotZealCodeGenerator compile: source.
	self assert: (result includesSubstring: 'class_name C_Health').
	self assert: (result includesSubstring: 'extends Component').
	self assert: (result includesSubstring: '@export var current: float = 100.0').
	self assert: (result includesSubstring: '@export var maximum: float = 100.0').
	self assert: (result includesSubstring: 'func _init(max_health: float = 100.0):').
	self assert: (result includesSubstring: 'maximum = max_health').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefcompShorthand [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defcomp health
  current:float 100.0
  maximum:float 100.0)'.
	self assert: (result includesSubstring: 'class_name C_Health').
	self assert: (result includesSubstring: '@export var current: float = 100.0').
	self assert: (result includesSubstring: '@export var maximum: float = 100.0').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefcompShorthandClassType [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defcomp velocity
  direction:@vector2 @vector2/RIGHT
  speed:float 200.0)'.
	self assert: (result includesSubstring: '@export var direction: Vector2 = Vector2.RIGHT').
	self assert: (result includesSubstring: '@export var speed: float = 200.0').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefcompShorthandWithInit [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defcomp health
  current:float 100.0
  maximum:float 100.0
  (init [max-health:float 100.0]
    (set maximum max-health)
    (set current max-health)))'.
	self assert: (result includesSubstring: '@export var current: float = 100.0').
	self assert: (result includesSubstring: 'func _init(max_health: float = 100.0):').
	self assert: (result includesSubstring: 'maximum = max_health').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefcompTag [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defcomp dead)'.
	self assert: (result includesSubstring: 'class_name C_Dead').
	self assert: (result includesSubstring: 'extends Component').
	self assert: (result includesSubstring: '@export') not.
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefentity [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	gen registry register: 'velocity'.
	result := gen generate: (ZealParser parse: '(defentity player
  (components [@health @velocity])
  (on-ready (print "Player spawned"))
  (on-destroy (print "Player destroyed")))').
	self assert: (result includesSubstring: '@tool').
	self assert: (result includesSubstring: 'class_name Player').
	self assert: (result includesSubstring: 'extends Entity').
	self assert: (result includesSubstring: 'C_Health.new(), C_Velocity.new()').
	self assert: (result includesSubstring: 'func on_ready() -> void:').
	self assert: (result includesSubstring: 'func on_destroy() -> void:').
	^ result
]

{ #category : 'examples - definitions' }
GodotZealExamples >> exampleDefn [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defn apply-damage [entity:@entity amount:float] :void
  (let [health (entity/get-component @health)]
    (set health/current (- health/current amount))))'.
	self assert: (result includesSubstring: 'func apply_damage(entity: Entity, amount: float) -> void:').
	self assert: (result includesSubstring: 'var health = entity.get_component(Health)').
	self assert: (result includesSubstring: 'health.current = health.current - amount').
	^ result
]

{ #category : 'examples - definitions' }
GodotZealExamples >> exampleDefnNoReturn [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defn greet [name:string]
  (print name))'.
	self assert: (result includesSubstring: 'func greet(name: String):').
	self assert: (result includesSubstring: '-> ') not.
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefobserver [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	result := gen generate: (ZealParser parse: '(defobserver health-observer
  (watch @health)
  (match (with-all [@health]))
  (on-changed [entity comp prop new-val old-val]
    (when (and (= prop "health") (< new-val 20))
      (print "Low health!"))))').
	self assert: (result includesSubstring: 'class_name O_HealthObserver').
	self assert: (result includesSubstring: 'extends Observer').
	self assert: (result includesSubstring: 'return C_Health').
	self assert: (result includesSubstring: 'func on_component_changed(entity: Entity, comp: Resource, prop: String, new_val: Variant, old_val: Variant) -> void:').
	self assert: (result includesSubstring: 'prop == "health" and new_val < 20').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefsystem [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'velocity'.
	result := gen generate: (ZealParser parse: '(defsystem movement-system
  (query (with-all [@velocity]))
  (process [entities _ delta]
    (for [e entities]
      (let [vel (e/get-component @velocity)]
        (+= (as e @node2D position)
            (* vel/direction vel/speed delta))))))').
	self assert: (result includesSubstring: 'class_name MovementSystem').
	self assert: (result includesSubstring: 'extends System').
	self assert: (result includesSubstring: 'q.with_all([C_Velocity])').
	self assert: (result includesSubstring: 'func process(entities: Array[Entity], _components: Array, delta: float) -> void:').
	self assert: (result includesSubstring: 'e.get_component(C_Velocity)').
	self assert: (result includesSubstring: '(e as Node2D).position').
	^ result
]

{ #category : 'examples - defsystem shorthand' }
GodotZealExamples >> exampleDefsystemFullFormStillWorks [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'velocity'.
	result := gen generate: (ZealParser parse: '(defsystem movement-system
  (query (with-all [@velocity]))
  (process [entities _ delta]
    (for [e entities]
      (let [vel (e/get-component @velocity)]
        (print vel/speed)))))').
	self assert: (result includesSubstring: 'func process(entities: Array[Entity], _components: Array, delta: float)').
	self assert: (result includesSubstring: 'for e in entities:').
	self assert: (result includesSubstring: 'e.get_component(C_Velocity)').
	^ result
]

{ #category : 'examples - defsystem shorthand' }
GodotZealExamples >> exampleDefsystemShorthandAutoName [
	<gtExample>
	"@health auto-binds to variable 'health'"
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	result := gen generate: (ZealParser parse: '(defsystem simple [@health]
  (print health/current))').
	self assert: (result includesSubstring: 'var health = health_arr[_i]').
	self assert: (result includesSubstring: 'print(health.current)').
	^ result
]

{ #category : 'examples - defsystem shorthand' }
GodotZealExamples >> exampleDefsystemShorthandEntityAccess [
	<gtExample>
	"entity variable is always available in shorthand"
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	result := gen generate: (ZealParser parse: '(defsystem cleanup [@health]
  (when (<= health/current 0)
    (cmd/remove-entity entity)))').
	self assert: (result includesSubstring: 'var entity = entities[_i]').
	self assert: (result includesSubstring: 'cmd.remove_entity(entity)').
	^ result
]

{ #category : 'examples - defsystem shorthand' }
GodotZealExamples >> exampleDefsystemShorthandMulti [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'velocity'.
	gen registry register: 'position'.
	result := gen generate: (ZealParser parse: '(defsystem movement-system [vel:@velocity pos:@position]
  (set pos/x += (* vel/direction/x vel/speed delta)))').
	self assert: (result includesSubstring: 'q.with_all([C_Velocity, C_Position]).iterate([C_Velocity, C_Position])').
	self assert: (result includesSubstring: 'var vel_arr = components[0]').
	self assert: (result includesSubstring: 'var pos_arr = components[1]').
	self assert: (result includesSubstring: 'var vel = vel_arr[_i]').
	self assert: (result includesSubstring: 'var pos = pos_arr[_i]').
	self assert: (result includesSubstring: 'pos.x += vel.direction.x * vel.speed * delta').
	^ result
]

{ #category : 'examples - defsystem shorthand' }
GodotZealExamples >> exampleDefsystemShorthandSingle [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	result := gen generate: (ZealParser parse: '(defsystem health-drain-system [@health]
  (when (> health/current 0)
    (set health/current -= 1)))').
	self assert: (result includesSubstring: 'class_name HealthDrainSystem').
	self assert: (result includesSubstring: 'q.with_all([C_Health]).iterate([C_Health])').
	self assert: (result includesSubstring: 'var health_arr = components[0]').
	self assert: (result includesSubstring: 'var health = health_arr[_i]').
	self assert: (result includesSubstring: 'health.current -= 1').
	^ result
]

{ #category : 'examples - defsystem shorthand' }
GodotZealExamples >> exampleDefsystemShorthandWithModifiers [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	gen registry register: 'dead'.
	result := gen generate: (ZealParser parse: '(defsystem regen-system [@health]
  (with-none [@dead])
  (enabled)
  (set health/current += 1))').
	self assert: (result includesSubstring: '.with_none([C_Dead])').
	self assert: (result includesSubstring: '.enabled()').
	self assert: (result includesSubstring: 'health.current += 1').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefsystemWithDeps [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'velocity'.
	gen registry register: 'position'.
	result := gen generate: (ZealParser parse: '(defsystem render-system
  (query (with-all [@velocity @position]) (iterate [@velocity @position]))
  (deps {:after [@physics-system] :before [@ui-system]})
  (process [entities components delta]
    (print "rendering")))').
	self assert: (result includesSubstring: 'class_name RenderSystem').
	self assert: (result includesSubstring: '.with_all([C_Velocity, C_Position])').
	self assert: (result includesSubstring: '.iterate([C_Velocity, C_Position])').
	self assert: (result includesSubstring: 'Runs.After: [PhysicsSystem]').
	self assert: (result includesSubstring: 'Runs.Before: [UiSystem]').
	^ result
]

{ #category : 'examples - GECS' }
GodotZealExamples >> exampleDefsystemWithSetup [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(defsystem init-system
  (query (with-all [@velocity]) (enabled))
  (setup (print "system ready"))
  (process [entities _ delta]
    (print "processing")))'.
	self assert: (result includesSubstring: 'func setup() -> void:').
	self assert: (result includesSubstring: 'print("system ready")').
	self assert: (result includesSubstring: '.enabled()').
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleDo [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(do (print "a") (print "b"))'.
	self assert: (result includesSubstring: 'print("a")').
	self assert: (result includesSubstring: 'print("b")').
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleFor [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(for [item items] (process item))'.
	self assert: (result includesSubstring: 'for item in items:').
	self assert: (result includesSubstring: 'process(item)').
	^ result
]

{ #category : 'examples' }
GodotZealExamples >> exampleFsmDetectsFsmSource [
	<gtExample>
	"isDefcosystem: detects the defcosystem form"
	self assert: (GodotZealCompiler isDefcosystem: '(defcosystem kek (loop (wait)))').
	self assert: (GodotZealCompiler isDefcosystem: '(defcomp velocity speed:float 200.0)') not.
	self assert: (GodotZealCompiler isDefcosystem: '(defcomp dead)') not.
	^ true
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmEmpty [
	<gtExample>
	"FSM with no body — just generates the class header and state field."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem ticker)'.
	self assert: (result includesSubstring: 'class_name C_Ticker').
	self assert: (result includesSubstring: '@export var _state: int = 0').
	self assert: (result includesSubstring: '@export var _timer: float = 0.0').
	self assert: (result includesSubstring: 'func tick(entity: Entity, delta: float) -> void:').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmIfInline [
	<gtExample>
	"(if cond then else) without waits compiles to a single inline if/else."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem simple
  (loop
    (wait 1.0)
    (if (> hp 0) (heal) (die))))'.
	self assert: (result includesSubstring: 'if hp > 0:').
	self assert: (result includesSubstring: 'heal()').
	self assert: (result includesSubstring: 'die()').
	self assert: (result includesSubstring: '_state = 2') not.
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmIfWithWait [
	<gtExample>
	"(if cond then else) where then has a wait — splits into branch states."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem boss
  (loop
    (if low-health
      (do (wait 0.5) (panic-attack))
      (do (wait 2.0) (normal-attack)))))'.
	self assert: (result includesSubstring: 'if low_health:').
	self assert: (result includesSubstring: 'panic_attack()').
	self assert: (result includesSubstring: 'normal_attack()').
	self assert: (result includesSubstring: '_timer = 0.5').
	self assert: (result includesSubstring: '_timer = 2.0').
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmLaneTerminalRunsOnce [
	<gtExample>
	"Lane final stmts must run exactly once: emitted state advances to the sentinel
	 (laneStates size), and the inline done check is _state >= sentinel."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem one
  (sync
    (do (wait 0.5) (boom))))'.
	self assert: (result includesSubstring: 'boom()').
	self assert: (result includesSubstring: '_l0_state = 2').
	self assert: (result includesSubstring: 'var d_l0 = _l0_state >= 2').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmLoop [
	<gtExample>
	"(loop body) makes the last state jump back to the loop start."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem ticker
  (loop
    (wait)
    (tick-once)))'.
	self assert: (result includesSubstring: 'tick_once()').
	self assert: (result includesSubstring: '_state = 0').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmMultipleBindings [
	<gtExample>
	"defcosystem with multiple bindings — all appear as tick parameters."
	| reg result |
	reg := GodotZealComponentRegistry new.
	reg register: 'health'.
	reg register: 'velocity'.
	result := GodotZealCodeGenerator compile: '(defcosystem ai [health:@health vel:@velocity]
  (loop
    (when (< health/current 10)
      (set vel/speed 0.0))
    (wait 0.5)))' withRegistry: reg.
	self assert: (result includesSubstring: 'func tick(entity: Entity, delta: float, health: C_Health, vel: C_Velocity)').
	self assert: (result includesSubstring: 'health.current < 10').
	self assert: (result includesSubstring: 'vel.speed = 0.0').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmNoBindings [
	<gtExample>
	"defcosystem without bindings still works — tick(entity, delta) only."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem tick-only
  (loop
    (wait 1.0)
    (do-thing)))'.
	self assert: (result includesSubstring: 'func tick(entity: Entity, delta: float) -> void:').
	self assert: (result includesSubstring: 'do_thing()').
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmRaceFirstWins [
	<gtExample>
	"(race ...) short-circuits — once any lane finishes, remaining lanes are skipped.
	 The generated code uses a _won flag with 'if not _won:' guards rather than
	 ticking all lanes and joining with 'or'."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem racer
  (race
    (do (wait 0.5) (fast))
    (do (wait 5.0) (slow))))'.
	self assert: (result includesSubstring: 'var _won = false').
	self assert: (result includesSubstring: 'if not _won:').
	self assert: (result includesSubstring: '_won = true').
	self assert: (result includesSubstring: 'if _won:').
	self assert: (result includesSubstring: 'fast()').
	self assert: (result includesSubstring: 'slow()').
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmRaceThreeLanes [
	<gtExample>
	"3-lane race generates three nested 'if not _won:' guards, ensuring each later lane
	 is skipped once any earlier one finishes."
	| result wonGuardCount |
	result := GodotZealCompiler compileToGDScript: '(defcosystem three-way
  (race
    (do (wait 0.3) (a))
    (do (wait 0.6) (b))
    (do (wait 0.9) (c))))'.
	wonGuardCount := (result substrings: String cr) inject: 0 into: [ :sum :ln |
		(ln includesSubstring: 'if not _won:') ifTrue: [ sum + 1 ] ifFalse: [ sum ] ].
	self assert: wonGuardCount = 3.
	self assert: (result includesSubstring: 'a()').
	self assert: (result includesSubstring: 'b()').
	self assert: (result includesSubstring: 'c()').
	self assert: (result includesSubstring: '_l0_state').
	self assert: (result includesSubstring: '_l1_state').
	self assert: (result includesSubstring: '_l2_state').
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmRaceTiedFrameLoserSkipped [
	<gtExample>
	"In a tie (both lanes finishing on the same frame), the FIRST DECLARED lane wins
	 and the loser's body must NOT execute. The structural guarantee is that each lane's
	 body is inside an 'if not _won:' guard, so once lane 0 sets _won, lane 1's if/elif
	 chain is skipped entirely."
	| result lines lane1Idx wonAssignIdx |
	result := GodotZealCompiler compileToGDScript: '(defcosystem tied
  (race
    (do (wait 0.5) (winner))
    (do (wait 0.5) (loser))))'.
	self assert: (result includesSubstring: 'winner()').
	self assert: (result includesSubstring: 'loser()').
	lines := result lines.
	lane1Idx := lines findFirst: [ :ln | ln includesSubstring: 'loser()' ].
	self assert: lane1Idx > 0.
	wonAssignIdx := 0.
	(lane1Idx - 1 to: 1 by: -1) do: [ :j |
		(wonAssignIdx = 0 and: [ (lines at: j) includesSubstring: 'if not _won:' ])
			ifTrue: [ wonAssignIdx := j ] ].
	self assert: wonAssignIdx > 0.
	self assert: ((1 to: wonAssignIdx) anySatisfy: [ :j | (lines at: j) includesSubstring: '_won = true' ]).
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmSyncResetsLanesOnAdvance [
	<gtExample>
	"When a sync controller advances out, it resets each lane's state and timer
	 so re-entry (e.g. via loop) starts clean."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem cycler
  (loop
    (sync
      (do (wait 0.5) (a))
      (do (wait 0.5) (b)))
    (after)))'.
	"Reset assignments under the controller's join branch"
	self assert: (result includesSubstring: '_l0_state = 0').
	self assert: (result includesSubstring: '_l0_timer = 0.0').
	self assert: (result includesSubstring: '_l1_state = 0').
	self assert: (result includesSubstring: '_l1_timer = 0.0').
	"After-sync code runs in a follow-up state"
	self assert: (result includesSubstring: 'after()').
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmSyncTwoBranches [
	<gtExample>
	"(sync ...) generates per-lane state fields and inlines each lane's state machine
	 directly into the controller arm — no helper functions."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem dual
  (sync
    (do (wait 0.5) (a))
    (do (wait 1.0) (b))))'.
	self assert: (result includesSubstring: '_l0_state').
	self assert: (result includesSubstring: '_l1_state').
	self assert: (result includesSubstring: '_l0_timer').
	self assert: (result includesSubstring: '_l1_timer').
	self assert: (result includesSubstring: 'func _tick_l') not.
	self assert: (result includesSubstring: 'if _l0_state == 0:').
	self assert: (result includesSubstring: 'if _l1_state == 0:').
	self assert: (result includesSubstring: 'var d_l0 = _l0_state >=').
	self assert: (result includesSubstring: 'var d_l1 = _l1_state >=').
	self assert: (result includesSubstring: 'if d_l0 and d_l1').
	self assert: (result includesSubstring: 'a()').
	self assert: (result includesSubstring: 'b()').
	^ result
]

{ #category : 'examples-fsm-concurrency' }
GodotZealExamples >> exampleFsmSyncWithBindings [
	<gtExample>
	"Bindings are accessible inside the inlined lane bodies (no separate helpers)."
	| reg result |
	reg := GodotZealComponentRegistry new.
	reg register: 'velocity'. reg register: 'health'.
	result := GodotZealCodeGenerator compile: '(defcosystem dual [vel:@velocity health:@health]
  (sync
    (do (wait 1.0) (set vel/speed += 10))
    (do (wait 0.5) (set health/current += 5))))' withRegistry: reg.
	self assert: (result includesSubstring: 'func tick(entity: Entity, delta: float, vel: C_Velocity, health: C_Health)').
	self assert: (result includesSubstring: 'func _tick_l') not.
	self assert: (result includesSubstring: 'vel.speed += 10').
	self assert: (result includesSubstring: 'health.current += 5').
	self assert: (result includesSubstring: 'if _l0_state == 0:').
	self assert: (result includesSubstring: 'if _l1_state == 0:').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmSystemCodegen [
	<gtExample>
	"compileFsmSystemFor: generates a sibling System class that ticks the FSM"
	| sys |
	sys := GodotZealCompiler compileFsmSystemFor: 'fsm-test'.
	self assert: (sys includesSubstring: 'class_name FsmTestSystem').
	self assert: (sys includesSubstring: 'extends System').
	self assert: (sys includesSubstring: 'q.with_all([C_FsmTest])').
	self assert: (sys includesSubstring: 'iterate([C_FsmTest])').
	self assert: (sys includesSubstring: 'fsm.tick(entity, delta)').
	^ sys
]

{ #category : 'examples' }
GodotZealExamples >> exampleFsmSystemWithBindings [
	<gtExample>
	"compileFsmSystemFor:withBindings: queries for all binding components and passes them to tick."
	| bindings sys |
	bindings := GodotZealCompiler defcosystemBindings: '(defcosystem regen [health:@health vel:@velocity] (loop (wait 1.0)))'.
	sys := GodotZealCompiler compileFsmSystemFor: 'regen' withBindings: bindings.
	"Query should include all binding components"
	self assert: (sys includesSubstring: 'q.with_all([C_Regen, C_Health, C_Velocity])').
	self assert: (sys includesSubstring: 'iterate([C_Regen, C_Health, C_Velocity])').
	"Tick call should pass all binding components"
	self assert: (sys includesSubstring: 'fsm.tick(entity, delta, health_arr[_i], vel_arr[_i])').
	^ sys
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmWaitFrame [
	<gtExample>
	"(wait) creates a single-frame state boundary."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem pause
  (print "before")
  (wait)
  (print "after"))'.
	self assert: (result includesSubstring: 'print("before")').
	self assert: (result includesSubstring: 'print("after")').
	self assert: (result includesSubstring: '0:').
	self assert: (result includesSubstring: '1:').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmWaitTime [
	<gtExample>
	"(wait n) creates a timed countdown state."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem delay
  (print "go")
  (wait 1.5)
  (print "done"))'.
	self assert: (result includesSubstring: 'if _timer <= 0.0:').
	self assert: (result includesSubstring: '_timer = 1.5').
	self assert: (result includesSubstring: '_timer -= delta').
	self assert: (result includesSubstring: 'print("go")').
	self assert: (result includesSubstring: 'print("done")').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmWhenWithWait [
	<gtExample>
	"(when cond body) with waits inside splits into a branch with no else."
	| result |
	result := GodotZealCompiler compileToGDScript: '(defcosystem regen
  (loop
    (when (> hp 0)
      (wait 1.0)
      (heal-by 5))))'.
	self assert: (result includesSubstring: 'if hp > 0:').
	self assert: (result includesSubstring: 'heal_by(5)').
	self assert: (result includesSubstring: '_timer = 1.0').
	^ result
]

{ #category : 'examples-fsm' }
GodotZealExamples >> exampleFsmWithBindings [
	<gtExample>
	"defcosystem with [name:@type] bindings adds them as tick parameters."
	| reg result |
	reg := GodotZealComponentRegistry new.
	reg register: 'health'.
	result := GodotZealCodeGenerator compile: '(defcosystem regen [health:@health]
  (loop
    (wait 1.0)
    (set health/current += 5)))' withRegistry: reg.
	"tick should accept the health binding"
	self assert: (result includesSubstring: 'func tick(entity: Entity, delta: float, health: C_Health)').
	"body should reference the binding"
	self assert: (result includesSubstring: 'health.current += 5').
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleIf [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(if (< x 0) (neg) (pos))'.
	self assert: (result includesSubstring: 'if x < 0:').
	self assert: (result includesSubstring: 'neg()').
	self assert: (result includesSubstring: 'else:').
	self assert: (result includesSubstring: 'pos()').
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleIfElif [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(if (< x 0) (neg) (> x 0) (pos) (zero))'.
	self assert: (result includesSubstring: 'if x < 0:').
	self assert: (result includesSubstring: 'elif x > 0:').
	self assert: (result includesSubstring: 'else:').
	self assert: (result includesSubstring: 'zero()').
	^ result
]

{ #category : 'examples - literals' }
GodotZealExamples >> exampleKeyword [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: ':idle'.
	self assert: result trimBoth equals: '"idle"'.
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleLet [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(let [x 10 y 20] (+ x y))'.
	self assert: (result includesSubstring: 'var x = 10').
	self assert: (result includesSubstring: 'var y = 20').
	self assert: (result includesSubstring: 'x + y').
	^ result
]

{ #category : 'examples - literals' }
GodotZealExamples >> exampleMap [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '{:key "val" :other 42}'.
	self assert: (result includesSubstring: '"key": "val"').
	self assert: (result includesSubstring: '"other": 42').
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleMatch [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(match state :idle (do-idle) :attack (do-attack) _ (default-action))'.
	self assert: (result includesSubstring: 'match state:').
	self assert: (result includesSubstring: '"idle":').
	self assert: (result includesSubstring: 'do_idle()').
	self assert: (result includesSubstring: '"attack":').
	self assert: (result includesSubstring: '_:').
	^ result
]

{ #category : 'examples - literals' }
GodotZealExamples >> exampleNumberLiterals [
	<gtExample>
	| parse |
	parse := [ :s | GodotZealCodeGenerator compile: s ].
	self assert: (parse value: '42') trimBoth equals: '42'.
	self assert: (parse value: '3.14') trimBoth equals: '3.14'.
	self assert: (parse value: '0xFF') trimBoth equals: '0xFF'.
	^ 'int=42, float=3.14, hex=0xFF'
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorBinary [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(+ a b)'.
	self assert: result trimBoth equals: 'a + b'.
	^ result
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorCompound [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(+= a b)'.
	self assert: result trimBoth equals: 'a += b'.
	^ result
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorEquality [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(= a b)'.
	self assert: result trimBoth equals: 'a == b'.
	^ result
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorNot [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(not x)'.
	self assert: result trimBoth equals: 'not x'.
	^ result
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorNotEqual [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(<> a b)'.
	self assert: result trimBoth equals: 'a != b'.
	^ result
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorUnaryMinus [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(- x)'.
	self assert: result trimBoth equals: '-x'.
	^ result
]

{ #category : 'examples - operators' }
GodotZealExamples >> exampleOperatorVariadic [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(* a b c)'.
	self assert: result trimBoth equals: 'a * b * c'.
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleReturn [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(return 42)'.
	self assert: result trimBoth equals: 'return 42'.
	^ result
]

{ #category : 'examples - definitions' }
GodotZealExamples >> exampleSet [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(set current-hp 75)'.
	self assert: result trimBoth equals: 'current_hp = 75'.
	^ result
]

{ #category : 'examples - definitions' }
GodotZealExamples >> exampleSetCompound [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(set something += 1)'.
	self assert: result trimBoth equals: 'something += 1'.
	^ result
]

{ #category : 'examples - slash' }
GodotZealExamples >> exampleSlashArrayIndex [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: 'arr/0'.
	self assert: result trimBoth equals: 'arr[0]'.
	^ result
]

{ #category : 'examples - slash' }
GodotZealExamples >> exampleSlashCastAccess [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(as e @node2D position)'.
	self assert: result trimBoth equals: '(e as Node2D).position'.
	^ result
]

{ #category : 'examples - slash' }
GodotZealExamples >> exampleSlashChained [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: 'e/health/current'.
	self assert: result trimBoth equals: 'e.health.current'.
	^ result
]

{ #category : 'examples - slash' }
GodotZealExamples >> exampleSlashMethodCall [
	<gtExample>
	| gen result |
	gen := GodotZealCodeGenerator new.
	gen registry register: 'health'.
	result := gen generate: (ZealParser parse: '(e/get-component @health)').
	self assert: result trimBoth equals: 'e.get_component(C_Health)'.
	^ result
]

{ #category : 'examples - slash' }
GodotZealExamples >> exampleSlashPropertyAccess [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: 'vel/direction'.
	self assert: result trimBoth equals: 'vel.direction'.
	^ result
]

{ #category : 'examples - literals' }
GodotZealExamples >> exampleStringLiteral [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '"hello world"'.
	self assert: result trimBoth equals: '"hello world"'.
	^ result
]

{ #category : 'examples - definitions' }
GodotZealExamples >> exampleVar [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(var current-hp:int 50)'.
	self assert: result trimBoth equals: 'var current_hp: int = 50'.
	^ result
]

{ #category : 'examples - literals' }
GodotZealExamples >> exampleVector [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '[1 2 3]'.
	self assert: result trimBoth equals: '[1, 2, 3]'.
	^ result
]

{ #category : 'examples - control flow' }
GodotZealExamples >> exampleWhen [
	<gtExample>
	| result |
	result := GodotZealCodeGenerator compile: '(when (< hp 20) (print "low"))'.
	self assert: (result includesSubstring: 'if hp < 20:').
	self assert: (result includesSubstring: 'print("low")').
	self assert: (result includesSubstring: 'else') not.
	^ result
]
