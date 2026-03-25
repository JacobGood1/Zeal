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

{ #category : 'verse' }
ZealInterface >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: (self toSnakeCase: name); nextPutAll: ' := interface {'.
	self methods do: [:m | stream cr. m compileToVerse: stream indent: level + 1 ].
	stream cr. self emitIndent: level on: stream. stream nextPut: $}
]

{ #category : 'zeal' }
ZealInterface >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(definterface '.
	stream nextPutAll: (self toKebabCase: name).
	parents ifNotNil: [
		parents notEmpty ifTrue: [
			stream nextPutAll: ' ['.
			parents do: [:p | stream nextPutAll: (self toKebabCase: p)] separatedBy: [stream nextPut: $ ].
			stream nextPut: $] ] ].
	methods do: [:m | stream cr. m compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
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
