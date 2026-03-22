Class {
	#name : 'VerseMapTypeNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'key',
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseMapTypeNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitMapType: self
]

{ #category : 'generated' }
VerseMapTypeNode >> key [
	^ key
]

{ #category : 'generated' }
VerseMapTypeNode >> key: aVerseProgramNode [
	self key notNil ifTrue: [ self key parent: nil ].
	key := aVerseProgramNode.
	self key notNil ifTrue: [ self key parent: self ]
]

{ #category : 'generated' }
VerseMapTypeNode >> nodeVariables [
	^ #(#key #value)
]

{ #category : 'generated' }
VerseMapTypeNode >> value [
	^ value
]

{ #category : 'generated' }
VerseMapTypeNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
