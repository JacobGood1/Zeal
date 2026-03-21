Class {
	#name : 'ZealIntegerLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealIntegerLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitIntegerLiteral: self
]

{ #category : 'generated' }
ZealIntegerLiteralNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealIntegerLiteralNode >> value [
	^ value
]

{ #category : 'generated' }
ZealIntegerLiteralNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
