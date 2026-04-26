Class {
	#name : 'ZealFolderNode',
	#superclass : 'ZealFsNode',
	#instVars : [
		'fileRef'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealFolderNode >> fileRef [
	^ fileRef
]

{ #category : 'accessing' }
ZealFolderNode >> fileRef: aFileRef [
	"Setting the file reference also derives the display name from its
	 basename (folders show their full name including any extension)."
	fileRef := aFileRef.
	aFileRef ifNotNil: [ name := aFileRef basename ]
]

{ #category : 'testing' }
ZealFolderNode >> isFolder [
	^ true
]
