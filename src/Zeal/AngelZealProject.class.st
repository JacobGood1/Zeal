Class {
	#name : 'AngelZealProject',
	#superclass : 'Object',
	#instVars : [
		'name',
		'path',
		'rootFolder'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealProject >> childrenOf: aFolder [
	"Return (subdirs first, then Zeal/AngelScript files) for the given folder,
	 alphabetically within each group. Files are filtered to .zeal (source) and
	 .as (generated output) extensions; other entries are hidden."
	| dirs files children |
	children := [ aFolder children ] on: Error do: [ :e | #() ].
	dirs := (children select: [ :f | f isDirectory ])
		asSortedCollection: [ :a :b | a basename asLowercase < b basename asLowercase ].
	files := (children select: [ :f |
		f isFile and: [ #('zeal' 'as') includes: f extension ] ])
		asSortedCollection: [ :a :b | a basename asLowercase < b basename asLowercase ].
	^ (dirs asOrderedCollection) , (files asOrderedCollection)
]

{ #category : 'api' }
AngelZealProject >> name [
	^ name
]

{ #category : 'api' }
AngelZealProject >> name: aString [
	name := aString
]

{ #category : 'api' }
AngelZealProject >> path [
	^ path
]

{ #category : 'api' }
AngelZealProject >> path: aString [
	path := aString
]

{ #category : 'api' }
AngelZealProject >> rootFolder [
	^ rootFolder
]

{ #category : 'api' }
AngelZealProject >> scanFolder: aFileReference [
	"Attach the project to a root directory. No eager file enumeration — the
	 browser's tree walks the filesystem lazily via children."
	| ref |
	ref := aFileReference asFileReference.
	path := ref fullName.
	name := ref basename.
	rootFolder := ref.
	^ self
]
