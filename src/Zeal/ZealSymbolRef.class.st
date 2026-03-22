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
	(ZealTheme operators includes: name)
		ifTrue: [ stream nextPutAll: name ]
		ifFalse: [ name = '_' 
			ifTrue: [ stream nextPutAll: '_' ]
			ifFalse: [ stream nextPutAll: (self toPascalCase: name) ] ]
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
