Class {
	#name : 'VerseMapEntryNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'key',
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseMapEntryNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitMapEntry: self
]

{ #category : 'generated' }
VerseMapEntryNode >> key [
	^ key
]

{ #category : 'generated' }
VerseMapEntryNode >> key: aVerseProgramNode [
	self key notNil ifTrue: [ self key parent: nil ].
	key := aVerseProgramNode.
	self key notNil ifTrue: [ self key parent: self ]
]

{ #category : 'generated' }
VerseMapEntryNode >> nodeVariables [
	^ #(#key #value)
]

{ #category : 'generated' }
VerseMapEntryNode >> value [
	^ value
]

{ #category : 'generated' }
VerseMapEntryNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
