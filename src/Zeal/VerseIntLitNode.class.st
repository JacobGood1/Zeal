Class {
	#name : 'VerseIntLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseIntLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitIntLit: self
]

{ #category : 'generated' }
VerseIntLitNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseIntLitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseIntLitNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
