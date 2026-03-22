Class {
	#name : 'VerseForNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'clauses'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseForNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFor: self
]

{ #category : 'generated' }
VerseForNode >> clauses [
	^ clauses
]

{ #category : 'generated' }
VerseForNode >> clauses: anOrderedCollection [
	self setParents: self clauses to: nil.
	clauses := anOrderedCollection.
	self setParents: self clauses to: self
]

{ #category : 'generated' }
VerseForNode >> compositeNodeVariables [
	^ #(#clauses #statements)
]

{ #category : 'generated-initialize-release' }
VerseForNode >> initialize [
	super initialize.
	clauses := OrderedCollection new: 2.
]
