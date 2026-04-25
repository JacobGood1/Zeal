Class {
	#name : 'ZealTypeInferencer',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
ZealTypeInferencer class >> default [
	"Lazy singleton — most queries are stateless lookups against a fixed set."
	^ self new
]

{ #category : 'api' }
ZealTypeInferencer >> knownTypes [
	"All type names this inferencer recognizes. Subclasses override to add
	 dialect/host-specific types on top of the primitives."
	^ self primitiveTypes
]

{ #category : 'api' }
ZealTypeInferencer >> primitiveTypes [
	"Type names common to every Zeal dialect — Lisp/Verse-style primitives.
	 Subclasses extend with their host's built-in / engine types."
	^ #('int' 'float' 'double' 'bool' 'logic' 'string' 'char' 'void' 'any' 'type'
	    'Int' 'Float' 'Double' 'Bool' 'Logic' 'String' 'Char' 'Void' 'Any' 'Type')
]

{ #category : 'api' }
ZealTypeInferencer >> recognizesType: aString [
	"Return true if aString names a type the dialect understands. Strips
	 leading array/map shorthand so e.g. `[]int` or `[FString]int` recognize
	 as a type by their element type."
	| s |
	s := aString.
	(s beginsWith: '[]') ifTrue: [ ^ self recognizesType: (s copyFrom: 3 to: s size) ].
	((s beginsWith: '[') and: [ s includes: $] ])
		ifTrue: [
			| close keyT valT |
			close := s indexOf: $].
			keyT := s copyFrom: 2 to: close - 1.
			valT := s copyFrom: close + 1 to: s size.
			^ (self recognizesType: keyT) and: [ self recognizesType: valT ] ].
	^ self knownTypes includes: s
]
