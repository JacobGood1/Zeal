Class {
	#name : 'VerseUsingDefNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'path'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseUsingDefNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitUsingDef: self
]

{ #category : 'generated' }
VerseUsingDefNode >> path [
	^ path
]

{ #category : 'generated' }
VerseUsingDefNode >> path: aSmaCCToken [
	path := aSmaCCToken
]

{ #category : 'generated' }
VerseUsingDefNode >> tokenVariables [
	^ #(#path)
]
