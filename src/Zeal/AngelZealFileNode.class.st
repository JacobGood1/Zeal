Class {
	#name : 'AngelZealFileNode',
	#superclass : 'AngelZealNode',
	#instVars : [
		'fileRef'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealFileNode >> fileRef [
	^ fileRef
]

{ #category : 'api' }
AngelZealFileNode >> fileRef: aFileReference [
	fileRef := aFileReference.
	name := aFileReference basenameWithoutExtension
]

{ #category : 'api' }
AngelZealFileNode >> isFile [
	^ true
]
