Class {
	#name : 'VerseIfNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'conds',
		'names',
		'values'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseIfNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitIf: self
]

{ #category : 'generated' }
VerseIfNode >> compositeNodeVariables [
	^ #(#conds #values #statements)
]

{ #category : 'generated' }
VerseIfNode >> compositeTokenVariables [
	^ #(#names)
]

{ #category : 'generated' }
VerseIfNode >> conds [
	^ conds
]

{ #category : 'generated' }
VerseIfNode >> conds: anOrderedCollection [
	self setParents: self conds to: nil.
	conds := anOrderedCollection.
	self setParents: self conds to: self
]

{ #category : 'generated-initialize-release' }
VerseIfNode >> initialize [
	super initialize.
	conds := OrderedCollection new: 2.
	names := OrderedCollection new: 2.
	values := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseIfNode >> names [
	^ names
]

{ #category : 'generated' }
VerseIfNode >> names: anOrderedCollection [
	names := anOrderedCollection
]

{ #category : 'generated' }
VerseIfNode >> values [
	^ values
]

{ #category : 'generated' }
VerseIfNode >> values: anOrderedCollection [
	self setParents: self values to: nil.
	values := anOrderedCollection.
	self setParents: self values to: self
]
