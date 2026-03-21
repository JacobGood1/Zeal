Class {
	#name : 'ZealCompiler',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealCompiler class >> compile: aString [
	| ast gen |
	ast := ZealParser parse: aString.
	gen := ZealCodeGenerator new.
	^ gen generate: ast
]

{ #category : 'compiling' }
ZealCompiler class >> parseOnly: aString [
	^ ZealParser parse: aString
]
