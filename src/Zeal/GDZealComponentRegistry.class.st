Class {
	#name : 'GDZealComponentRegistry',
	#superclass : 'Object',
	#instVars : [
		'components',
		'coroutines'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
GDZealComponentRegistry >> coroutineNamed: aName [
	^ self coroutines at: aName ifAbsent: [ nil ]
]

{ #category : 'accessing' }
GDZealComponentRegistry >> coroutines [
	"Lazily-initialized dict of registered defco coroutines.
	 name (String) -> Dictionary { #params: OC of strings, #body: OC of body forms }"
	coroutines isNil ifTrue: [ coroutines := Dictionary new ].
	^ coroutines
]

{ #category : 'initialization' }
GDZealComponentRegistry >> initialize [
	components := Set new
]

{ #category : 'testing' }
GDZealComponentRegistry >> isComponent: aName [
	"Is this name a registered component?"
	^ components includes: aName
]

{ #category : 'accessing' }
GDZealComponentRegistry >> register: aName [
	"Register a component name (lowercase, e.g., 'health')"
	components add: aName
]

{ #category : 'accessing' }
GDZealComponentRegistry >> registerCoroutine: aName params: paramList body: bodyForms [
	self coroutines at: aName put: (Dictionary new
		at: #params put: paramList;
		at: #body put: bodyForms;
		yourself)
]

{ #category : 'resolving' }
GDZealComponentRegistry >> resolve: aName [
	"Resolve a name (without @) to its GDScript class name.
	 Components get C_ prefix, others just PascalCase."
	| pascal |
	pascal := self toPascalCase: aName.
	(self isComponent: aName)
		ifTrue: [ ^ 'C_' , pascal ].
	^ pascal
]

{ #category : 'private' }
GDZealComponentRegistry >> toPascalCase: aString [
	"Capitalize first letter, capitalize after hyphens, remove hyphens.
	 @kek -> Kek, @some-class -> SomeClass, @node2D -> Node2D"
	^ String streamContents: [ :s |
		| capitalize |
		capitalize := true.
		aString do: [ :ch |
			ch = $-
				ifTrue: [ capitalize := true ]
				ifFalse: [
					capitalize
						ifTrue: [ s nextPut: ch asUppercase. capitalize := false ]
						ifFalse: [ s nextPut: ch ] ] ] ]
]
