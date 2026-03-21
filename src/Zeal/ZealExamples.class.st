Class {
	#name : 'ZealExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'examples' }
ZealExamples >> classWithMethods [
	<gtExample>
	^ ZealCompiler compile: '(defclass character:concrete (entity)
  (var health:int 100)
  (defn take-damage:void [amount:int]
    (set health (Max 0 (- health amount)))))'
]

{ #category : 'examples' }
ZealExamples >> enumDefinition [
	<gtExample>
	^ ZealCompiler compile: '(defenum game-state :main-menu :playing :paused :game-over)'
]

{ #category : 'examples' }
ZealExamples >> forWithFilters [
	<gtExample>
	^ ZealCompiler compile: '(for [x 1..10 (> x 3) (< x 7)] (Print x))'
]

{ #category : 'examples' }
ZealExamples >> fullProgram [
	<gtExample>
	^ ZealCompiler compile: '
(defstruct vector2 [x:float 0.0] [y:float 0.0])
(defenum game-state :main-menu :playing :paused :game-over)
(defn calculate-score:public:int [base:int bonus:int]
  (+ base (* bonus 2)))
(defclass character:concrete (entity)
  (var health:int 100)
  (var level:int 1)
  (defn take-damage:void [amount:int]
    (set health (Max 0 (- health amount))))
  (defn is-alive:decides:void
    (> health 0)))'
]

{ #category : 'examples' }
ZealExamples >> functionWithSpecifiers [
	<gtExample>
	^ ZealCompiler compile: '(defn add:public:int [x:int y:int] (+ x y))'
]

{ #category : 'examples' }
ZealExamples >> ifElseIfElse [
	<gtExample>
	^ ZealCompiler compile: '(if (> x 100) (Print "high") (> x 50) (Print "medium") :else (Print "low"))'
]

{ #category : 'examples' }
ZealExamples >> letWithPredicates [
	<gtExample>
	^ ZealCompiler compile: '(let [x 10 y:int 9 (< 10 x)] (Print x))'
]

{ #category : 'examples' }
ZealExamples >> loopWithBreak [
	<gtExample>
	^ ZealCompiler compile: '(loop (set x (+ x 1)) (if (> x 10) (break)))'
]

{ #category : 'examples' }
ZealExamples >> structDefinition [
	<gtExample>
	^ ZealCompiler compile: '(defstruct vector2 [x:float 0.0] [y:float 0.0])'
]

{ #category : 'examples' }
ZealExamples >> variableBindings [
	<gtExample>
	^ ZealCompiler compile: '(def pi:float 3.14)
(var hp:int 100)
(set hp 50)'
]
