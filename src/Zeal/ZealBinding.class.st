Class {
	#name : 'ZealBinding',
	#superclass : 'ZealNode',
	#instVars : [
		'name',
		'type',
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealBinding >> compileToVerse: stream indent: level [
	stream nextPutAll: (self toPascalCase: name).
	type ifNotNil: [ stream nextPutAll: ' : '; nextPutAll: type; nextPutAll: ' = ' ]
		ifNil: [ stream nextPutAll: ' := ' ].
	value compileToVerse: stream indent: level
]

{ #category : 'accessing' }
ZealBinding >> name [ ^ name
]

{ #category : 'accessing' }
ZealBinding >> name: s [ name := s
]

{ #category : 'accessing' }
ZealBinding >> type [ ^ type
]

{ #category : 'accessing' }
ZealBinding >> type: s [ type := s
]

{ #category : 'accessing' }
ZealBinding >> value [ ^ value
]

{ #category : 'accessing' }
ZealBinding >> value: e [ value := e
]
