Class {
	#name : 'ZealVectorLiteralExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'examples' }
ZealVectorLiteralExamples >> arrowAloneStaysSymbol [
	"Bare `->` (the threading macro) still parses as a ZealSymbolNode and
	 NOT as a vector literal — disambiguation works."
	<gtExample>
	| node |
	node := self parse: '->'.
	self assert: node class equals: ZealSymbolNode label: 'arrow alone is symbol'.
	self assert: node value value equals: '->' label: 'symbol text is ->'.
	^ node
]

{ #category : 'helpers' }
ZealVectorLiteralExamples >> assert: actual equals: expected label: label [
	actual = expected ifTrue: [ ^ self ].
	^ self error: label , ' — expected ' , expected printString
		, ' but got ' , actual printString
]

{ #category : 'helpers' }
ZealVectorLiteralExamples >> assert: aBoolean label: label [
	aBoolean ifTrue: [ ^ self ].
	^ self error: label , ' — expected true but got false'
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> emptyVector [
	"`->[]` parses as a zero-dimensional vector literal (still a vector node,
	 not an empty regular vector)."
	<gtExample>
	| node |
	node := self parse: '->[]'.
	self assert: node class equals: ZealVectorLiteralNode label: 'still vector literal'.
	self assert: node dimensions equals: 0 label: 'zero dimensions'.
	^ node
]

{ #category : 'helpers' }
ZealVectorLiteralExamples >> parse: aString [
	"Parse and return the first top-level expression."
	^ (ZealParser parse: aString) expressions first
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> regularVectorStillWorks [
	"`[1 2 3]` (no arrow prefix) remains a plain ZealVectorNode — the new
	 grammar doesn't accidentally absorb it as a vector literal."
	<gtExample>
	| node |
	node := self parse: '[1 2 3]'.
	self assert: node class equals: ZealVectorNode label: 'plain bracket vector unchanged'.
	self assert: node expressions size equals: 3 label: '3 elements'.
	^ node
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> threadingMacroPreserved [
	"`(-> a b c)` is the threading macro — must keep parsing as a list with
	 `->` as its head symbol, not as a vector literal."
	<gtExample>
	| node head |
	node := self parse: '(-> a b c)'.
	self assert: node class equals: ZealListNode label: 'outer list intact'.
	head := node expressions first.
	self assert: head class equals: ZealSymbolNode label: 'head is symbol'.
	self assert: head value value equals: '->' label: 'head is the -> threading macro'.
	^ node
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> vector2D [
	"`->[1 2]` parses as a 2D vector literal."
	<gtExample>
	| node |
	node := self parse: '->[1 2]'.
	self assert: node class equals: ZealVectorLiteralNode label: 'class is ZealVectorLiteralNode'.
	self assert: node dimensions equals: 2 label: '2 dimensions'.
	self assert: node isVectorLiteral label: 'isVectorLiteral predicate'.
	self assert: ((node expressions collect: [ :e | e class name ]) asArray)
		equals: #(#ZealIntegerLiteralNode #ZealIntegerLiteralNode)
		label: 'two integer literal children'.
	^ node
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> vector3D [
	"`->[1 2 3]` parses as a 3D vector literal."
	<gtExample>
	| node |
	node := self parse: '->[1 2 3]'.
	self assert: node class equals: ZealVectorLiteralNode label: 'class is ZealVectorLiteralNode'.
	self assert: node dimensions equals: 3 label: '3 dimensions'.
	self assert: ((node expressions collect: [ :e | e value value ]) asArray)
		equals: #('1' '2' '3') label: 'integer texts 1, 2, 3'.
	^ node
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> vector4DFloats [
	"`->[1.0 2.0 3.0 4.0]` parses as a 4D vector with float components."
	<gtExample>
	| node |
	node := self parse: '->[1.0 2.0 3.0 4.0]'.
	self assert: node dimensions equals: 4 label: '4 dimensions'.
	self assert: (node expressions allSatisfy: [ :e | e isKindOf: ZealFloatLiteralNode ])
		label: 'all components are floats'.
	^ node
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> vectorNestedInList [
	"`(set pos ->[1 2 3])` — vector literal as a child of a list expression."
	<gtExample>
	| node listExprs vec |
	node := self parse: '(set pos ->[1 2 3])'.
	self assert: node class equals: ZealListNode label: 'outer is a list'.
	listExprs := node expressions.
	self assert: listExprs size equals: 3 label: 'three list elements: set, pos, vector'.
	vec := listExprs third.
	self assert: vec class equals: ZealVectorLiteralNode label: 'third element is vector literal'.
	self assert: vec dimensions equals: 3 label: 'inner vector is 3D'.
	^ node
]

{ #category : 'examples' }
ZealVectorLiteralExamples >> vectorOfSymbols [
	"`->[x y z]` is a 3D vector of variable references — symbols, not literals."
	<gtExample>
	| node |
	node := self parse: '->[x y z]'.
	self assert: node dimensions equals: 3 label: '3 dimensions'.
	self assert: (node expressions allSatisfy: [ :e | e isKindOf: ZealSymbolNode ])
		label: 'all components are symbols'.
	self assert: ((node expressions collect: [ :e | e value value ]) asArray)
		equals: #('x' 'y' 'z') label: 'component names x y z'.
	^ node
]
