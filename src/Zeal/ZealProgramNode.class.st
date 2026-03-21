Class {
	#name : 'ZealProgramNode',
	#superclass : 'SmaCCParseNode',
	#instVars : [
		'expressions'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealProgramNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitProgram: self
]

{ #category : 'generated' }
ZealProgramNode >> compositeNodeVariables [
	^ #(#expressions)
]

{ #category : 'generated' }
ZealProgramNode >> expressions [
	^ expressions
]

{ #category : 'generated' }
ZealProgramNode >> expressions: anOrderedCollection [
	self setParents: self expressions to: nil.
	expressions := anOrderedCollection.
	self setParents: self expressions to: self
]

{ #category : 'generated-initialize-release' }
ZealProgramNode >> initialize [
	super initialize.
	expressions := OrderedCollection new: 2.
]
