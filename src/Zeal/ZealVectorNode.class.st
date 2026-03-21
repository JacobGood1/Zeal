Class {
	#name : 'ZealVectorNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'leftBracket',
		'rightBracket'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealVectorNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitVector: self
]

{ #category : 'generated' }
ZealVectorNode >> leftBracket [
	^ leftBracket
]

{ #category : 'generated' }
ZealVectorNode >> leftBracket: aSmaCCToken [
	leftBracket := aSmaCCToken
]

{ #category : 'generated' }
ZealVectorNode >> rightBracket [
	^ rightBracket
]

{ #category : 'generated' }
ZealVectorNode >> rightBracket: aSmaCCToken [
	rightBracket := aSmaCCToken
]

{ #category : 'generated' }
ZealVectorNode >> tokenVariables [
	^ #(#leftBracket #rightBracket)
]
