Class {
	#name : 'VerseClassNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'specs',
		'parents'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseClassNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitClass: self
]

{ #category : 'generated' }
VerseClassNode >> compositeTokenVariables [
	^ #(#specs #parents)
]

{ #category : 'generated-initialize-release' }
VerseClassNode >> initialize [
	super initialize.
	specs := OrderedCollection new: 2.
	parents := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseClassNode >> name [
	^ name
]

{ #category : 'generated' }
VerseClassNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseClassNode >> parents [
	^ parents
]

{ #category : 'generated' }
VerseClassNode >> parents: anOrderedCollection [
	parents := anOrderedCollection
]

{ #category : 'generated' }
VerseClassNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseClassNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseClassNode >> tokenVariables [
	^ #(#name)
]
