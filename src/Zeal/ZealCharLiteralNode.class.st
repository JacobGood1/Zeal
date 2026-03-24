Class {
	#name : 'ZealCharLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealCharLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitCharLiteral: self
]

{ #category : 'generated' }
ZealCharLiteralNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealCharLiteralNode >> value [
	^ value
]

{ #category : 'generated' }
ZealCharLiteralNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
