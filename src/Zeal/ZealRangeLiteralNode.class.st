Class {
	#name : 'ZealRangeLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealRangeLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitRangeLiteral: self
]

{ #category : 'generated' }
ZealRangeLiteralNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealRangeLiteralNode >> value [
	^ value
]

{ #category : 'generated' }
ZealRangeLiteralNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
