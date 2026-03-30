Class {
	#name : 'ZealTreeGroup',
	#superclass : 'Object',
	#instVars : [
		'name',
		'items'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealTreeGroup >> items [
	^ items
]

{ #category : 'accessing' }
ZealTreeGroup >> items: aCollection [
	items := aCollection
]

{ #category : 'accessing' }
ZealTreeGroup >> name [
	^ name
]

{ #category : 'accessing' }
ZealTreeGroup >> name: aString [
	name := aString
]
