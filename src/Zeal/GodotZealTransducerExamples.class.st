Class {
	#name : 'GodotZealTransducerExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'helpers' }
GodotZealTransducerExamples >> assert: aBoolean description: aString [
	aBoolean ifFalse: [ self error: 'Assertion failed: ' , aString ]
]

{ #category : 'helpers' }
GodotZealTransducerExamples >> assertGenerated: src includes: substring [
	"Compile src and assert the generated GDScript contains substring. Returns
	 the generated GDScript so the caller can return it from the example."
	| out |
	out := self compile: src.
	self assert: (out includesSubstring: substring) description: 
		'expected ' , substring printString , ' in ' , out printString.
	^ out
]

{ #category : 'helpers' }
GodotZealTransducerExamples >> compile: aZealString [
	"Compile a Zeal source string to GDScript and return it."
	^ GodotZealCodeGenerator compile: aZealString
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleAnyP [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :bool (any? (fn [x] (> x 0)) xs))'
		includes: 'Z.any(func(x): return x > 0, xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleAvg [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :float (avg xs))' includes: 'Z.avg(xs)'
]

{ #category : 'examples-threading' }
GodotZealTransducerExamples >> exampleBarePipeline [
	<gtExample>
	<description: '((filter pred) (map f) xs) auto-comps and fuses into a single loop'>
	| out |
	out := self compile: '(defn t [xs:Array] :Array ((filter (fn [x] (> x 0))) (map (fn [x] (* x x))) xs))'.
	self assert: (out includesSubstring: 'for _v in xs') description: 'bare pipeline should fuse into a loop'.
	^ out
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleChunk [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Callable (chunk 2))' includes: 'Z.chunking(2)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleChunkBy [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (chunk-by (fn [x] (> x 0)) xs))'
		includes: 'Z.into([], Z.chunking_by(func(x): return x > 0), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleChunkStep [
	<gtExample>
	<description: '(chunk n step) — sliding window with explicit step'>
	^ self assertGenerated: '(defn t [] :Callable (chunk 3 1))' includes: 'Z.chunking(3, 1)'
]

{ #category : 'examples-core' }
GodotZealTransducerExamples >> exampleComp [
	<gtExample>
	<description: '(comp xform1 xform2 ...) -> Z.comp([xform1, xform2, ...])'>
	^ self assertGenerated: '(defn t [] :Callable (comp (filter (fn [x] (> x 0))) (map (fn [x] (* x x))) (take 5)))'
		includes: 'Z.comp([Z.filtering(func(x): return x > 0), Z.mapping(func(x): return x * x), Z.taking(5)])'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleCount [
	<gtExample>
	<description: '(count xs) -> xs.size() — built-in, no Z call'>
	^ self assertGenerated: '(defn t [xs:Array] :int (count xs))' includes: 'xs.size()'
]

{ #category : 'examples-sources' }
GodotZealTransducerExamples >> exampleCycle [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Array (into [] (take 7) (cycle [1 2 3])))'
		includes: 'Z.cycle_([1, 2, 3])'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDedupe [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (dedupe xs))'
		includes: 'Z.into([], Z.dedupe_(), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDistinct [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (distinct xs))'
		includes: 'Z.into([], Z.distinct_(), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDrop [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (drop 2 xs))'
		includes: 'Z.into([], Z.dropping(2), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDropLastEager [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (drop-last 2 xs))'
		includes: 'Z.into([], Z.dropping_last(2), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDropLastN [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Callable (drop-last 3))' includes: 'Z.dropping_last(3)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDropLastNoArg [
	<gtExample>
	<description: '(drop-last) -> Z.dropping_last() (drops 1)'>
	^ self assertGenerated: '(defn t [] :Callable (drop-last))' includes: 'Z.dropping_last()'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleDropWhile [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (drop-while (fn [x] (< x 5)) xs))'
		includes: 'Z.dropping_while(func(x): return x < 5)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleEveryP [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :bool (every? (fn [x] (> x 0)) xs))'
		includes: 'Z.every(func(x): return x > 0, xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleFilterEager [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (filter (fn [x] (> x 0)) xs))'
		includes: 'Z.into([], Z.filtering(func(x): return x > 0), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleFilterTransducer [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Callable (filter (fn [x] (> x 0))))'
		includes: 'Z.filtering(func(x): return x > 0)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleFlatten [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (flatten xs))'
		includes: 'Z.into([], Z.flattening(), xs)'
]

{ #category : 'examples-integration' }
GodotZealTransducerExamples >> exampleFullPipeline [
	<gtExample>
	<description: 'Full transducer pipeline fuses into a single tight loop with continue/break.'>
	| out |
	out := self compile: '(defn pipeline [xs:Array] :Array
  (into [] (comp (filter (fn [x] (> x 0))) (map (fn [x] (* x x))) (take 3)) xs))'.
	self assert: (out includesSubstring: 'for _v in xs') description: 'pipeline must fuse into a loop'.
	self assert: (out includesSubstring: 'continue') description: 'filter step must use continue'.
	self assert: (out includesSubstring: 'break') description: 'take step must use break'.
	^ out
]

{ #category : 'examples-fusion' }
GodotZealTransducerExamples >> exampleFusionFallback [
	<gtExample>
	<description: 'Non-fusible xform (runtime Callable) falls back to Z.into'>
	| out |
	out := self compile: '(defn t [xs:Array xform:Callable] :Array (into [] xform xs))'.
	self assert: (out includesSubstring: 'Z.into') description: 'should fall back to Z.into'.
	self assert: (out includesSubstring: 'for _v') not description: 'should NOT fuse'.
	^ out
]

{ #category : 'examples-fusion' }
GodotZealTransducerExamples >> exampleFusionFilterMapTake [
	<gtExample>
	<description: 'Fusion: filter+map+take emits a single tight loop with break'>
	| out |
	out := self compile: '(defn t [xs:Array] :Array (into [] (comp (filter (fn [x] (> x 0))) (map (fn [x] (* x x))) (take 3)) xs))'.
	self assert: (out includesSubstring: 'for _v in xs') description: 'should fuse into a loop'.
	self assert: (out includesSubstring: 'continue') description: 'filter step should use continue'.
	self assert: (out includesSubstring: 'break') description: 'take step should use break'.
	self assert: (out includesSubstring: '_r.append') description: 'should append to result'.
	^ out
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleIndexed [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (indexed xs))'
		includes: 'Z.into([], Z.indexing(), xs)'
]

{ #category : 'examples-integration' }
GodotZealTransducerExamples >> exampleInfiniteSourceBoundedByTake [
	<gtExample>
	<description: 'iterate is infinite; take fuses into a loop with break over the iterator.'>
	| out |
	out := self compile: '(defn first-ten:Array [] (into [] (take 10) (iterate (fn [n] (+ n 1)) 0)))'.
	self assert: (out includesSubstring: 'Z.iterate_') description: 'must use Z.iterate_ as source'.
	self assert: (out includesSubstring: 'break') description: 'take must use break for early termination'.
	^ out
]

{ #category : 'examples-eager' }
GodotZealTransducerExamples >> exampleInterleave [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array ys:Array] :Array (interleave xs ys))'
		includes: 'Z.interleave([xs, ys])'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleInterpose [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (interpose 0 xs))'
		includes: 'Z.into([], Z.interposing(0), xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleIntoArray [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (into-array xs))' includes: 'Z.into_array(xs)'
]

{ #category : 'examples-core' }
GodotZealTransducerExamples >> exampleIntoEmpty [
	<gtExample>
	<description: '(into dest) -> dest.duplicate()'>
	^ self assertGenerated: '(defn t [d:Array] :Array (into d))' includes: 'd.duplicate()'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleIntoMap [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Dictionary (into-map xs))' includes: 'Z.into_map(xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleIntoString [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :String (into-string xs))' includes: 'Z.into_string(xs)'
]

{ #category : 'examples-core' }
GodotZealTransducerExamples >> exampleIntoXform [
	<gtExample>
	<description: '(into [] xform xs) fuses when xform is a known transducer with inline fn'>
	| out |
	out := self compile: '(defn t [xs:Array] :Array (into [] (map (fn [x] (* x 2))) xs))'.
	self assert: (out includesSubstring: 'for _v in xs') description: 'fusible into should emit a loop'.
	^ out
]

{ #category : 'examples-sources' }
GodotZealTransducerExamples >> exampleIterate [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Array (into [] (take 5) (iterate (fn [n] (+ n 1)) 0)))'
		includes: 'Z.iterate_(func(n): return n + 1, 0)'
]

{ #category : 'examples-combinators' }
GodotZealTransducerExamples >> exampleJuxt [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Callable (juxt (fn [x] (+ x 1)) (fn [x] (- x 1))))'
		includes: 'Z.juxt([func(x): return x + 1, func(x): return x - 1])'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleKeep [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (keep (fn [x] (if (> x 0) x null)) xs))'
		includes: 'Z.into([], Z.keeping('
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleKeepIndexed [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (keep-indexed (fn [i x] (if (> i 0) x null)) xs))'
		includes: 'Z.into([], Z.keeping_indexed('
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleMapEager [
	<gtExample>
	<description: '(map f xs) compiles to Z.into([], Z.mapping(f), xs)'>
	^ self assertGenerated: '(defn t [xs:Array] :Array (map (fn [x] (* x 2)) xs))'
		includes: 'Z.into([], Z.mapping(func(x): return x * 2), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleMapTransducer [
	<gtExample>
	<description: '(map f) compiles to Z.mapping(f)'>
	^ self assertGenerated: '(defn t [] :Callable (map (fn [x] (* x 2))))'
		includes: 'Z.mapping(func(x): return x * 2)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleMapcat [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (mapcat (fn [x] [x x]) xs))'
		includes: 'Z.into([], Z.mapcatting(func(x): return [x, x]), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleMapcatIndexed [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (mapcat-indexed (fn [i x] [i x]) xs))'
		includes: 'Z.into([], Z.mapcatting_indexed(func(i, x): return [i, x]), xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleMax [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :int (max xs))' includes: 'Z.max_of(xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleMin [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :int (min xs))' includes: 'Z.min_of(xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleProduct [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :int (product xs))' includes: 'Z.product(xs)'
]

{ #category : 'examples-sources' }
GodotZealTransducerExamples >> exampleRangeOne [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Array (range 10))' includes: 'range(10)'
]

{ #category : 'examples-sources' }
GodotZealTransducerExamples >> exampleRangeThree [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Array (range 0 100 5))' includes: 'range(0, 100, 5)'
]

{ #category : 'examples-sources' }
GodotZealTransducerExamples >> exampleRangeTwo [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Array (range 1 11))' includes: 'range(1, 11)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleReduceThreeArg [
	<gtExample>
	<description: '(reduce f init xs) -> Z.reduce(f, init, xs)'>
	^ self assertGenerated: '(defn t [xs:Array] :int (reduce (fn [a b] (+ a b)) 0 xs))'
		includes: 'Z.reduce(func(a, b): return a + b, 0, xs)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleReduceTwoArg [
	<gtExample>
	<description: '(reduce f xs) -> Z.reduce(f, null, xs)'>
	^ self assertGenerated: '(defn t [xs:Array] :int (reduce (fn [a b] (+ a b)) xs))'
		includes: 'Z.reduce(func(a, b): return a + b, null, xs)'
]

{ #category : 'examples-sources' }
GodotZealTransducerExamples >> exampleRepeat [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Array (into [] (take 3) (repeat "x")))'
		includes: 'Z.repeat_("x")'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleSum [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :int (sum xs))' includes: 'Z.sum(xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleTakeEager [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (take 3 xs))'
		includes: 'Z.into([], Z.taking(3), xs)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleTakeTransducer [
	<gtExample>
	^ self assertGenerated: '(defn t [] :Callable (take 3))' includes: 'Z.taking(3)'
]

{ #category : 'examples-transducers' }
GodotZealTransducerExamples >> exampleTakeWhile [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Array (take-while (fn [x] (< x 5)) xs))'
		includes: 'Z.taking_while(func(x): return x < 5)'
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleTally [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :Dictionary (tally xs))' includes: 'Z.tally(xs)'
]

{ #category : 'examples-threading' }
GodotZealTransducerExamples >> exampleThreadAutoFirst [
	<gtExample>
	<description: '(-> x (f a)) with no _ auto-inserts x as first arg -> (f x a)'>
	| out |
	out := self compile: '(defn t [x] (-> x (print "val: ")))'.
	self assert: (out includesSubstring: 'print(x, "val: ")') description: 'should insert x as first arg'.
	^ out
]

{ #category : 'examples-threading' }
GodotZealTransducerExamples >> exampleThreadBareSymbol [
	<gtExample>
	<description: '(-> x blah (bleh 1 _)) bare symbol wraps as (blah x), _ explicit on bleh'>
	| out |
	out := self compile: '(defn t [x] (-> x blah (bleh 1 _)))'.
	self assert: (out includesSubstring: 'bleh(1, blah(x))') description: 'bare sym + explicit _'.
	^ out
]

{ #category : 'examples-threading' }
GodotZealTransducerExamples >> exampleThreadLast [
	<gtExample>
	<description: '(-> xs (f _ ) uses _ for insertion point — transducer-friendly'>
	| out |
	out := self compile: '(defn t [xs:Array] :Array (-> xs (filter (fn [x] (> x 0)) _) (map (fn [x] (* x x)) _)))'.
	self assert: (out includesSubstring: 'Z.') description: 'thread with _ should emit Z.* calls'.
	^ out
]

{ #category : 'examples-reducers' }
GodotZealTransducerExamples >> exampleTransduce [
	<gtExample>
	^ self assertGenerated: '(defn t [xs:Array] :int (transduce (map (fn [x] (* x 2))) (Z:append_rf) [] xs))'
		includes: 'Z.transduce(Z.mapping(func(x): return x * 2),'
]
