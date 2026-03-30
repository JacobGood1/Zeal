Class {
	#name : 'ZealDefinition',
	#superclass : 'ZealNode',
	#instVars : [
		'name',
		'type'
	],
	#category : '_UnpackagedPackage',
	#package : '_UnpackagedPackage'
}

{ #category : 'accessing' }
ZealDefinition >> name [ ^ name
]

{ #category : 'accessing' }
ZealDefinition >> name: aString [ name := aString
]

{ #category : 'accessing' }
ZealDefinition >> type [ ^ type
]

{ #category : 'accessing' }
ZealDefinition >> type: aString [ type := aString
]
