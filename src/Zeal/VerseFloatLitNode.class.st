Class {
	#name : 'VerseFloatLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseFloatLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFloatLit: self
]

{ #category : 'generated' }
VerseFloatLitNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseFloatLitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseFloatLitNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
