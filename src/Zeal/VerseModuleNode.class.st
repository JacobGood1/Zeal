Class {
	#name : 'VerseModuleNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'specs'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseModuleNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitModule: self
]

{ #category : 'generated' }
VerseModuleNode >> compositeTokenVariables [
	^ #(#specs)
]

{ #category : 'generated-initialize-release' }
VerseModuleNode >> initialize [
	super initialize.
	specs := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseModuleNode >> name [
	^ name
]

{ #category : 'generated' }
VerseModuleNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseModuleNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseModuleNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseModuleNode >> tokenVariables [
	^ #(#name)
]
