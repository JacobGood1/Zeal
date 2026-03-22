Class {
	#name : 'VerseParamNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'type'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseParamNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitParam: self
]

{ #category : 'generated' }
VerseParamNode >> name [
	^ name
]

{ #category : 'generated' }
VerseParamNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseParamNode >> nodeVariables [
	^ #(#type)
]

{ #category : 'generated' }
VerseParamNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseParamNode >> type [
	^ type
]

{ #category : 'generated' }
VerseParamNode >> type: aVerseProgramNode [
	self type notNil ifTrue: [ self type parent: nil ].
	type := aVerseProgramNode.
	self type notNil ifTrue: [ self type parent: self ]
]
