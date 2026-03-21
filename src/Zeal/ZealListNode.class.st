Class {
	#name : 'ZealListNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'leftParen',
		'rightParen'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealListNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitList: self
]

{ #category : 'generated' }
ZealListNode >> leftParen [
	^ leftParen
]

{ #category : 'generated' }
ZealListNode >> leftParen: aSmaCCToken [
	leftParen := aSmaCCToken
]

{ #category : 'generated' }
ZealListNode >> rightParen [
	^ rightParen
]

{ #category : 'generated' }
ZealListNode >> rightParen: aSmaCCToken [
	rightParen := aSmaCCToken
]

{ #category : 'generated' }
ZealListNode >> tokenVariables [
	^ #(#leftParen #rightParen)
]
