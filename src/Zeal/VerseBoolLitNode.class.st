Class {
	#name : 'VerseBoolLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseBoolLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitBoolLit: self
]

{ #category : 'generated' }
VerseBoolLitNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseBoolLitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseBoolLitNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
