Class {
	#name : 'VerseSetNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'target',
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseSetNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitSet: self
]

{ #category : 'generated' }
VerseSetNode >> nodeVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseSetNode >> target [
	^ target
]

{ #category : 'generated' }
VerseSetNode >> target: aSmaCCToken [
	target := aSmaCCToken
]

{ #category : 'generated' }
VerseSetNode >> tokenVariables [
	^ #(#target)
]

{ #category : 'generated' }
VerseSetNode >> value [
	^ value
]

{ #category : 'generated' }
VerseSetNode >> value: aVerseProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aVerseProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
