Class {
	#name : 'ZealDesugarerExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'helpers' }
ZealDesugarerExamples >> assert: actual equals: expected label: label [
	actual = expected ifTrue: [ ^ self ].
	^ self error: label , ' — expected ', expected printString , ' but got ', actual printString
]

{ #category : 'helpers' }
ZealDesugarerExamples >> assert: aBoolean label: label [
	"Boolean-only assertion form."
	aBoolean ifTrue: [ ^ self ].
	^ self error: label , ' — expected true but got false'
]

{ #category : 'examples-for' }
ZealDesugarerExamples >> forNestedBindsAndGuards [
	"(for [x c1 (even? x) y c2 (< y 5)] (pair x y)) → 
	 (for [x c1] (when (even? x) (for [y c2] (when (< y 5) (pair x y)))))"
	<gtExample>
	| input output outerWhen innerFor innerWhen |
	input := self parse: '(for [x coll1 (even? x) y coll2 (< y 5)] (pair x y))'.
	output := ZealDesugarer desugarFor: input.
	self assert: (self headSymbolOf: output) equals: 'for' label: 'outer is for'.
	outerWhen := output expressions third.
	self assert: (self headSymbolOf: outerWhen) equals: 'when' label: 'first guard wraps with when'.
	innerFor := outerWhen expressions third.
	self assert: (self headSymbolOf: innerFor) equals: 'for' label: 'second bind is nested for'.
	innerWhen := innerFor expressions third.
	self assert: (self headSymbolOf: innerWhen) equals: 'when' label: 'second guard wraps inner body'.
	self assert: innerWhen expressions third source equals: '(pair x y)' label: 'body intact'.
	^ output
]

{ #category : 'examples-for' }
ZealDesugarerExamples >> forObjectDestructuring [
	"(for [{x lx y ly} entities] (use lx ly)) →
	 (for [__t1 entities] (let [lx (slot __t1 x) ly (slot __t1 y)] (use lx ly)))"
	<gtExample>
	| input output letNode letBindings |
	input := self parse: '(for [{x lx y ly} entities] (use lx ly))'.
	output := ZealDesugarer desugarFor: input.
	letNode := output expressions third.
	self assert: (self headSymbolOf: letNode) equals: 'let'
		label: 'object destructuring extraction is a let'.
	letBindings := letNode expressions second.
	self assert: letBindings expressions size equals: 4 label: 'two locals, two slot exprs'.
	self assert: letBindings expressions first source equals: 'lx' label: 'first local is lx'.
	self assert: (letBindings expressions second source includesSubstring: '(slot __t')
		label: 'lx bound via (slot tmp x)'.
	^ output
]

{ #category : 'examples-for' }
ZealDesugarerExamples >> forPlainPassthrough [
	"A for with one symbol/coll pair and no guards is unchanged."
	<gtExample>
	| input output |
	input := self parse: '(for [x coll] (print x))'.
	output := ZealDesugarer desugarFor: input.
	self assert: output == input
		equals: true
		label: 'plain for must be returned unchanged'.
	^ output
]

{ #category : 'examples-for' }
ZealDesugarerExamples >> forPositionalDestructuring [
	"(for [[a b] pairs] (sum a b)) →
	 (for [__t1 pairs] (let [a (at __t1 0) b (at __t1 1)] (sum a b)))"
	<gtExample>
	| input output bindingVec letNode letBindings |
	input := self parse: '(for [[a b] pairs] (sum a b))'.
	output := ZealDesugarer desugarFor: input.
	bindingVec := output expressions second.
	self assert: bindingVec expressions size equals: 2 label: 'tmp loop var + collection'.
	self assert: (bindingVec expressions first source beginsWith: '__t')
		label: 'loop var is gensymmed'.
	letNode := output expressions third.
	self assert: (self headSymbolOf: letNode) equals: 'let'
		label: 'destructuring extraction lives in a let inside the loop body'.
	letBindings := letNode expressions second.
	self assert: letBindings expressions size equals: 4 label: 'a + b extracted via at'.
	self assert: (letBindings expressions second source includesSubstring: '(at __t')
		label: 'a uses (at tmp 0)'.
	^ output
]

{ #category : 'examples-for' }
ZealDesugarerExamples >> forSingleGuard [
	"(for [x coll (even? x)] body) → (for [x coll] (when (even? x) body))"
	<gtExample>
	| input output bindingVec whenNode |
	input := self parse: '(for [x coll (even? x)] (print x))'.
	output := ZealDesugarer desugarFor: input.
	self assert: (self headSymbolOf: output) equals: 'for' label: 'top is for'.
	bindingVec := output expressions second.
	self assert: bindingVec expressions size equals: 2
		label: 'binding vector reduces to just x coll'.
	whenNode := output expressions third.
	self assert: (self headSymbolOf: whenNode) equals: 'when'
		label: 'guard becomes a when wrapping body'.
	self assert: whenNode expressions second source equals: '(even? x)'
		label: 'when predicate matches the original guard'.
	^ output
]

{ #category : 'helpers' }
ZealDesugarerExamples >> headSymbolOf: aListNode [
	"Return the symbol-string at the head of a list, or nil if the head
	 isn't a symbol."
	| exprs head |
	(aListNode isKindOf: ZealListNode) ifFalse: [ ^ nil ].
	exprs := aListNode expressions.
	exprs isEmpty ifTrue: [ ^ nil ].
	head := exprs first.
	(head isKindOf: ZealSymbolNode) ifFalse: [ ^ nil ].
	^ head value value
]

{ #category : 'examples-let-destructuring' }
ZealDesugarerExamples >> letMixedDestructuringAndGuard [
	"(let [[a b] coll {x lx} obj (< a x)] body) →
	 (let [__t1 coll a (at __t1 0) b (at __t1 1) __t2 obj lx (slot __t2 x)]
	    (if (< a x) body nil))"
	<gtExample>
	| input output bindingVec ifNode |
	input := self parse: '(let [[a b] coll {x lx} obj (< a x)] (+ a b lx))'.
	output := ZealDesugarer desugarLet: input.
	bindingVec := output expressions second.
	self assert: bindingVec expressions size equals: 10
		label: '(__t1 coll a-pair b-pair __t2 obj lx-pair) = 10 entries'.
	ifNode := output expressions third.
	self assert: (self headSymbolOf: ifNode) equals: 'if' label: 'guard becomes outer if'.
	self assert: ifNode expressions second source equals: '(< a x)'
		label: 'guard predicate preserved'.
	^ output
]

{ #category : 'examples-let-multigroup' }
ZealDesugarerExamples >> letMultiGroup [
	"(let [x 10 (< x 5)] x [y 5] (* y 2)) →
	 (let [x 10] (if (< x 5) x (let [y 5] (* y 2))))
	 Group 1's else branch is group 2's let-form."
	<gtExample>
	| input output ifNode elseBranch |
	input := self parse: '(let [x 10 (< x 5)] x [y 5] (* y 2))'.
	output := ZealDesugarer desugarLet: input.
	ifNode := output expressions third.
	self assert: (self headSymbolOf: ifNode) equals: 'if' label: 'group 1 emits an if'.
	self assert: ifNode expressions third source equals: 'x' label: 'then-branch is g1 body'.
	elseBranch := ifNode expressions fourth.
	self assert: (self headSymbolOf: elseBranch) equals: 'let' label: 'else-branch is group 2 let'.
	^ output
]

{ #category : 'examples-let-multigroup' }
ZealDesugarerExamples >> letMultiGroupNoMatchYieldsNil [
	"When every group has guards and we want the failure case, the last
	 if's else branch must be the symbol `nil`."
	<gtExample>
	| input output finalElse |
	input := self parse: '(let [x 10 (< x 5)] x [y 5 (= y 5)] (* y 2))'.
	output := ZealDesugarer desugarLet: input.
	finalElse := output expressions third expressions fourth.
	self assert: (self headSymbolOf: finalElse) equals: 'let' label: 'g1 else falls into g2 let'.
	"g2's if's else should be nil"
	self assert: finalElse expressions third expressions fourth source equals: 'nil'
		label: 'final fall-through is nil'.
	^ output
]

{ #category : 'examples-let-destructuring' }
ZealDesugarerExamples >> letObjectDestructuring [
	"(let [{x lx y ly} obj] body) →
	 (let [__t1 obj lx (slot __t1 x) ly (slot __t1 y)] body)
	 Map keys = slot names; map values = local names."
	<gtExample>
	| input output bindingVec |
	input := self parse: '(let [{x lx y ly} obj] (use lx ly))'.
	output := ZealDesugarer desugarLet: input.
	bindingVec := output expressions second.
	self assert: bindingVec expressions size equals: 6
		label: 'tmp + obj + 2 (local, slot) pairs = 6'.
	self assert: bindingVec expressions third source equals: 'lx'
		label: 'first extracted local is lx (the map value side)'.
	self assert: (bindingVec expressions fourth source includesSubstring: '(slot __t')
		label: 'lx bound via (slot tmp x)'.
	self assert: (bindingVec expressions fourth source endsWith: 'x)')
		label: 'extracts slot x (the map key side)'.
	self assert: bindingVec expressions fifth source equals: 'ly'
		label: 'second extracted local is ly'.
	^ output
]

{ #category : 'examples-let-guards' }
ZealDesugarerExamples >> letPlainPassthrough [
	"A let with no guards or destructuring is returned unchanged."
	<gtExample>
	| input output |
	input := self parse: '(let [x 10 y 20] (+ x y))'.
	output := ZealDesugarer desugarLet: input.
	self assert: output == input
		equals: true
		label: 'plain let must be returned unchanged (identity)'.
	^ output
]

{ #category : 'examples-let-destructuring' }
ZealDesugarerExamples >> letPositionalDestructuring [
	"(let [[a b c] coll] (+ a b c)) →
	 (let [__t1 coll a (at __t1 0) b (at __t1 1) c (at __t1 2)] (+ a b c))"
	<gtExample>
	| input output bindingVec |
	input := self parse: '(let [[a b c] coll] (+ a b c))'.
	output := ZealDesugarer desugarLet: input.
	self assert: (self headSymbolOf: output) equals: 'let' label: 'top is let'.
	bindingVec := output expressions second.
	self assert: bindingVec expressions size equals: 8
		label: 'tmp + coll + (a, b, c) × 2 = 8 entries'.
	self assert: (bindingVec expressions first source beginsWith: '__t')
		label: 'first slot is gensymmed temp'.
	self assert: bindingVec expressions second source equals: 'coll'
		label: 'tmp bound to original collection'.
	self assert: (bindingVec expressions fourth source includesSubstring: '(at __t')
		label: 'a binding uses (at tmp idx)'.
	self assert: ((bindingVec expressions fourth source) endsWith: '0)')
		label: 'first index is 0'.
	^ output
]

{ #category : 'examples-let-guards' }
ZealDesugarerExamples >> letSingleGuard [
	"(let [x 10 (< x 5)] x) → (let [x 10] (if (< x 5) x nil))
	 Tree shape: let with one binding pair, body = if(guard, x, nil)."
	<gtExample>
	| input output ifNode bindingVec |
	input := self parse: '(let [x 10 (< x 5)] x)'.
	output := ZealDesugarer desugarLet: input.
	self assert: (self headSymbolOf: output) equals: 'let' label: 'top is let'.
	bindingVec := output expressions second.
	self assert: bindingVec class equals: ZealVectorNode label: 'second is vector'.
	self assert: bindingVec expressions size equals: 2 label: 'binding has only x 10'.
	ifNode := output expressions third.
	self assert: (self headSymbolOf: ifNode) equals: 'if' label: 'body wrapped in if'.
	self assert: ifNode expressions second source equals: '(< x 5)' label: 'guard moved into if test'.
	self assert: ifNode expressions fourth source equals: 'nil' label: 'else branch is nil'.
	^ output
]

{ #category : 'examples-let-guards' }
ZealDesugarerExamples >> letTwoInterleavedGuards [
	"(let [x 10 (< x 5) y 20 (= y 20)] x) →
	 (let [x 10] (if (< x 5) (let [y 20] (if (= y 20) x nil)) nil))"
	<gtExample>
	| input output outerIf innerLet innerIf |
	input := self parse: '(let [x 10 (< x 5) y 20 (= y 20)] x)'.
	output := ZealDesugarer desugarLet: input.
	self assert: (self headSymbolOf: output) equals: 'let' label: 'outer is let'.
	outerIf := output expressions third.
	self assert: (self headSymbolOf: outerIf) equals: 'if' label: 'outer body is if'.
	innerLet := outerIf expressions third.
	self assert: (self headSymbolOf: innerLet) equals: 'let' label: 'then-branch is a nested let'.
	innerIf := innerLet expressions third.
	self assert: (self headSymbolOf: innerIf) equals: 'if' label: 'inner let body is another if'.
	self assert: innerIf expressions second source equals: '(= y 20)' label: 'inner guard preserved'.
	^ output
]

{ #category : 'helpers' }
ZealDesugarerExamples >> parse: aString [
	"Parse a Zeal source string and return its first top-level expression."
	^ (ZealParser parse: aString) expressions first
]
