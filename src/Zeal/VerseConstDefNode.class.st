Class {
	#name : 'VerseConstDefNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'type',
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseConstDefNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitConstDef: self
]

{ #category : 'generated' }
VerseConstDefNode >> name [
	^ name
]

{ #category : 'generated' }
VerseConstDefNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseConstDefNode >> nodeVariables [
	^ #(#type #value)
]

{ #category : 'generated' }
VerseConstDefNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseConstDefNode >> type [
	^ type
]

{ #category : 'generated' }
VerseConstDefNode >> type: aVerseProgramNode [
	self type notNil ifTrue: [ self type parent: nil ].
	type := aVerseProgramNode.
	self type notNil ifTrue: [ self type parent: self ]
]

{ #category : 'generated' }
VerseConstDefNode >> value [
	^ value
]

{ #category : 'generated' }
VerseConstDefNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
