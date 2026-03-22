Class {
	#name : 'VerseFieldInitNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseFieldInitNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFieldInit: self
]

{ #category : 'generated' }
VerseFieldInitNode >> name [
	^ name
]

{ #category : 'generated' }
VerseFieldInitNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseFieldInitNode >> nodeVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseFieldInitNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseFieldInitNode >> value [
	^ value
]

{ #category : 'generated' }
VerseFieldInitNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
