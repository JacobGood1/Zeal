Class {
	#name : 'VerseArrayLitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'args'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseArrayLitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitArrayLit: self
]

{ #category : 'generated' }
VerseArrayLitNode >> args [
	^ args
]

{ #category : 'generated' }
VerseArrayLitNode >> args: anOrderedCollection [
	self setParents: self args to: nil.
	args := anOrderedCollection.
	self setParents: self args to: self
]

{ #category : 'generated' }
VerseArrayLitNode >> compositeNodeVariables [
	^ #(#args #statements)
]

{ #category : 'generated-initialize-release' }
VerseArrayLitNode >> initialize [
	super initialize.
	args := OrderedCollection new: 2.
]
