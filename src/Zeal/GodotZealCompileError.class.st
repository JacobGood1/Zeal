Class {
	#name : 'GodotZealCompileError',
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
GodotZealCompileError >> compilerError [
	^ compilerError
]

{ #category : 'accessing' }
GodotZealCompileError >> compilerError: anError [
	compilerError := anError
]

{ #category : 'accessing' }
GodotZealCompileError >> linterDiags [
	^ linterDiags ifNil: [ #() ]
]

{ #category : 'accessing' }
GodotZealCompileError >> linterDiags: aCollection [
	linterDiags := aCollection
]

{ #category : 'accessing' }
GodotZealCompileError >> source [
	^ source
]

{ #category : 'accessing' }
GodotZealCompileError >> source: aString [
	source := aString
]
