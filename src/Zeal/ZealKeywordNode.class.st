Class {
	#name : 'ZealKeywordNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealKeywordNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitKeyword: self
]

{ #category : 'generated' }
ZealKeywordNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealKeywordNode >> value [
	^ value
]

{ #category : 'generated' }
ZealKeywordNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
