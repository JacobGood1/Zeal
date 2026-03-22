Class {
	#name : 'VerseProgramNode',
	#superclass : 'SmaCCParseNode',
	#instVars : [
		'statements'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseProgramNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitProgram: self
]

{ #category : 'generated' }
VerseProgramNode >> compositeNodeVariables [
	^ #(#statements)
]

{ #category : 'generated-initialize-release' }
VerseProgramNode >> initialize [
	super initialize.
	statements := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseProgramNode >> statements [
	^ statements
]

{ #category : 'generated' }
VerseProgramNode >> statements: anOrderedCollection [
	self setParents: self statements to: nil.
	statements := anOrderedCollection.
	self setParents: self statements to: self
]
