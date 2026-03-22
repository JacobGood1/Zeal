Class {
	#name : 'VerseVarDefNode',
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
VerseVarDefNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitVarDef: self
]

{ #category : 'generated' }
VerseVarDefNode >> name [
	^ name
]

{ #category : 'generated' }
VerseVarDefNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseVarDefNode >> nodeVariables [
	^ #(#type #value)
]

{ #category : 'generated' }
VerseVarDefNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseVarDefNode >> type [
	^ type
]

{ #category : 'generated' }
VerseVarDefNode >> type: aVerseProgramNode [
	self type notNil ifTrue: [ self type parent: nil ].
	type := aVerseProgramNode.
	self type notNil ifTrue: [ self type parent: self ]
]

{ #category : 'generated' }
VerseVarDefNode >> value [
	^ value
]

{ #category : 'generated' }
VerseVarDefNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
