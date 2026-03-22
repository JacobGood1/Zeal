Class {
	#name : 'VerseCharLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseCharLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitCharLit: self
]

{ #category : 'generated' }
VerseCharLitNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseCharLitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseCharLitNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
