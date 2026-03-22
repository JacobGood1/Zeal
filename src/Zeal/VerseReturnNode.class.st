Class {
	#name : 'VerseReturnNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseReturnNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitReturn: self
]

{ #category : 'generated' }
VerseReturnNode >> nodeVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseReturnNode >> value [
	^ value
]

{ #category : 'generated' }
VerseReturnNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
