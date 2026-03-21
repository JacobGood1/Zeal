Class {
	#name : 'ZealMapPairNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'key',
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealMapPairNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitMapPair: self
]

{ #category : 'generated' }
ZealMapPairNode >> key [
	^ key
]

{ #category : 'generated' }
ZealMapPairNode >> key: aZealProgramNode [
	self key notNil ifTrue: [ self key parent: nil ].
	key := aZealProgramNode.
	self key notNil ifTrue: [ self key parent: self ]
]

{ #category : 'generated' }
ZealMapPairNode >> nodeVariables [
	^ #(#key #value)
]

{ #category : 'generated' }
ZealMapPairNode >> value [
	^ value
]

{ #category : 'generated' }
ZealMapPairNode >> value: aZealProgramNode [
	self value notNil ifTrue: [ self value parent: nil ].
	value := aZealProgramNode.
	self value notNil ifTrue: [ self value parent: self ]
]
