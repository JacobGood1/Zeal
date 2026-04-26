Class {
	#name : 'ZealDesugarer',
	#superclass : 'Object',
	#instVars : [
		'counter'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
ZealDesugarer class >> desugarFor: aListNode [
	"Take a (for ...) ZealListNode and return a new ZealListNode with guards
	 expanded into nested whens, and destructuring patterns flattened. The
	 binding vector keeps multi-iteration semantics (each name+coll pair = a
	 nested level)."
	^ self new desugarFor: aListNode
]

{ #category : 'api' }
ZealDesugarer class >> desugarLet: aListNode [
	"Take a (let ...) ZealListNode and return a new ZealListNode with guards
	 expanded into nested ifs, multi-group cond-let cascaded into nested
	 if/let, and destructuring patterns ([], {}) flattened to plain
	 sequential bindings.
	 Returns the original node if no transformation is needed."
	^ self new desugarLet: aListNode
]

{ #category : 'private' }
ZealDesugarer >> bindingHasGuardsOrDestructuring: aBindingVector [
	aBindingVector ifNil: [ ^ false ].
	^ aBindingVector expressions anySatisfy: [ :e |
		(e isKindOf: ZealListNode)
			or: [ (e isKindOf: ZealVectorNode)
			or: [ e isKindOf: ZealMapNode ] ] ]
]

{ #category : 'api' }
ZealDesugarer >> desugarFor: aListNode [
	"Top-level for desugaring. See class>>#desugarFor: for spec."
	| exprs args bindingVec body source |
	exprs := aListNode expressions.
	(self isForForm: aListNode) ifFalse: [ ^ aListNode ].
	args := exprs allButFirst.
	args size < 2 ifTrue: [ ^ aListNode ].
	bindingVec := args first.
	body := args allButFirst.
	(bindingVec isKindOf: ZealVectorNode) ifFalse: [ ^ aListNode ].
	(self forNeedsDesugar: bindingVec) ifFalse: [ ^ aListNode ].
	source := self emitForSourceFor: bindingVec body: body.
	^ (ZealParser parse: source) expressions first
]

{ #category : 'api' }
ZealDesugarer >> desugarLet: aListNode [
	"Top-level let desugaring. See class>>#desugarLet: for spec."
	| exprs args groups source |
	exprs := aListNode expressions.
	(self isLetForm: aListNode) ifFalse: [ ^ aListNode ].
	args := exprs allButFirst.
	args isEmpty ifTrue: [ ^ aListNode ].
	groups := self letGroupsFromArgs: args.
	(self letNeedsDesugar: groups) ifFalse: [ ^ aListNode ].
	source := self emitLetSourceForGroups: groups.
	^ (ZealParser parse: source) expressions first
]

{ #category : 'emitting' }
ZealDesugarer >> emitForItems: items index: idx bodySrc: bodySrc [
	"Walk items left-to-right.
	 - bind starts a (for [name val] <inner>) wrapping the rest.
	 - guard wraps the rest in (when guard <inner>).
	 - destructure introduces a tmp loop var with a let inside that extracts."
	| item kind |
	idx > items size ifTrue: [ ^ bodySrc ].
	item := items at: idx.
	kind := item at: #kind.
	kind = #bind ifTrue: [
		| inner |
		inner := self emitForItems: items index: idx + 1 bodySrc: bodySrc.
		^ '(for [' , (item at: #nameSrc) , ' ' , (item at: #valSrc) , '] ' , inner , ')' ].
	kind = #guard ifTrue: [
		| inner |
		inner := self emitForItems: items index: idx + 1 bodySrc: bodySrc.
		^ '(when ' , (item at: #exprSrc) , ' ' , inner , ')' ].
	kind = #destructurePositional ifTrue: [
		| tmp letBinds inner |
		tmp := self gensym: 't'.
		letBinds := OrderedCollection new.
		(item at: #names) doWithIndex: [ :n :i |
			letBinds add: n.
			letBinds add: '(at ' , tmp , ' ' , (i - 1) printString , ')' ].
		inner := self emitForItems: items index: idx + 1 bodySrc: bodySrc.
		^ '(for [' , tmp , ' ' , (item at: #valSrc) , '] (let ['
			, (' ' join: letBinds) , '] ' , inner , '))' ].
	kind = #destructureObject ifTrue: [
		| tmp letBinds inner |
		tmp := self gensym: 't'.
		letBinds := OrderedCollection new.
		(item at: #pairs) do: [ :pair |
			letBinds add: pair second.
			letBinds add: '(slot ' , tmp , ' ' , pair first , ')' ].
		inner := self emitForItems: items index: idx + 1 bodySrc: bodySrc.
		^ '(for [' , tmp , ' ' , (item at: #valSrc) , '] (let ['
			, (' ' join: letBinds) , '] ' , inner , '))' ].
	^ self error: 'unknown for binding item kind: ' , kind printString
]

{ #category : 'emitting' }
ZealDesugarer >> emitForSourceFor: aBindingVector body: bodyExprs [
	"Build a desugared (for ...) source by recursing through binding items.
	 Each bind starts a nested for, each guard wraps in (when guard ...),
	 destructuring patterns introduce a tmp loop var + let inside the body."
	| items bodySrc |
	items := self parseBindingItems: aBindingVector.
	bodySrc := bodyExprs ifEmpty: [ 'nil' ]
		ifNotEmpty: [ bodyExprs size = 1
			ifTrue: [ bodyExprs first source ]
			ifFalse: [ '(do ' , (' ' join: (bodyExprs collect: [ :e | e source ])) , ')' ] ].
	^ self emitForItems: items index: 1 bodySrc: bodySrc
]

{ #category : 'emitting' }
ZealDesugarer >> emitGroupCascade: groupsList [
	"Build a chain of (let ... (if guard <body> <next-group>)) forms.
	 Final group with no successor uses `nil` as the implicit else."
	| g rest body bodySrc elseSrc items |
	groupsList isEmpty ifTrue: [ ^ 'nil' ].
	g := groupsList first.
	rest := groupsList allButFirst.
	body := g at: #body.
	bodySrc := body ifNotNil: [ body source ] ifNil: [ 'nil' ].
	"A nil-bindings group is an unconditional else body; emit verbatim."
	(g at: #bindings) ifNil: [ ^ bodySrc ].
	elseSrc := self emitGroupCascade: rest.
	items := self parseBindingItems: (g at: #bindings).
	^ self emitGroupItems: items index: 1 acc: OrderedCollection new
		bodySrc: bodySrc elseSrc: elseSrc
]

{ #category : 'emitting' }
ZealDesugarer >> emitGroupItems: items index: idx acc: acc bodySrc: bodySrc elseSrc: elseSrc [
	"Walk binding items one at a time. Plain binds + destructured binds
	 accumulate into `acc` (flat name/val source strings). A guard splits
	 the accumulation: emit (let [acc] (if guard <recurse on rest> elseSrc))."
	| item kind |
	idx > items size ifTrue: [
		acc isEmpty ifTrue: [ ^ bodySrc ].
		^ '(let [' , (' ' join: acc) , '] ' , bodySrc , ')' ].
	item := items at: idx.
	kind := item at: #kind.
	kind = #guard ifTrue: [
		| inner ifSrc |
		inner := self emitGroupItems: items index: idx + 1
			acc: OrderedCollection new bodySrc: bodySrc elseSrc: elseSrc.
		ifSrc := '(if ' , (item at: #exprSrc) , ' ' , inner , ' ' , elseSrc , ')'.
		acc isEmpty ifTrue: [ ^ ifSrc ].
		^ '(let [' , (' ' join: acc) , '] ' , ifSrc , ')' ].
	kind = #bind ifTrue: [
		acc add: (item at: #nameSrc).
		acc add: (item at: #valSrc).
		^ self emitGroupItems: items index: idx + 1 acc: acc
			bodySrc: bodySrc elseSrc: elseSrc ].
	kind = #destructurePositional ifTrue: [
		| tmp |
		tmp := self gensym: 't'.
		acc add: tmp. acc add: (item at: #valSrc).
		(item at: #names) doWithIndex: [ :n :i |
			acc add: n.
			acc add: '(at ' , tmp , ' ' , (i - 1) printString , ')' ].
		^ self emitGroupItems: items index: idx + 1 acc: acc
			bodySrc: bodySrc elseSrc: elseSrc ].
	kind = #destructureObject ifTrue: [
		| tmp |
		tmp := self gensym: 't'.
		acc add: tmp. acc add: (item at: #valSrc).
		(item at: #pairs) do: [ :pair |
			acc add: pair second.
			acc add: '(slot ' , tmp , ' ' , pair first , ')' ].
		^ self emitGroupItems: items index: idx + 1 acc: acc
			bodySrc: bodySrc elseSrc: elseSrc ].
	^ self error: 'unknown binding item kind: ' , kind printString
]

{ #category : 'emitting' }
ZealDesugarer >> emitLetSourceForGroups: groups [
	"Top-level emitter: turn a list of {bindings, body} groups into a single
	 desugared (let ...) source string by cascading them as nested ifs."
	^ self emitGroupCascade: groups
]

{ #category : 'private' }
ZealDesugarer >> forNeedsDesugar: aBindingVector [
	"For only needs desugaring if there's a guard (list at name slot) or a
	 destructuring pattern (vector/map at name slot). The first slot must be
	 a name (symbol/chain) followed by a collection — those don't need work."
	^ self bindingHasGuardsOrDestructuring: aBindingVector
]

{ #category : 'private' }
ZealDesugarer >> gensym: prefix [
	"Return a fresh, unique-within-this-instance symbol like __t1, __t2, ..."
	counter := counter + 1.
	^ '__' , prefix , counter printString
]

{ #category : 'initialize-release' }
ZealDesugarer >> initialize [
	super initialize.
	counter := 0
]

{ #category : 'private' }
ZealDesugarer >> isForForm: aListNode [
	| exprs |
	(aListNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	exprs := aListNode expressions.
	^ exprs notEmpty
		and: [ (exprs first isKindOf: ZealSymbolNode)
		and: [ exprs first value value = 'for' ] ]
]

{ #category : 'private' }
ZealDesugarer >> isLetForm: aListNode [
	| exprs |
	(aListNode isKindOf: ZealListNode) ifFalse: [ ^ false ].
	exprs := aListNode expressions.
	^ exprs notEmpty
		and: [ (exprs first isKindOf: ZealSymbolNode)
		and: [ exprs first value value = 'let' ] ]
]

{ #category : 'private' }
ZealDesugarer >> letGroupsFromArgs: argsList [
	"Split a let's args into groups of {bindings, body}. Strict pairs:
	 [vec] body [vec] body ... A trailing odd element with no preceding vector
	 becomes an unconditional final group with #bindings -> nil."
	| groups i n |
	groups := OrderedCollection new.
	i := 1. n := argsList size.
	[ i <= n ] whileTrue: [
		| binding body |
		binding := argsList at: i.
		(binding isKindOf: ZealVectorNode)
			ifTrue: [
				body := i + 1 <= n ifTrue: [ argsList at: i + 1 ] ifFalse: [ nil ].
				groups add: (Dictionary new
					at: #bindings put: binding;
					at: #body put: body;
					yourself).
				i := i + 2 ]
			ifFalse: [
				"Unconditional else body."
				groups add: (Dictionary new
					at: #bindings put: nil;
					at: #body put: binding;
					yourself).
				i := i + 1 ] ].
	^ groups
]

{ #category : 'private' }
ZealDesugarer >> letNeedsDesugar: groups [
	"Single plain group with only symbol/colon-chain bindings → no desugaring.
	 Multiple groups, any guard, or any destructuring pattern triggers it."
	groups size > 1 ifTrue: [ ^ true ].
	groups first ifNil: [ ^ false ].
	^ self bindingHasGuardsOrDestructuring: (groups first at: #bindings)
]

{ #category : 'private' }
ZealDesugarer >> mapPairsFor: aZealMapNode [
	"Return an array of #(slotSrc localSrc) pairs from a map node. Each pair
	 in #pairs is a ZealMapPairNode with #key (slot name) and #value (local
	 name) source."
	^ aZealMapNode pairs asArray collect: [ :pair |
		Array with: pair key source with: pair value source ]
]

{ #category : 'private' }
ZealDesugarer >> parseBindingItems: aZealVectorNode [
	"Walk a binding vector and produce ordered items in source-order.
	 - Symbol or ZealColonChainNode at name slot → bind { kind: #bind, nameSrc, valSrc }
	 - ZealVectorNode at name slot → positional destructuring (#destructurePositional)
	 - ZealMapNode at name slot → object destructuring (#destructureObject)
	 - ZealListNode at name slot → guard (#guard, no paired value)
	 nameSrc/valSrc are source strings so the emitter can splice them."
	| exprs items i n |
	exprs := aZealVectorNode expressions.
	items := OrderedCollection new.
	i := 1. n := exprs size.
	[ i <= n ] whileTrue: [
		| first |
		first := exprs at: i.
		(first isKindOf: ZealListNode)
			ifTrue: [
				items add: (Dictionary new
					at: #kind put: #guard;
					at: #exprSrc put: first source;
					yourself).
				i := i + 1 ]
			ifFalse: [
				| val valSrc |
				val := i + 1 <= n ifTrue: [ exprs at: i + 1 ] ifFalse: [ nil ].
				valSrc := val ifNotNil: [ val source ] ifNil: [ '' ].
				(first isKindOf: ZealVectorNode)
					ifTrue: [
						items add: (Dictionary new
							at: #kind put: #destructurePositional;
							at: #names put: ((first expressions collect: [ :e | e source ]) asArray);
							at: #valSrc put: valSrc;
							yourself) ]
				ifFalse: [ (first isKindOf: ZealMapNode)
					ifTrue: [
						items add: (Dictionary new
							at: #kind put: #destructureObject;
							at: #pairs put: (self mapPairsFor: first);
							at: #valSrc put: valSrc;
							yourself) ]
					ifFalse: [
						items add: (Dictionary new
							at: #kind put: #bind;
							at: #nameSrc put: first source;
							at: #valSrc put: valSrc;
							yourself) ] ].
				i := i + 2 ] ].
	^ items
]
