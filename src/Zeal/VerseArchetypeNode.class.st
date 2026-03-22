Class {
	#name : 'VerseArchetypeNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'receiver',
		'inits'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseArchetypeNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitArchetype: self
]

{ #category : 'generated' }
VerseArchetypeNode >> compositeNodeVariables [
	^ #(#inits #statements)
]

{ #category : 'generated-initialize-release' }
VerseArchetypeNode >> initialize [
	super initialize.
	inits := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseArchetypeNode >> inits [
	^ inits
]

{ #category : 'generated' }
VerseArchetypeNode >> inits: anOrderedCollection [
	self setParents: self inits to: nil.
	inits := anOrderedCollection.
	self setParents: self inits to: self
]

{ #category : 'generated' }
VerseArchetypeNode >> nodeVariables [
	^ #(#receiver)
]

{ #category : 'generated' }
VerseArchetypeNode >> receiver [
	^ receiver
]

{ #category : 'generated' }
VerseArchetypeNode >> receiver: aVerseProgramNode [
	self receiver notNil ifTrue: [ self receiver parent: nil ].
	receiver := aVerseProgramNode.
	self receiver notNil ifTrue: [ self receiver parent: self ]
]
