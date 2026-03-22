Class {
	#name : 'VerseMemberAccessNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'receiver',
		'member'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseMemberAccessNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitMemberAccess: self
]

{ #category : 'generated' }
VerseMemberAccessNode >> member [
	^ member
]

{ #category : 'generated' }
VerseMemberAccessNode >> member: aSmaCCToken [
	member := aSmaCCToken
]

{ #category : 'generated' }
VerseMemberAccessNode >> nodeVariables [
	^ #(#receiver)
]

{ #category : 'generated' }
VerseMemberAccessNode >> receiver [
	^ receiver
]

{ #category : 'generated' }
VerseMemberAccessNode >> receiver: aVerseProgramNode [
	self receiver notNil ifTrue: [ self receiver parent: nil ].
	receiver := aVerseProgramNode.
	self receiver notNil ifTrue: [ self receiver parent: self ]
]

{ #category : 'generated' }
VerseMemberAccessNode >> tokenVariables [
	^ #(#member)
]
