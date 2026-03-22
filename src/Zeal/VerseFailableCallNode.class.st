Class {
	#name : 'VerseFailableCallNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'receiver',
		'args'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseFailableCallNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFailableCall: self
]

{ #category : 'generated' }
VerseFailableCallNode >> args [
	^ args
]

{ #category : 'generated' }
VerseFailableCallNode >> args: anOrderedCollection [
	self setParents: self args to: nil.
	args := anOrderedCollection.
	self setParents: self args to: self
]

{ #category : 'generated' }
VerseFailableCallNode >> compositeNodeVariables [
	^ #(#args #statements)
]

{ #category : 'generated-initialize-release' }
VerseFailableCallNode >> initialize [
	super initialize.
	args := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseFailableCallNode >> nodeVariables [
	^ #(#receiver)
]

{ #category : 'generated' }
VerseFailableCallNode >> receiver [
	^ receiver
]

{ #category : 'generated' }
VerseFailableCallNode >> receiver: aVerseProgramNode [
	self receiver notNil ifTrue: [ self receiver parent: nil ].
	receiver := aVerseProgramNode.
	self receiver notNil ifTrue: [ self receiver parent: self ]
]
