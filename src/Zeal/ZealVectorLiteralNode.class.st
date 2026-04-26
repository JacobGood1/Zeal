Class {
	#name : 'ZealVectorLiteralNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'leftMarker',
		'rightBracket'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealVectorLiteralNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitVectorLiteral: self
]

{ #category : 'accessing' }
ZealVectorLiteralNode >> dimensions [
	"Number of components in this vector literal — `->[1 2]` is 2D, `->[1 2 3]`
	 is 3D, etc. An empty `->[]` has zero dimensions."
	^ self expressions size
]

{ #category : 'testing' }
ZealVectorLiteralNode >> isVectorLiteral [
	^ true
]

{ #category : 'generated' }
ZealVectorLiteralNode >> leftMarker [
	^ leftMarker
]

{ #category : 'generated' }
ZealVectorLiteralNode >> leftMarker: aSmaCCToken [
	leftMarker := aSmaCCToken
]

{ #category : 'generated' }
ZealVectorLiteralNode >> rightBracket [
	^ rightBracket
]

{ #category : 'generated' }
ZealVectorLiteralNode >> rightBracket: aSmaCCToken [
	rightBracket := aSmaCCToken
]

{ #category : 'generated' }
ZealVectorLiteralNode >> tokenVariables [
	^ #(#leftMarker #rightBracket)
]
