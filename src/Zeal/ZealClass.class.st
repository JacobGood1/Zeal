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

{ #category : 'compiling' }
ZealClass >> compileToVerse: stream indent: level [
	| declSpecs |
	self emitIndent: level on: stream.
	declSpecs := specifiers select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	stream nextPutAll: (self toSnakeCase: name).
	self emitSpecifiers: declSpecs on: stream.
	stream nextPutAll: ' := class'.
	superclass ifNotNil: [ stream nextPutAll: '('; nextPutAll: (self toSnakeCase: superclass); nextPutAll: ')' ].
	stream nextPutAll: ':'.
	self fields do: [:f | stream cr. f compileToVerse: stream indent: level + 1 ].
	self methods do: [:m | stream cr. m compileToVerse: stream indent: level + 1 ]
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
	self emitIndent: level on: stream.
	stream nextPutAll: '(defclass '.
	stream nextPutAll: (self toKebabCase: name).
	specifiers do: [:s | stream nextPut: $:; nextPutAll: (self toKebabCase: s) ].
	superclass ifNotNil: [ stream nextPutAll: ' (' , (self toKebabCase: superclass) , ')' ].
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
