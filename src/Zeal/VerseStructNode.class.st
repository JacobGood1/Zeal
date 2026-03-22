Class {
	#name : 'VerseStructNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'specs',
		'parents'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseStructNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitStruct: self
]

{ #category : 'generated' }
VerseStructNode >> compositeTokenVariables [
	^ #(#specs #parents)
]

{ #category : 'generated-initialize-release' }
VerseStructNode >> initialize [
	super initialize.
	specs := OrderedCollection new: 2.
	parents := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseStructNode >> name [
	^ name
]

{ #category : 'generated' }
VerseStructNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseStructNode >> parents [
	^ parents
]

{ #category : 'generated' }
VerseStructNode >> parents: anOrderedCollection [
	parents := anOrderedCollection
]

{ #category : 'generated' }
VerseStructNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseStructNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseStructNode >> tokenVariables [
	^ #(#name)
]
