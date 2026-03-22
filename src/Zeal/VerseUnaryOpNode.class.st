Class {
	#name : 'VerseUnaryOpNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'op',
		'operand'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseUnaryOpNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitUnaryOp: self
]

{ #category : 'generated' }
VerseUnaryOpNode >> nodeVariables [
	^ #(#operand)
]

{ #category : 'generated' }
VerseUnaryOpNode >> op [
	^ op
]

{ #category : 'generated' }
VerseUnaryOpNode >> op: aSmaCCToken [
	op := aSmaCCToken
]

{ #category : 'generated' }
VerseUnaryOpNode >> operand [
	^ operand
]

{ #category : 'generated' }
VerseUnaryOpNode >> operand: aVerseProgramNode [
	self operand notNil ifTrue: [ self operand parent: nil ].
	operand := aVerseProgramNode.
	self operand notNil ifTrue: [ self operand parent: self ]
]

{ #category : 'generated' }
VerseUnaryOpNode >> tokenVariables [
	^ #(#op)
]
