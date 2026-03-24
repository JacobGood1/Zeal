Class {
	#name : 'ZealSymbolRef',
	#superclass : 'ZealExpression',
	#instVars : [
		'name'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealSymbolRef >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	(#('true' 'false') includes: name) ifTrue: [ stream nextPutAll: name. ^ self ].
	(ZealTheme operators includes: name) ifTrue: [ stream nextPutAll: name. ^ self ].
	name = '_' ifTrue: [ stream nextPutAll: '_'. ^ self ].
	stream nextPutAll: (self toPascalCase: name)
]

{ #category : 'compiling' }
ZealSymbolRef >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: (self toKebabCase: name)
]

{ #category : 'accessing' }
ZealSymbolRef >> name [ ^ name
]

{ #category : 'accessing' }
ZealSymbolRef >> name: s [ name := s
]
