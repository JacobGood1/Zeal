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
