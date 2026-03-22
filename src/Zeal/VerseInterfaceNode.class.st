Class {
	#name : 'VerseInterfaceNode',
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
VerseInterfaceNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitInterface: self
]

{ #category : 'generated' }
VerseInterfaceNode >> compositeTokenVariables [
	^ #(#specs #parents)
]

{ #category : 'generated-initialize-release' }
VerseInterfaceNode >> initialize [
	super initialize.
	specs := OrderedCollection new: 2.
	parents := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseInterfaceNode >> name [
	^ name
]

{ #category : 'generated' }
VerseInterfaceNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseInterfaceNode >> parents [
	^ parents
]

{ #category : 'generated' }
VerseInterfaceNode >> parents: anOrderedCollection [
	parents := anOrderedCollection
]

{ #category : 'generated' }
VerseInterfaceNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseInterfaceNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseInterfaceNode >> tokenVariables [
	^ #(#name)
]
