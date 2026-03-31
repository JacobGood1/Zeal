Class {
	#name : 'ZealClass',
	#superclass : 'ZealDefinition',
	#instVars : [
		'superclass',
		'interfaces',
		'fields',
		'methods'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'verse' }
ZealClass >> compileToVerse: stream indent: level [
	| declSpecs allParents |
	self emitIndent: level on: stream.
	declSpecs := specifiers select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	stream nextPutAll: (self toSnakeCase: name).
	self emitSpecifiers: declSpecs on: stream.
	stream nextPutAll: ' := class'.
	allParents := OrderedCollection new.
	superclass ifNotNil: [ allParents add: (self toSnakeCase: superclass) ].
	(interfaces notNil and: [interfaces notEmpty]) ifTrue: [
		interfaces do: [:i | allParents add: (self toSnakeCase: i) ] ].
	allParents notEmpty ifTrue: [
		stream nextPut: $(.
		allParents do: [:p | stream nextPutAll: p] separatedBy: [stream nextPutAll: ', '].
		stream nextPut: $) ].
	stream nextPutAll: ' {'.
	self fields do: [:f | stream cr. f compileToVerse: stream indent: level + 1 ].
	self methods do: [:m | stream cr. m compileToVerse: stream indent: level + 1 ].
	stream cr.
	self emitIndent: level on: stream.
	stream nextPut: $}
]

{ #category : 'compiling' }
ZealClass >> compileToVerseWithComments: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '// zeal: (defclass ' , name.
	specifiers do: [:s | stream nextPut: $:; nextPutAll: s].
	stream nextPutAll: ' ...)'.
	stream cr.
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealClass >> compileToZeal: stream indent: level [
	| parents |
	self emitIndent: level on: stream.
	stream nextPutAll: '(defclass '.
	stream nextPutAll: (self toKebabCase: name).
	specifiers do: [:s | stream nextPut: $:; nextPutAll: (self toKebabCase: s) ].
	parents := OrderedCollection new.
	superclass ifNotNil: [ parents add: (self toKebabCase: superclass) ].
	interfaces ifNotNil: [ interfaces do: [:i | parents add: (self toKebabCase: i) ] ].
	parents notEmpty ifTrue: [
		stream nextPutAll: ' ['.
		stream nextPutAll: (' ' join: parents).
		stream nextPutAll: ']' ].
	self fields do: [:f | stream cr. f compileToZeal: stream indent: level + 1 ].
	self methods do: [:m | stream cr. m compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealClass >> fields [ ^ fields ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealClass >> fields: a [ fields := a
]

{ #category : 'views' }
ZealClass >> gtFieldsFor: aView [
	<gtView>
	^ aView list
		title: 'Fields';
		items: [ self fields ];
		itemText: [:f | (f isMutable ifTrue: ['var '] ifFalse: ['']) , f name , (f type ifNotNil: [':' , f type] ifNil: ['']) ]
]

{ #category : 'views' }
ZealClass >> gtMethodsFor: aView [
	<gtView>
	^ aView list
		title: 'Methods';
		items: [ self methods ];
		itemText: [:m | m name , (m type ifNotNil: [':' , m type] ifNil: ['']) ]
]

{ #category : 'views' }
ZealClass >> gtVerseFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Verse';
		text: [ self compileToVerse ]
]

{ #category : 'accessing' }
ZealClass >> interfaces [ ^ interfaces ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealClass >> interfaces: a [ interfaces := a
]

{ #category : 'accessing' }
ZealClass >> methods [ ^ methods ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealClass >> methods: a [ methods := a
]

{ #category : 'accessing' }
ZealClass >> superclass [ ^ superclass
]

{ #category : 'accessing' }
ZealClass >> superclass: s [ superclass := s
]
