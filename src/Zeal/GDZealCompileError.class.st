Class {
	#name : 'GDZealCompileError',
	#superclass : 'Object',
	#instVars : [
		'source',
		'linterDiags',
		'compilerError'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
GDZealCompileError >> compilerError [
	^ compilerError
]

{ #category : 'accessing' }
GDZealCompileError >> compilerError: anError [
	compilerError := anError
]

{ #category : 'accessing' }
GDZealCompileError >> linterDiags [
	^ linterDiags ifNil: [ #() ]
]

{ #category : 'accessing' }
GDZealCompileError >> linterDiags: aCollection [
	linterDiags := aCollection
]

{ #category : 'accessing' }
GDZealCompileError >> source [
	^ source
]

{ #category : 'accessing' }
GDZealCompileError >> source: aString [
	source := aString
]
