Class {
	#name : 'VerseBinOpNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'left',
		'op',
		'right'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseBinOpNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitBinOp: self
]

{ #category : 'generated' }
VerseBinOpNode >> left [
	^ left
]

{ #category : 'generated' }
VerseBinOpNode >> left: aVerseProgramNode [
	self left notNil ifTrue: [ self left parent: nil ].
	left := aVerseProgramNode.
	self left notNil ifTrue: [ self left parent: self ]
]

{ #category : 'generated' }
VerseBinOpNode >> nodeVariables [
	^ #(#left #right)
]

{ #category : 'generated' }
VerseBinOpNode >> op [
	^ op
]

{ #category : 'generated' }
VerseBinOpNode >> op: aSmaCCToken [
	op := aSmaCCToken
]

{ #category : 'generated' }
VerseBinOpNode >> right [
	^ right
]

{ #category : 'generated' }
VerseBinOpNode >> right: aVerseProgramNode [
	self right notNil ifTrue: [ self right parent: nil ].
	right := aVerseProgramNode.
	self right notNil ifTrue: [ self right parent: self ]
]

{ #category : 'generated' }
VerseBinOpNode >> tokenVariables [
	^ #(#op)
]
