Class {
	#name : 'ZealFileNode',
	#superclass : 'ZealFsNode',
	#instVars : [
		'fileRef'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealFileNode >> fileRef [
	^ fileRef
]

{ #category : 'accessing' }
ZealFileNode >> fileRef: aFileRef [
	"Setting the file reference also derives the display name from its
	 basenameWithoutExtension — files show as `Plain`, not `Plain.as`."
	fileRef := aFileRef.
	aFileRef ifNotNil: [ name := aFileRef basenameWithoutExtension ]
]

{ #category : 'testing' }
ZealFileNode >> isFile [
	^ true
]
