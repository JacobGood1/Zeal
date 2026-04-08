Class {
	#name : 'ZealCodeGenerator',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'indentLevel'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'protocol' }
ZealCodeGenerator class >> transducerFormSelectors [
	"The Zeal transducer protocol — a name -> selector dictionary that every concrete
	 dialect (GDZeal, VZeal, ...) must implement. Each dialect mixes this into its own
	 specialForms table; the actual code-emission methods live on the dialect class
	 because the right output depends entirely on the target language."
	^ Dictionary new
		at: 'map' put: #generateMap:;
		at: 'filter' put: #generateFilter:;
		at: 'reduce' put: #generateReduce:;
		at: 'range' put: #generateRange:;
		at: 'take' put: #generateTake:;
		at: 'drop' put: #generateDrop:;
		yourself
]

{ #category : 'emitting' }
ZealCodeGenerator >> dedent [
	indentLevel := indentLevel - 1
]

{ #category : 'emitting' }
ZealCodeGenerator >> emit: aString [
	stream nextPutAll: aString
]

{ #category : 'emitting' }
ZealCodeGenerator >> emitIndent [
	indentLevel timesRepeat: [ stream nextPutAll: '    ' ]
]

{ #category : 'generating' }
ZealCodeGenerator >> generate: aZealProgramNode [
	aZealProgramNode expressions do: [:expr |
		self visitExpression: expr ] separatedBy: [ self nl. self nl ].
	^ self output
]

{ #category : 'emitting' }
ZealCodeGenerator >> indent [
	indentLevel := indentLevel + 1
]

{ #category : 'initialization' }
ZealCodeGenerator >> initialize [
	super initialize.
	stream := WriteStream on: String new.
	indentLevel := 0
]

{ #category : 'accessing' }
ZealCodeGenerator >> output [
	^ stream contents
]

{ #category : 'visiting' }
ZealCodeGenerator >> visitExpression: aNode [
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self visitList: aNode ].
	(aNode isKindOf: ZealVectorNode) ifTrue: [ ^ self visitVector: aNode ].
	(aNode isKindOf: ZealMapNode) ifTrue: [ ^ self visitMap: aNode ].
	^ self visitAtom: aNode
]
