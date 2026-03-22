Class {
	#name : 'VerseNamedNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseNamedNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitNamed: self
]

{ #category : 'generated' }
VerseNamedNode >> name [
	^ name
]

{ #category : 'generated' }
VerseNamedNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseNamedNode >> tokenVariables [
	^ #(#name)
]
