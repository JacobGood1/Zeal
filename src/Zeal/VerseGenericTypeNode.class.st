Class {
	#name : 'VerseGenericTypeNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'args'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseGenericTypeNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitGenericType: self
]

{ #category : 'generated' }
VerseGenericTypeNode >> args [
	^ args
]

{ #category : 'generated' }
VerseGenericTypeNode >> args: anOrderedCollection [
	self setParents: self args to: nil.
	args := anOrderedCollection.
	self setParents: self args to: self
]

{ #category : 'generated' }
VerseGenericTypeNode >> compositeNodeVariables [
	^ #(#args #statements)
]

{ #category : 'generated-initialize-release' }
VerseGenericTypeNode >> initialize [
	super initialize.
	args := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseGenericTypeNode >> name [
	^ name
]

{ #category : 'generated' }
VerseGenericTypeNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseGenericTypeNode >> tokenVariables [
	^ #(#name)
]
