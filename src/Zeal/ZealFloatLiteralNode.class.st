Class {
	#name : 'ZealFloatLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealFloatLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFloatLiteral: self
]

{ #category : 'generated' }
ZealFloatLiteralNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealFloatLiteralNode >> value [
	^ value
]

{ #category : 'generated' }
ZealFloatLiteralNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
