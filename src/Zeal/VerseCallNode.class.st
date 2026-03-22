Class {
	#name : 'VerseCallNode',
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
VerseCallNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitCall: self
]

{ #category : 'generated' }
VerseCallNode >> args [
	^ args
]

{ #category : 'generated' }
VerseCallNode >> args: anOrderedCollection [
	self setParents: self args to: nil.
	args := anOrderedCollection.
	self setParents: self args to: self
]

{ #category : 'generated' }
VerseCallNode >> compositeNodeVariables [
	^ #(#args #statements)
]

{ #category : 'generated-initialize-release' }
VerseCallNode >> initialize [
	super initialize.
	args := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseCallNode >> nodeVariables [
	^ #(#receiver)
]

{ #category : 'generated' }
VerseCallNode >> receiver [
	^ receiver
]

{ #category : 'generated' }
VerseCallNode >> receiver: aVerseProgramNode [
	self receiver notNil ifTrue: [ self receiver parent: nil ].
	receiver := aVerseProgramNode.
	self receiver notNil ifTrue: [ self receiver parent: self ]
]
