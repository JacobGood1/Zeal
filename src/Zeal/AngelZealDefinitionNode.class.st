Class {
	#name : 'AngelZealDefinitionNode',
	#superclass : 'AngelZealNode',
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

{ #category : 'api' }
AngelZealDefinitionNode >> file [
	"FileReference of the .as file containing this definition (walks up
	 the parent chain to the enclosing AngelZealFileNode)."
	| n |
	n := parent.
	[ n notNil and: [ n isFile not ] ] whileTrue: [ n := n parent ].
	^ n ifNotNil: [ n fileRef ]
]

{ #category : 'gt-views' }
AngelZealDefinitionNode >> gtAngelScriptFor: aView [
	<gtView>
	^ aView textEditor
		title: 'AngelScript';
		priority: 20;
		text: [ targetCode ifNil: [ '' ] ]
]

{ #category : 'gt-views' }
AngelZealDefinitionNode >> gtMetaFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
AngelZealDefinitionNode >> gtPrintFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
AngelZealDefinitionNode >> gtRawFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
AngelZealDefinitionNode >> gtZealSourceFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Zeal';
		priority: 10;
		styler: (ZealTextStyler new);
		text: [ zealSource ifNil: [ '' ] ]
]

{ #category : 'api' }
AngelZealDefinitionNode >> isDefinition [
	^ true
]

{ #category : 'api' }
AngelZealDefinitionNode >> kind [
	^ kind
]

{ #category : 'api' }
AngelZealDefinitionNode >> metadata [
	^ metadata ifNil: [ metadata := Dictionary new ]
]

{ #category : 'api' }
AngelZealDefinitionNode >> metadata: aDict [
	metadata := aDict.
	"Cache common keys for fast access."
	kind := aDict at: #kind ifAbsent: [ nil ].
	returns := aDict at: #returns ifAbsent: [ nil ].
	params := aDict at: #params ifAbsent: [ nil ].
	zealLines := aDict at: #'zeal-lines' ifAbsent: [ aDict at: #zealLines ifAbsent: [ nil ] ].
	targetLines := aDict at: #'target-lines' ifAbsent: [ aDict at: #targetLines ifAbsent: [ nil ] ].
	(aDict at: #name ifAbsent: [ nil ]) ifNotNil: [ :n | name := n ]
]

{ #category : 'api' }
AngelZealDefinitionNode >> params [
	^ params
]

{ #category : 'printing' }
AngelZealDefinitionNode >> printOn: aStream [
	aStream nextPutAll: (kind ifNil: [ 'def' ]);
		nextPutAll: ' ';
		nextPutAll: (name ifNil: [ '?' ])
]

{ #category : 'api' }
AngelZealDefinitionNode >> returns [
	^ returns
]

{ #category : 'api' }
AngelZealDefinitionNode >> targetCode [
	^ targetCode
]

{ #category : 'api' }
AngelZealDefinitionNode >> targetCode: aString [
	targetCode := aString
]

{ #category : 'api' }
AngelZealDefinitionNode >> targetLines [
	^ targetLines
]

{ #category : 'api' }
AngelZealDefinitionNode >> zealLines [
	^ zealLines
]

{ #category : 'api' }
AngelZealDefinitionNode >> zealSource [
	^ zealSource
]

{ #category : 'api' }
AngelZealDefinitionNode >> zealSource: aString [
	zealSource := aString
]
