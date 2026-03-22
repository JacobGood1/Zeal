Class {
	#name : 'ZealInterface',
	#superclass : 'ZealDefinition',
	#instVars : [
		'parents',
		'methods'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealInterface >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: (self toSnakeCase: name); nextPutAll: ' := interface:'.
	self methods do: [:m | stream cr. m compileToVerse: stream indent: level + 1 ]
]

{ #category : 'accessing' }
ZealInterface >> methods [ ^ methods ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealInterface >> methods: a [ methods := a
]

{ #category : 'accessing' }
ZealInterface >> parents [ ^ parents ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealInterface >> parents: a [ parents := a
]
