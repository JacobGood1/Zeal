Class {
	#name : 'VerseMapLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'entries'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseMapLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitMapLit: self
]

{ #category : 'generated' }
VerseMapLitNode >> compositeNodeVariables [
	^ #(#entries #statements)
]

{ #category : 'generated' }
VerseMapLitNode >> entries [
	^ entries
]

{ #category : 'generated' }
VerseMapLitNode >> entries: anOrderedCollection [
	self setParents: self entries to: nil.
	entries := anOrderedCollection.
	self setParents: self entries to: self
]

{ #category : 'generated-initialize-release' }
VerseMapLitNode >> initialize [
	super initialize.
	entries := OrderedCollection new: 2.
]
