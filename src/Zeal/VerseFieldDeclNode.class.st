Class {
	#name : 'VerseFieldDeclNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'type'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseFieldDeclNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFieldDecl: self
]

{ #category : 'generated' }
VerseFieldDeclNode >> name [
	^ name
]

{ #category : 'generated' }
VerseFieldDeclNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseFieldDeclNode >> nodeVariables [
	^ #(#type)
]

{ #category : 'generated' }
VerseFieldDeclNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseFieldDeclNode >> type [
	^ type
]

{ #category : 'generated' }
VerseFieldDeclNode >> type: aVerseProgramNode [
	self type notNil ifTrue: [ self type parent: nil ].
	type := aVerseProgramNode.
	self type notNil ifTrue: [ self type parent: self ]
]
