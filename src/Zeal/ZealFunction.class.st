Class {
	#name : 'ZealFunction',
	#superclass : 'ZealDefinition',
	#instVars : [
		'parameters',
		'body',
		'effects'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealFunction >> body [ ^ body ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFunction >> body: anArray [ body := anArray
]

{ #category : 'compiling' }
ZealFunction >> compileToVerse: stream indent: level [
	| declSpecs sigSpecs bodyExprs |
	self emitIndent: level on: stream.
	declSpecs := specifiers select: [:s | ZealColonChainResolver isDeclarationSpecifier: s].
	sigSpecs := specifiers select: [:s | ZealColonChainResolver isSignatureSpecifier: s].
	stream nextPutAll: (self toPascalCase: name).
	self emitSpecifiers: declSpecs on: stream.
	stream nextPutAll: '('.
	self parameters 
		do: [:p | p compileToVerse: stream indent: 0 ]
		separatedBy: [ stream nextPutAll: ', ' ].
	stream nextPutAll: ')'.
	self emitSpecifiers: sigSpecs on: stream.
	type ifNotNil: [ stream nextPut: $:; nextPutAll: type ].
	stream nextPutAll: ' ='.
	bodyExprs := self body.
	(bodyExprs size = 1 and: [ bodyExprs first isKindOf: ZealBlock ]) ifTrue: [
		bodyExprs := bodyExprs first body ].
	bodyExprs do: [:expr |
		stream cr.
		expr compileToVerse: stream indent: level + 1 ]
]

{ #category : 'compiling' }
ZealFunction >> compileToVerseWithComments: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '// zeal: (defn ' , name.
	specifiers do: [:s | stream nextPut: $:; nextPutAll: s].
	type ifNotNil: [ stream nextPut: $:; nextPutAll: type ].
	stream nextPutAll: ' ...)'.
	stream cr.
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealFunction >> compileToVerseWithZealComment: stream indent: level zealSource: zealSrc [
	"Emit a # zeal: comment with the original Zeal source, then the Verse output"
	self emitIndent: level on: stream.
	stream nextPutAll: '# zeal: '.
	zealSrc lines doWithIndex: [:line :i |
		i > 1 ifTrue: [ stream cr. self emitIndent: level on: stream. stream nextPutAll: '#   ' ].
		stream nextPutAll: line ].
	stream cr.
	self compileToVerse: stream indent: level
]

{ #category : 'compiling' }
ZealFunction >> compileToZeal: stream indent: level [
	| bodyExprs |
	self emitIndent: level on: stream.
	stream nextPutAll: '(defn '.
	stream nextPutAll: (self toKebabCase: name).
	specifiers do: [:s | stream nextPut: $:; nextPutAll: (self toKebabCase: s) ].
	type ifNotNil: [ stream nextPut: $:; nextPutAll: (self typeToZeal: type) ].
	stream nextPutAll: ' ['.
	self parameters do: [:p | p compileToZeal: stream indent: 0 ] separatedBy: [ stream nextPut: $  ].
	stream nextPut: $].
	bodyExprs := self body.
	(bodyExprs size = 1 and: [ bodyExprs first isKindOf: ZealBlock ]) ifTrue: [
		bodyExprs := bodyExprs first body ].
	bodyExprs do: [:e | stream cr. e compileToZeal: stream indent: level + 1 ].
	stream nextPut: $)
]

{ #category : 'accessing' }
ZealFunction >> effects [ ^ effects ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFunction >> effects: anArray [ effects := anArray
]

{ #category : 'views' }
ZealFunction >> gtBodyFor: aView [
	<gtView>
	^ aView list
		title: 'Body';
		items: [ self body ];
		itemText: [:e | e class name allButFirst: 4 , ': ' , e compileToVerse ]
]

{ #category : 'views' }
ZealFunction >> gtParametersFor: aView [
	<gtView>
	^ aView list
		title: 'Parameters';
		items: [ self parameters ];
		itemText: [:p | p name , (p type ifNotNil: [ ':' , p type ] ifNil: [ '' ]) ]
]

{ #category : 'views' }
ZealFunction >> gtVerseFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Verse';
		text: [ self compileToVerse ]
]

{ #category : 'accessing' }
ZealFunction >> parameters [ ^ parameters ifNil: [ #() ]
]

{ #category : 'accessing' }
ZealFunction >> parameters: anArray [ parameters := anArray
]
