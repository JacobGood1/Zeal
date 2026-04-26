Class {
	#name : 'AngelZealNode',
	#superclass : 'Object',
	#instVars : [
		'parent',
		'name',
		'children'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealNode >> addChild: aNode [
	aNode parent: self.
	children add: aNode.
	^ aNode
]

{ #category : 'api' }
AngelZealNode >> children [
	^ children
]

{ #category : 'api' }
AngelZealNode >> initialize [
	super initialize.
	children := OrderedCollection new
]

{ #category : 'api' }
AngelZealNode >> isDefinition [
	^ false
]

{ #category : 'api' }
AngelZealNode >> isFile [
	^ false
]

{ #category : 'api' }
AngelZealNode >> isFolder [
	^ false
]

{ #category : 'api' }
AngelZealNode >> name [
	^ name
]

{ #category : 'api' }
AngelZealNode >> name: aString [
	name := aString
]

{ #category : 'api' }
AngelZealNode >> parent [
	^ parent
]

{ #category : 'api' }
AngelZealNode >> parent: aNode [
	parent := aNode
]
