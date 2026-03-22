Class {
	#name : 'VerseHexLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseHexLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitHexLit: self
]

{ #category : 'generated' }
VerseHexLitNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseHexLitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseHexLitNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
