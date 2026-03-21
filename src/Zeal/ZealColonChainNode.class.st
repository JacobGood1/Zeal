Class {
	#name : 'ZealColonChainNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealColonChainNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitColonChain: self
]

{ #category : 'generated' }
ZealColonChainNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealColonChainNode >> value [
	^ value
]

{ #category : 'generated' }
ZealColonChainNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
