Class {
	#name : 'VerseOptionalNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'inner'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseOptionalNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitOptional: self
]

{ #category : 'generated' }
VerseOptionalNode >> inner [
	^ inner
]

{ #category : 'generated' }
VerseOptionalNode >> inner: aVerseProgramNode [
	self inner notNil ifTrue: [ self inner parent: nil ].
	inner := aVerseProgramNode.
	self inner notNil ifTrue: [ self inner parent: self ]
]

{ #category : 'generated' }
VerseOptionalNode >> nodeVariables [
	^ #(#inner)
]
