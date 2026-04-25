Class {
	#name : 'AngelZealExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealExamples class >> basicFunction [
	"<gtExample>
	 A minimal typed function — add two ints."
	^ AngelZealCompiler compileToAngelScript:
'(defn add:int [x:int y:int]
    (+ x y))'
]

{ #category : 'api' }
AngelZealExamples class >> branchingFunction [
	"<gtExample>
	 if / else-if / else chain with returns."
	^ AngelZealCompiler compileToAngelScript:
'(defn classify:FString [score:int]
    (if (>= score 90) (return "A")
        (>= score 80) (return "B")
        (>= score 70) (return "C")
        (return "F")))'
]

{ #category : 'api' }
AngelZealExamples class >> classWithMethod [
	"<gtExample>
	 Class with a parent, a field, and a method — exercises nested scope."
	^ AngelZealCompiler compileToAngelScript:
'(defclass enemy:AActor
    (var health:int 100)
    (defn take-damage:void [amount:int]
        (set health -= amount)
        (when (<= health 0) (Destroy))))'
]

{ #category : 'api' }
AngelZealExamples class >> countedLoop [
	"<gtExample>
	 Range-literal (0..N) → C-style for loop. Note: the Zeal parser only forms a
	 ZealRangeLiteralNode when both endpoints are integer literals. For variable
	 endpoints, write a while loop or (for [i coll] …) over a collection."
	^ AngelZealCompiler compileToAngelScript:
'(defn first-ten:void []
    (for [i 0..10]
        (Print "Hello")))'
]

{ #category : 'api' }
AngelZealExamples class >> letScope [
	"<gtExample>
	 Let-bindings emit as a nested block scope."
	^ AngelZealCompiler compileToAngelScript:
'(defn distance:float [ax:float ay:float bx:float by:float]
    (let [dx:float (- bx ax)
          dy:float (- by ay)]
        (return (Sqrt (+ (* dx dx) (* dy dy))))))'
]

{ #category : 'api' }
AngelZealExamples class >> logicOperators [
	"<gtExample>
	 Map `and`/`or`/`not` to `&&`/`||`/`!`, `=` to `==`, `<>` to `!=`."
	^ AngelZealCompiler compileToAngelScript:
'(defn is-valid:bool [x:int]
    (and (> x 0) (< x 100) (<> x 42)))'
]

{ #category : 'api' }
AngelZealExamples class >> loopFunction [
	"<gtExample>
	 Range-based for accumulating into a var. []T is the array shorthand →
	 TArray<T>; [K]V is the map shorthand → TMap<K, V>."
	^ AngelZealCompiler compileToAngelScript:
'(defn sum:int [arr:[]int]
    (var total:int 0)
    (for [x arr] (set total += x))
    total)'
]

{ #category : 'api' }
AngelZealExamples class >> structDefinition [
	"<gtExample>
	 Plain struct — fields map straight through the type aliases."
	^ AngelZealCompiler compileToAngelScript:
'(defstruct vector2 x:float y:float)'
]
