Class {
	#name : 'ZealParameter',
	#superclass : 'ZealNode',
	#instVars : [
		'name',
		'type'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealParameter >> compileToVerse: stream indent: level [
	stream nextPutAll: (self toPascalCase: name).
	type ifNotNil: [ stream nextPut: $:; nextPutAll: type ]
]

{ #category : 'compiling' }
ZealParameter >> compileToZeal: stream indent: level [
	stream nextPutAll: (self toKebabCase: name).
	type ifNotNil: [ stream nextPut: $:; nextPutAll: (self toKebabCase: type) ]
]

{ #category : 'accessing' }
ZealParameter >> name [ ^ name
]

{ #category : 'accessing' }
ZealParameter >> name: aString [ name := aString
]

{ #category : 'accessing' }
ZealParameter >> type [ ^ type
]

{ #category : 'accessing' }
ZealParameter >> type: aString [ type := aString
]
