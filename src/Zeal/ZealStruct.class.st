Class {
	#name : 'ZealStruct',
	#superclass : 'ZealDefinition',
	#instVars : [
		'fields'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealStruct >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: (self toSnakeCase: name); nextPutAll: ' := struct:'.
	self fields do: [:f |
		stream cr. f compileToVerse: stream indent: level + 1 ]
]

{ #category : 'compiling' }
ZealStruct >> compileToVerseWithComments: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '// zeal: (defstruct ' , name , ' ...)'.
	stream cr.
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealStruct >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(defstruct ' , name.
	self fields do: [:f | stream cr. f compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealStruct >> fields [ ^ fields ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealStruct >> fields: a [ fields := a
]

{ #category : 'views' }
ZealStruct >> gtFieldsFor: aView [
	<gtView>
	^ aView list
		title: 'Fields';
		items: [ self fields ];
		itemText: [:f | f name , (f type ifNotNil: [':' , f type] ifNil: ['']) ]
]

{ #category : 'views' }
ZealStruct >> gtVerseFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Verse';
		text: [ self compileToVerse ]
]
