Class {
	#name : 'ZealField',
	#superclass : 'ZealNode',
	#instVars : [
		'name',
		'type',
		'defaultValue',
		'isMutable'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealField >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	self isMutable ifTrue: [ stream nextPutAll: 'var ' ].
	stream nextPutAll: (self toPascalCase: name).
	type ifNotNil: [ stream nextPut: $:; nextPutAll: type ].
	defaultValue ifNotNil: [ 
		stream nextPutAll: ' = '. 
		defaultValue compileToVerse: stream indent: 0 ]
]

{ #category : 'compiling' }
ZealField >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	self isMutable 
		ifTrue: [ stream nextPutAll: '(var '; nextPutAll: (self toKebabCase: name) ]
		ifFalse: [ stream nextPut: $[; nextPutAll: (self toKebabCase: name) ].
	type ifNotNil: [ stream nextPut: $:; nextPutAll: (self toKebabCase: type) ].
	defaultValue ifNotNil: [ stream nextPut: $ . defaultValue compileToZeal: stream indent: 0 ].
	self isMutable ifTrue: [ stream nextPut: $) ] ifFalse: [ stream nextPut: $] ]
]

{ #category : 'accessing' }
ZealField >> defaultValue [ ^ defaultValue
]

{ #category : 'accessing' }
ZealField >> defaultValue: e [ defaultValue := e
]

{ #category : 'accessing' }
ZealField >> isMutable [ ^ isMutable ifNil: [ false ]
]

{ #category : 'accessing' }
ZealField >> isMutable: b [ isMutable := b
]

{ #category : 'accessing' }
ZealField >> name [ ^ name
]

{ #category : 'accessing' }
ZealField >> name: s [ name := s
]

{ #category : 'accessing' }
ZealField >> type [ ^ type
]

{ #category : 'accessing' }
ZealField >> type: s [ type := s
]
