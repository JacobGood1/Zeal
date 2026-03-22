Class {
	#name : 'VerseAnnotatedDefNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'annotation',
		'definition'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseAnnotatedDefNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitAnnotatedDef: self
]

{ #category : 'generated' }
VerseAnnotatedDefNode >> annotation [
	^ annotation
]

{ #category : 'generated' }
VerseAnnotatedDefNode >> annotation: aSmaCCToken [
	annotation := aSmaCCToken
]

{ #category : 'generated' }
VerseAnnotatedDefNode >> definition [
	^ definition
]

{ #category : 'generated' }
VerseAnnotatedDefNode >> definition: aVerseProgramNode [
	self definition notNil ifTrue: [ self definition parent: nil ].
	definition := aVerseProgramNode.
	self definition notNil ifTrue: [ self definition parent: self ]
]

{ #category : 'generated' }
VerseAnnotatedDefNode >> nodeVariables [
	^ #(#definition)
]

{ #category : 'generated' }
VerseAnnotatedDefNode >> tokenVariables [
	^ #(#annotation)
]
