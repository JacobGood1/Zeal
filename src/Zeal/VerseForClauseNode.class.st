Class {
	#name : 'VerseForClauseNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'collection',
		'range'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseForClauseNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitForClause: self
]

{ #category : 'generated' }
VerseForClauseNode >> collection [
	^ collection
]

{ #category : 'generated' }
VerseForClauseNode >> collection: aVerseProgramNode [
	self collection notNil ifTrue: [ self collection parent: nil ].
	collection := aVerseProgramNode.
	self collection notNil ifTrue: [ self collection parent: self ]
]

{ #category : 'generated' }
VerseForClauseNode >> name [
	^ name
]

{ #category : 'generated' }
VerseForClauseNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseForClauseNode >> nodeVariables [
	^ #(#collection #range)
]

{ #category : 'generated' }
VerseForClauseNode >> range [
	^ range
]

{ #category : 'generated' }
VerseForClauseNode >> range: aVerseProgramNode [
	self range notNil ifTrue: [ self range parent: nil ].
	range := aVerseProgramNode.
	self range notNil ifTrue: [ self range parent: self ]
]

{ #category : 'generated' }
VerseForClauseNode >> tokenVariables [
	^ #(#name)
]
