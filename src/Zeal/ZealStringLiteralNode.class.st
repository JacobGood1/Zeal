Class {
	#name : 'ZealStringLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealStringLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitStringLiteral: self
]

{ #category : 'generated' }
ZealStringLiteralNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealStringLiteralNode >> value [
	^ value
]

{ #category : 'generated' }
ZealStringLiteralNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
