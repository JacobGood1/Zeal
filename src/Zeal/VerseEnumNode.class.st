Class {
	#name : 'VerseEnumNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'specs',
		'values'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseEnumNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitEnum: self
]

{ #category : 'generated' }
VerseEnumNode >> compositeTokenVariables [
	^ #(#specs #values)
]

{ #category : 'generated-initialize-release' }
VerseEnumNode >> initialize [
	super initialize.
	specs := OrderedCollection new: 2.
	values := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseEnumNode >> name [
	^ name
]

{ #category : 'generated' }
VerseEnumNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseEnumNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseEnumNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseEnumNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseEnumNode >> values [
	^ values
]

{ #category : 'generated' }
VerseEnumNode >> values: anOrderedCollection [
	values := anOrderedCollection
]
