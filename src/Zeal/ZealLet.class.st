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

{ #category : 'compiling' }
ZealLet >> compileToVerse: stream indent: level [
	self predicates isEmpty
		ifTrue: [ stream nextPutAll: 'block:' ]
		ifFalse: [ stream nextPutAll: 'if:' ].
	self bindings do: [:b |
		stream cr. self emitIndent: level + 1 on: stream.
		b compileToVerse: stream indent: level + 1 ].
	self predicates do: [:p |
		stream cr. self emitIndent: level + 1 on: stream.
		p compileToVerse: stream indent: level + 1 ].
	self predicates isEmpty ifFalse: [
		stream cr. self emitIndent: level on: stream.
		stream nextPutAll: 'then:' ].
	self body do: [:e |
		stream cr. self emitIndent: level + 1 on: stream.
		e compileToVerse: stream indent: level + 1 ]
]

{ #category : 'accessing' }
ZealLet >> predicates [ ^ predicates ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealLet >> predicates: a [ predicates := a
]
