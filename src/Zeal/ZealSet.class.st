Class {
	#name : 'ZealSet',
	#superclass : 'ZealExpression',
	#instVars : [
		'target',
		'value',
		'operator'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealSet >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'set '.
	stream nextPutAll: (self toPascalCase: target).
	stream nextPutAll: ' '; nextPutAll: self operator; nextPutAll: ' '.
	value compileToVerse: stream indent: 0
]

{ #category : 'compiling' }
ZealSet >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(set '.
	stream nextPutAll: (self toKebabCase: target).
	self operator = '+=' ifTrue: [ stream nextPutAll: ' += ' ] 
		ifFalse: [ self operator = '-=' ifTrue: [ stream nextPutAll: ' -= ' ] 
		ifFalse: [ stream nextPut: $  ] ].
	value compileToZeal: stream indent: 0.
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealSet >> operator [ ^ operator ifNil: ['=']
]

{ #category : 'accessing' }
ZealSet >> operator: s [ operator := s
]

{ #category : 'accessing' }
ZealSet >> target [ ^ target
]

{ #category : 'accessing' }
ZealSet >> target: s [ target := s
]

{ #category : 'accessing' }
ZealSet >> value [ ^ value
]

{ #category : 'accessing' }
ZealSet >> value: e [ value := e
]
