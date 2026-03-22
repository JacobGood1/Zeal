Class {
	#name : 'VerseQueryNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'receiver'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseQueryNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitQuery: self
]

{ #category : 'generated' }
VerseQueryNode >> nodeVariables [
	^ #(#receiver)
]

{ #category : 'generated' }
VerseQueryNode >> receiver [
	^ receiver
]

{ #category : 'generated' }
VerseQueryNode >> receiver: aVerseProgramNode [
	self receiver notNil ifTrue: [ self receiver parent: nil ].
	receiver := aVerseProgramNode.
	self receiver notNil ifTrue: [ self receiver parent: self ]
]
