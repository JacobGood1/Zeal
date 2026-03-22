Class {
	#name : 'VerseFuncParamNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'name',
		'params',
		'specs',
		'type'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseFuncParamNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitFuncParam: self
]

{ #category : 'generated' }
VerseFuncParamNode >> compositeNodeVariables [
	^ #(#params #statements)
]

{ #category : 'generated' }
VerseFuncParamNode >> compositeTokenVariables [
	^ #(#specs)
]

{ #category : 'generated-initialize-release' }
VerseFuncParamNode >> initialize [
	super initialize.
	params := OrderedCollection new: 2.
	specs := OrderedCollection new: 2.
]

{ #category : 'generated' }
VerseFuncParamNode >> name [
	^ name
]

{ #category : 'generated' }
VerseFuncParamNode >> name: aSmaCCToken [
	name := aSmaCCToken
]

{ #category : 'generated' }
VerseFuncParamNode >> nodeVariables [
	^ #(#type)
]

{ #category : 'generated' }
VerseFuncParamNode >> params [
	^ params
]

{ #category : 'generated' }
VerseFuncParamNode >> params: anOrderedCollection [
	self setParents: self params to: nil.
	params := anOrderedCollection.
	self setParents: self params to: self
]

{ #category : 'generated' }
VerseFuncParamNode >> specs [
	^ specs
]

{ #category : 'generated' }
VerseFuncParamNode >> specs: anOrderedCollection [
	specs := anOrderedCollection
]

{ #category : 'generated' }
VerseFuncParamNode >> tokenVariables [
	^ #(#name)
]

{ #category : 'generated' }
VerseFuncParamNode >> type [
	^ type
]

{ #category : 'generated' }
VerseFuncParamNode >> type: aVerseProgramNode [
	self type notNil ifTrue: [ self type parent: nil ].
	type := aVerseProgramNode.
	self type notNil ifTrue: [ self type parent: self ]
]
