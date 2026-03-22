Class {
	#name : 'VerseArrayTypeNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'inner'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseArrayTypeNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitArrayType: self
]

{ #category : 'generated' }
VerseArrayTypeNode >> inner [
	^ inner
]

{ #category : 'generated' }
VerseArrayTypeNode >> inner: aVerseProgramNode [
	self inner notNil ifTrue: [ self inner parent: nil ].
	inner := aVerseProgramNode.
	self inner notNil ifTrue: [ self inner parent: self ]
]

{ #category : 'generated' }
VerseArrayTypeNode >> nodeVariables [
	^ #(#inner)
]
