Class {
	#name : 'ZealFor',
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
ZealFor >> bindings [ ^ bindings ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFor >> bindings: a [ bindings := a
]

{ #category : 'accessing' }
ZealFor >> body [ ^ body ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFor >> body: a [ body := a
]

{ #category : 'verse' }
ZealFor >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'for('.
	self bindings 
		do: [:b | 
			stream nextPutAll: (self toPascalCase: b name).
			((b value isKindOf: ZealOperator) and: [b value operator = '..'])
				ifTrue: [ stream nextPutAll: ' := ' ]
				ifFalse: [ ((b value isKindOf: ZealLiteral) and: [b value literalType = #range])
					ifTrue: [ stream nextPutAll: ' := ' ]
					ifFalse: [ stream nextPutAll: ' : ' ] ].
			b value compileToVerse: stream indent: 0 ]
		separatedBy: [ stream nextPutAll: ', ' ].
	self predicates do: [:p | stream nextPutAll: ', '. p compileToVerse: stream indent: 0 ].
	stream nextPutAll: ') {'.
	self body do: [:e | stream cr. e compileToVerse: stream indent: level + 1 ].
	stream cr. self emitIndent: level on: stream. stream nextPut: $}
]

{ #category : 'compiling' }
ZealFor >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(for ['.
	self bindings 
		do: [:b | 
			stream nextPutAll: (self toKebabCase: b name).
			b type ifNotNil: [ stream nextPut: $:; nextPutAll: (self toKebabCase: b type) ].
			stream nextPut: $ .
			b value compileToZeal: stream indent: 0 ]
		separatedBy: [ stream nextPut: $  ].
	self predicates do: [:p | stream nextPut: $ . p compileToZeal: stream indent: 0 ].
	stream nextPut: $].
	self body do: [:e | stream cr. e compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealFor >> predicates [ ^ predicates ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFor >> predicates: a [ predicates := a
]
