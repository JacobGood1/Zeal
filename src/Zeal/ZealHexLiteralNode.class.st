Class {
	#name : 'ZealHexLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealHexLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitHexLiteral: self
]

{ #category : 'generated' }
ZealHexLiteralNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealHexLiteralNode >> value [
	^ value
]

{ #category : 'generated' }
ZealHexLiteralNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
