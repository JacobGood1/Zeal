Class {
	#name : 'ZealLiteral',
	#superclass : 'ZealExpression',
	#instVars : [
		'value',
		'literalType'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealLiteral >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	(literalType = #boolean) ifTrue: [ stream nextPutAll: value asLowercase. ^ self ].
	stream nextPutAll: value asString
]

{ #category : 'compiling' }
ZealLiteral >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	(literalType = #string and: [value includesSubstring: '{']) ifTrue: [
		self emitStrInterpolation: value on: stream.
		^ self ].
	stream nextPutAll: value asString
]

{ #category : 'compiling' }
ZealLiteral >> emitStrInterpolation: aString on: stream [
	"Convert ""hello {Name} world"" to (str ""hello "" name "" world"")
	 Input includes surrounding quotes."
	| inner parts i current |
	inner := aString copyFrom: 2 to: aString size - 1. "strip quotes"
	parts := OrderedCollection new.
	current := WriteStream on: String new.
	i := 1.
	[ i <= inner size ] whileTrue: [
		(inner at: i) = ${ ifTrue: [
			current contents notEmpty ifTrue: [ parts add: {#text. current contents} ].
			current := WriteStream on: String new.
			i := i + 1.
			[ i <= inner size and: [(inner at: i) ~= $}] ] whileTrue: [
				current nextPut: (inner at: i). i := i + 1 ].
			parts add: {#expr. current contents}.
			current := WriteStream on: String new.
			i := i + 1 "skip }" ]
		ifFalse: [
			current nextPut: (inner at: i).
			i := i + 1 ] ].
	current contents notEmpty ifTrue: [ parts add: {#text. current contents} ].
	
	parts size = 1 ifTrue: [
		parts first first = #text 
			ifTrue: [ stream nextPut: $"; nextPutAll: parts first second; nextPut: $" ]
			ifFalse: [ stream nextPutAll: (self toKebabCase: parts first second) ].
		^ self ].
	
	stream nextPutAll: '(str'.
	parts do: [:p |
		stream nextPut: $ .
		p first = #text ifTrue: [ stream nextPut: $"; nextPutAll: p second; nextPut: $" ]
		ifFalse: [ stream nextPutAll: (self toKebabCase: p second) ] ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealLiteral >> literalType [ ^ literalType
]

{ #category : 'accessing' }
ZealLiteral >> literalType: s [ literalType := s
]

{ #category : 'accessing' }
ZealLiteral >> value [ ^ value
]

{ #category : 'accessing' }
ZealLiteral >> value: v [ value := v
]
