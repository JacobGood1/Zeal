Class {
	#name : 'ZealMapNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'leftBrace',
		'pairs',
		'rightBrace'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealMapNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitMap: self
]

{ #category : 'generated' }
ZealMapNode >> compositeNodeVariables [
	^ #(#pairs #expressions)
]

{ #category : 'generated-initialize-release' }
ZealMapNode >> initialize [
	super initialize.
	pairs := OrderedCollection new: 2.
]

{ #category : 'generated' }
ZealMapNode >> leftBrace [
	^ leftBrace
]

{ #category : 'generated' }
ZealMapNode >> leftBrace: aSmaCCToken [
	leftBrace := aSmaCCToken
]

{ #category : 'generated' }
ZealMapNode >> pairs [
	^ pairs
]

{ #category : 'generated' }
ZealMapNode >> pairs: anOrderedCollection [
	self setParents: self pairs to: nil.
	pairs := anOrderedCollection.
	self setParents: self pairs to: self
]

{ #category : 'generated' }
ZealMapNode >> rightBrace [
	^ rightBrace
]

{ #category : 'generated' }
ZealMapNode >> rightBrace: aSmaCCToken [
	rightBrace := aSmaCCToken
]

{ #category : 'generated' }
ZealMapNode >> tokenVariables [
	^ #(#leftBrace #rightBrace)
]
