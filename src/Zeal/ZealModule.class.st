Class {
	#name : 'ZealModule',
	#superclass : 'ZealDefinition',
	#instVars : [
		'usings',
		'definitions',
		'kind'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealModule >> compileToVerse: stream indent: level [
	"File namespaces just emit their contents, inline modules emit module: wrapper"
	self kind = #file ifTrue: [
		self usings do: [:u | u compileToVerse: stream indent: level. stream cr ].
		self definitions 
			do: [:d | d compileToVerse: stream indent: level ] 
			separatedBy: [ stream cr; cr ].
		^ self ].
	self emitIndent: level on: stream.
	stream nextPutAll: (self toSnakeCase: name); nextPutAll: ' := module:'.
	self usings do: [:u | stream cr. u compileToVerse: stream indent: level + 1 ].
	self definitions do: [:d | stream cr. d compileToVerse: stream indent: level + 1 ]
]

{ #category : 'compiling' }
ZealModule >> compileToZeal: stream indent: level [
	self kind = #file ifTrue: [
		self definitions do: [:d | d compileToZeal: stream indent: level ] separatedBy: [ stream cr; cr ].
		^ self ].
	self emitIndent: level on: stream.
	stream nextPutAll: '(module ' , name.
	self usings do: [:u | stream cr. u compileToZeal: stream indent: level + 1 ].
	self definitions do: [:d | stream cr. d compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealModule >> definitions [ ^ definitions ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealModule >> definitions: a [ definitions := a
]

{ #category : 'views' }
ZealModule >> gtDefinitionsFor: aView [
	<gtView>
	^ aView list
		title: 'Definitions';
		items: [ self definitions ];
		itemText: [:d | d class name allButFirst: 4 , ': ' , d name ]
]

{ #category : 'views' }
ZealModule >> gtUsingsFor: aView [
	<gtView>
	^ aView list
		title: 'Usings';
		items: [ self usings ];
		itemText: [:u | u path ]
]

{ #category : 'views' }
ZealModule >> gtVerseFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Verse';
		text: [ self compileToVerse ]
]

{ #category : 'accessing' }
ZealModule >> kind [ ^ kind ifNil: [ #inline ]
]

{ #category : 'accessing' }
ZealModule >> kind: s [ kind := s
]

{ #category : 'accessing' }
ZealModule >> usings [ ^ usings ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealModule >> usings: a [ usings := a
]
