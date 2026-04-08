Class {
	#name : 'GDZealCompileResult',
	#superclass : 'Object',
	#instVars : [
		'definitionName',
		'source',
		'generated',
		'gdPath'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
GDZealCompileResult >> definitionName [
	^ definitionName
]

{ #category : 'accessing' }
GDZealCompileResult >> definitionName: aName [
	definitionName := aName
]

{ #category : 'accessing' }
GDZealCompileResult >> gdPath [
	^ gdPath
]

{ #category : 'accessing' }
GDZealCompileResult >> gdPath: aPath [
	gdPath := aPath
]

{ #category : 'accessing' }
GDZealCompileResult >> generated [
	^ generated
]

{ #category : 'accessing' }
GDZealCompileResult >> generated: aString [
	generated := aString
]

{ #category : 'accessing' }
GDZealCompileResult >> source [
	^ source
]

{ #category : 'accessing' }
GDZealCompileResult >> source: aString [
	source := aString
]
