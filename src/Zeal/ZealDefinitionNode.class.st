Class {
	#name : 'ZealDefinitionNode',
	#superclass : 'ZealFsNode',
	#instVars : [
		'zealSource',
		'targetCode',
		'metadata',
		'kind',
		'returns',
		'params',
		'zealLines',
		'targetLines'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
ZealDefinitionNode class >> fromSection: aSectionDict [
	"Build a definition node from a parseSections: result dict (keys:
	 #zealSource #targetCode #metadata)."
	| node md name |
	node := self new.
	node zealSource: (aSectionDict at: #zealSource ifAbsent: [ '' ]).
	node targetCode: (aSectionDict at: #targetCode ifAbsent: [ '' ]).
	md := (aSectionDict at: #metadata ifAbsent: [ Dictionary new ]) copy.
	node metadata: md.
	name := md at: #name ifAbsent: [ nil ].
	name ifNotNil: [ node name: name ].
	^ node
]

{ #category : 'accessing' }
ZealDefinitionNode >> file [
	"Walk up to find the enclosing file node, if any."
	| n |
	n := parent.
	[ n notNil and: [ n isFile not ] ] whileTrue: [ n := n parent ].
	^ n
]

{ #category : 'gt-views' }
ZealDefinitionNode >> gtMetaFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
ZealDefinitionNode >> gtPrintFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
ZealDefinitionNode >> gtRawFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
ZealDefinitionNode >> gtSourceTargetFor: aView [
	"Inspector tab named 'Source Target' — shared across every Zeal dialect.
	 The tab title is dialect-neutral; each dialect supplies its own styler
	 via the `targetStyler` hook to colorize the target source appropriately."
	<gtView>
	| editor styler font |
	editor := aView textEditor
		title: 'Source Target';
		priority: 20;
		text: [ targetCode ifNil: [ '' ] ].
	styler := self targetStyler.
	styler ifNotNil: [ editor styler: styler ].
	font := ZealBrowser codeFontName.
	font ifNotNil: [ editor fontName: font ].
	^ editor
]

{ #category : 'gt-views' }
ZealDefinitionNode >> gtZealSourceFor: aView [
	<gtView>
	| editor font |
	editor := aView textEditor
		title: 'Zeal';
		priority: 10;
		styler: ZealTextStyler new;
		text: [ zealSource ifNil: [ '' ] ].
	font := ZealBrowser codeFontName.
	font ifNotNil: [ editor fontName: font ].
	^ editor
]

{ #category : 'testing' }
ZealDefinitionNode >> isDefinition [
	^ true
]

{ #category : 'accessing' }
ZealDefinitionNode >> kind [
	^ kind
]

{ #category : 'accessing' }
ZealDefinitionNode >> metadata [
	^ metadata ifNil: [ metadata := Dictionary new ]
]

{ #category : 'accessing' }
ZealDefinitionNode >> metadata: aDict [
	metadata := aDict
]

{ #category : 'accessing' }
ZealDefinitionNode >> params [
	^ params
]

{ #category : 'printing' }
ZealDefinitionNode >> printOn: aStream [
	aStream nextPutAll: (kind ifNil: [ 'def' ]);
		nextPutAll: ' ';
		nextPutAll: (name ifNil: [ '?' ])
]

{ #category : 'accessing' }
ZealDefinitionNode >> returns [
	^ returns
]

{ #category : 'accessing' }
ZealDefinitionNode >> targetCode [
	^ targetCode
]

{ #category : 'accessing' }
ZealDefinitionNode >> targetCode: aString [
	targetCode := aString
]

{ #category : 'accessing' }
ZealDefinitionNode >> targetLines [
	^ targetLines
]

{ #category : 'view-hooks' }
ZealDefinitionNode >> targetStyler [
	"Styler used by gtSourceTargetFor: to colorize the compiled target source.
	 Default returns nil — the editor falls back to plain text. Each dialect
	 subclass overrides to return its target-language BlTextStyler."
	^ nil
]

{ #category : 'accessing' }
ZealDefinitionNode >> zealLines [
	^ zealLines
]

{ #category : 'accessing' }
ZealDefinitionNode >> zealSource [
	^ zealSource
]

{ #category : 'accessing' }
ZealDefinitionNode >> zealSource: aString [
	zealSource := aString
]
