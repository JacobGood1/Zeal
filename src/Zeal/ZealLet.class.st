Class {
	#name : 'ZealLet',
	#superclass : 'ZealExpression',
	#instVars : [
		'bindings',
		'predicates',
		'body'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealLet >> bindings [ ^ bindings ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealLet >> bindings: a [ bindings := a
]

{ #category : 'accessing' }
ZealLet >> body [ ^ body ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealLet >> body: a [ body := a
]

{ #category : 'verse' }
ZealLet >> compileToVerse: stream indent: level [
	self predicates isEmpty
		ifTrue: [ 
			"No predicates — just a block with bindings"
			stream nextPutAll: 'block {'.
			self bindings do: [:b |
				stream cr. self emitIndent: level + 1 on: stream.
				b compileToVerse: stream indent: 0 ].
			self body do: [:e |
				stream cr. e compileToVerse: stream indent: level + 1 ].
			stream cr. self emitIndent: level on: stream. stream nextPut: $} ]
		ifFalse: [
			"Has predicates — if(conditions) { body }"
			stream nextPutAll: 'if ('.
			self bindings doWithIndex: [:b :i |
				i > 1 ifTrue: [ stream nextPutAll: ', ' ].
				b compileToVerse: stream indent: 0 ].
			(self bindings notEmpty and: [self predicates notEmpty]) ifTrue: [ stream nextPutAll: ', ' ].
			self predicates doWithIndex: [:p :i |
				i > 1 ifTrue: [ stream nextPutAll: ', ' ].
				p compileToVerse: stream indent: 0 ].
			stream nextPutAll: ') {'.
			self body do: [:e |
				stream cr. e compileToVerse: stream indent: level + 1 ].
			stream cr. self emitIndent: level on: stream. stream nextPut: $} ]
]

{ #category : 'accessing' }
ZealLet >> predicates [ ^ predicates ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealLet >> predicates: a [ predicates := a
]
