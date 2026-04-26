Class {
	#name : 'AngelZealFolderNode',
	#superclass : 'AngelZealNode',
	#instVars : [
		'fileRef'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealFolderNode >> fileRef [
	^ fileRef
]

{ #category : 'api' }
AngelZealFolderNode >> fileRef: aFileReference [
	fileRef := aFileReference.
	name := aFileReference basename
]

{ #category : 'api' }
AngelZealFolderNode >> isFolder [
	^ true
]
