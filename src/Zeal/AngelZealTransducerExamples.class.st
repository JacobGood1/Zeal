Class {
	#name : 'AngelZealTransducerExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'examples' }
AngelZealTransducerExamples >> accTypeFollowsInitLiteral [
	"Float init produces float Acc."
	<gtExample>
	| out |
	out := self compile: '(transduce (map id) + 0.0 [1.5 2.5 3.5])'.
	self assert: (out includesSubstring: 'float Acc = 0.0;') label: 'float accumulator from float init'.
	self assert: (out includesSubstring: 'TArray<float>') label: 'TArray<float> for vec literal'.
	^ out
]

{ #category : 'helpers' }
AngelZealTransducerExamples >> assert: actual equals: expected label: label [
	actual = expected ifTrue: [ ^ self ].
	^ self error: label , ' — expected ' , expected printString
		, ' but got ' , actual printString
]

{ #category : 'helpers' }
AngelZealTransducerExamples >> assert: aBoolean label: label [
	aBoolean ifTrue: [ ^ self ].
	^ self error: label , ' — expected true but got false'
]

{ #category : 'examples' }
AngelZealTransducerExamples >> collOverNamedVariableUsesItDirectly [
	"When the source isn't a vector literal, no TArray<…> temp is materialized
	 — the for-each iterates over the symbol directly."
	<gtExample>
	| out |
	out := self compile: '(transduce (map inc) + 0 nums)'.
	self assert: ((out includesSubstring: 'TArray<') not) label: 'no TArray temp for variable source'.
	self assert: (out includesSubstring: 'for (int Elem : Nums)') label: 'iterates over Nums directly'.
	^ out
]

{ #category : 'examples' }
AngelZealTransducerExamples >> compFlattenedInDataFlowOrder [
	"(comp s1 s2 s3) emits s1, then s2, then s3 — the data flows through
	 each in left-to-right order. Verify by ordering of stage markers in
	 the loop body."
	<gtExample>
	| out incIdx evenIdx takeIdx |
	out := self compile: '(transduce (comp (map inc) (filter even?) (take 3)) + 0 [1 2 3 4 5 6 7])'.
	incIdx := out indexOfSubCollection: 'Inc(Elem)'.
	evenIdx := out indexOfSubCollection: 'Even(Elem)'.
	"Use the take-check substring rather than the bare counter name —
	 the counter declaration appears before the loop, so a bare match would
	 see it earlier than the map stage."
	takeIdx := out indexOfSubCollection: '__Taken >= 3'.
	self assert: (incIdx > 0 and: [ incIdx < evenIdx and: [ evenIdx < takeIdx ] ])
		label: 'stages emit in (comp …) order: map, filter, take'.
	^ out
]

{ #category : 'helpers' }
AngelZealTransducerExamples >> compile: zealSrc [
	^ AngelZealCompiler compileToAngelScript: zealSrc
]

{ #category : 'examples' }
AngelZealTransducerExamples >> dropStageEmitsContinueAndCounter [
	"(drop n) introduces a __Dropped counter and skips first n."
	<gtExample>
	| out |
	out := self compile: '(transduce (drop 2) + 0 [10 20 30 40])'.
	self assert: (out includesSubstring: 'int __Dropped = 0;') label: 'dropped counter declared'.
	self assert: (out includesSubstring: 'if (__Dropped < 2) { ++__Dropped; continue; }') label: 'skip-first-n logic'.
	^ out
]

{ #category : 'examples' }
AngelZealTransducerExamples >> filterStageEmitsContinue [
	"(filter pred?) compiles to `if (!Pred(Elem)) continue;` with the `?`
	 stripped from the identifier."
	<gtExample>
	| out |
	out := self compile: '(transduce (filter even?) + 0 [1 2 3 4])'.
	self assert: (out includesSubstring: 'if (!(Even(Elem))) continue;') label: 'filter → skip-if-not'.
	self assert: ((out includesSubstring: 'Even?') not) label: '? stripped from identifier'.
	^ out
]

{ #category : 'examples' }
AngelZealTransducerExamples >> mapStageInlinesAssignment [
	"Single (map fn) reassigns Elem and proceeds to the reducer."
	<gtExample>
	| out |
	out := self compile: '(transduce (map inc) + 0 [1 2 3])'.
	self assert: (out includesSubstring: 'int Acc = 0;') label: 'int accumulator declared'.
	self assert: (out includesSubstring: 'TArray<int> __Coll = {1, 2, 3};') label: 'TArray temp for vec literal'.
	self assert: (out includesSubstring: 'for (int Elem : __Coll)') label: 'range-for over coll'.
	self assert: (out includesSubstring: 'Elem = Inc(Elem);') label: 'map stage reassigns'.
	self assert: (out includesSubstring: 'Acc = Acc + Elem;') label: 'reducer step'.
	^ out
]

{ #category : 'examples' }
AngelZealTransducerExamples >> namedReducerEmitsCallNotOperator [
	"A non-operator reducer emits `Acc = MyReducer(Acc, Elem)` rather than
	 an inline operator."
	<gtExample>
	| out |
	out := self compile: '(transduce (map inc) my-combine 0 [1 2 3])'.
	self assert: (out includesSubstring: 'Acc = MyCombine(Acc, Elem);') label: 'named reducer call'.
	^ out
]

{ #category : 'examples' }
AngelZealTransducerExamples >> standaloneFactoryEmitsPlaceholder [
	"(map fn) outside a transduce emits a placeholder comment — Option-B
	 monomorphic codegen has no runtime representation for transducers."
	<gtExample>
	| out |
	out := self compile: '(map inc)'.
	self assert: (out includesSubstring: '/* map: only valid inside') label: 'placeholder for standalone factory'.
	^ out
]

{ #category : 'examples' }
AngelZealTransducerExamples >> takeStageEmitsBreakAndCounter [
	"(take n) introduces a __Taken counter and breaks once the count is
	 reached."
	<gtExample>
	| out |
	out := self compile: '(transduce (take 3) + 0 [1 2 3 4 5])'.
	self assert: (out includesSubstring: 'int __Taken = 0;') label: 'taken counter declared'.
	self assert: (out includesSubstring: 'if (__Taken >= 3) break;') label: 'break when limit reached'.
	self assert: (out includesSubstring: '++__Taken;') label: 'increment counter on pass'.
	^ out
]
