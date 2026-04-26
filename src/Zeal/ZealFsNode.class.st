Class {
	#name : 'ZealFsNode',
	#superclass : 'Object',
	#instVars : [
		'parent',
		'name',
		'children'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'building' }
ZealFsNode >> addChild: aNode [
	aNode parent: self.
	children add: aNode.
	^ aNode
]

{ #category : 'accessing' }
ZealFsNode >> children [
	^ children
]

{ #category : 'initialize-release' }
ZealFsNode >> initialize [
	super initialize.
	children := OrderedCollection new
]

{ #category : 'testing' }
ZealFsNode >> isDefinition [
	^ false
]

{ #category : 'testing' }
ZealFsNode >> isFile [
	^ false
]

{ #category : 'testing' }
ZealFsNode >> isFolder [
	^ false
]

{ #category : 'accessing' }
ZealFsNode >> name [
	^ name
]

{ #category : 'accessing' }
ZealFsNode >> name: aString [
	name := aString
]

{ #category : 'accessing' }
ZealFsNode >> parent [
	^ parent
]

{ #category : 'accessing' }
ZealFsNode >> parent: aNode [
	parent := aNode
]
