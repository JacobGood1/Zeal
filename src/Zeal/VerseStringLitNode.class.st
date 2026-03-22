Class {
	#name : 'VerseStringLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseStringLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitStringLit: self
]

{ #category : 'generated' }
VerseStringLitNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseStringLitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseStringLitNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
