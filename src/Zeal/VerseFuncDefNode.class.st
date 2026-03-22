Class {
	#name : 'VerseFuncDefNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'specs',
		'params',
		'type',
		'body'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseFuncDefNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFuncDef: self
]

{ #category : 'generated' }
VerseFuncDefNode >> body [
	^ body
]

{ #category : 'generated' }
VerseFuncDefNode >> body: aVerseProgramNode [
	self body notNil ifTrue: [ self body parent: nil ].
	body := aVerseProgramNode.
	self body notNil ifTrue: [ self body parent: self ]
]

{ #category : 'generated' }
VerseFuncDefNode >> compositeNodeVariables [
	^ #(#params #statements)
]

{ #category : 'generated' }
VerseFuncDefNode >> compositeTokenVariables [
	^ #(#specs)
]

{ #category : 'generated-initialize-release' }
VerseFuncDefNode >> initialize [
	super initialize.
	specs := OrderedCollection new: 2.
	params := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseFuncDefNode >> name [
	^ name
]

{ #category : 'generated' }
VerseFuncDefNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseFuncDefNode >> nodeVariables [
	^ #(#type #body)
]

{ #category : 'generated' }
VerseFuncDefNode >> params [
	^ params
]

{ #category : 'generated' }
VerseFuncDefNode >> params: anOrderedCollection [
	self setParents: self params to: nil.
	params := anOrderedCollection.
	self setParents: self params to: self
]

{ #category : 'generated' }
VerseFuncDefNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseFuncDefNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseFuncDefNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseFuncDefNode >> type [
	^ type
]

{ #category : 'generated' }
VerseFuncDefNode >> type: aVerseProgramNode [
	self type notNil ifTrue: [ self type parent: nil ].
	type := aVerseProgramNode.
	self type notNil ifTrue: [ self type parent: self ]
]
