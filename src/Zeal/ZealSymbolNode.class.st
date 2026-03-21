Class {
	#name : 'ZealSymbolNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealSymbolNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitSymbol: self
]

{ #category : 'generated' }
ZealSymbolNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealSymbolNode >> value [
	^ value
]

{ #category : 'generated' }
ZealSymbolNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
