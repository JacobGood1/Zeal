Class {
	#name : 'ZealExpanderAttribute',
	#superclass : 'BrGlamorousTriangleExpanderTextAttribute',
	#instVars : [
		'zealNode',
		'browser',
		'isTopLevel'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
ZealExpanderAttribute class >> forNode: aZealNode browser: aZealBrowser [
	^ self new zealNode: aZealNode; browser: aZealBrowser; isTopLevel: true; yourself
]

{ #category : 'instance creation' }
ZealExpanderAttribute class >> forNode: aZealNode browser: aZealBrowser nested: aBoolean [
	^ self new zealNode: aZealNode; browser: aZealBrowser; isTopLevel: aBoolean not; yourself
]

{ #category : 'accessing' }
ZealExpanderAttribute >> browser: aZealBrowser [
	browser := aZealBrowser
]

{ #category : 'building' }
ZealExpanderAttribute >> buildExpandedEditor [
	"Build an inline editor. External definitions show read-only signature."
	| source editor statusLabel container isExternal |
	zealNode ifNil: [ ^ BlElement new ].
	
	"Check if this is an external (digest) definition"
	isExternal := zealNode body isNil or: [zealNode body isEmpty and: [zealNode rawSource notNil]].
	
	source := isExternal
		ifTrue: [ self buildExternalSource ]
		ifFalse: [ browser 
			ifNotNil: [ browser zealSourceFor: zealNode generatedClass: (browser generatedClassFor: zealNode) ]
			ifNil: [ String streamContents: [:s | zealNode compileToZeal: s indent: 0] ] ].
	
	container := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4 right: 8 bottom: 8 left: 8);
		padding: (BlInsets all: 4);
		border: (BlBorder paint: (isExternal ifTrue: [Color fromHexString: '888888'] ifFalse: [Color fromHexString: '9580FF']) width: 1);
		background: (ZealTheme backgroundColor darker).
	
	statusLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: (Color fromHexString: '9580FF'); fontSize: 10);
		text: (isExternal 
			ifTrue: [ zealNode parent ifNotNil: [:p | p name , '.' , zealNode name , ' (external)'] ifNil: [zealNode name , ' (external)'] ]
			ifFalse: [ zealNode class name , ': ' , zealNode name ]);
		constraintsDo: [:c | c horizontal matchParent];
		margin: (BlInsets bottom: 2).
	
	editor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: (ZealTheme highlight: source);
		background: (ZealTheme backgroundColor);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 6).
	
	isExternal ifTrue: [ editor beReadOnlyWithSelection ]
	ifFalse: [
		| highlightedText |
		highlightedText := browser 
			ifNotNil: [ browser highlightWithExpanders: source nested: true ]
			ifNil: [ ZealTheme highlight: source ].
		editor text: highlightedText.
		editor addShortcut: (BlShortcutWithAction new 
			combination: BlKeyCombination primaryS;
			action: [ 
				| newSource compiled |
				newSource := editor editor text asString.
				compiled := ZealCompiler compile: newSource.
				(compiled isKindOf: ZealCompileError) 
					ifTrue: [ 
						statusLabel text: ('Error: ' , compiled message) asRopedText.
						(statusLabel text) foreground: Color red ]
					ifFalse: [ 
						statusLabel text: ('Compiled: ' , compiled class name , ' ' , compiled name) asRopedText.
						(statusLabel text) foreground: (Color fromHexString: '50FA7B').
						browser ifNotNil: [ browser compileAndSave: editor forNode: zealNode ] ] ]).
		browser ifNotNil: [ browser configureZealEditor: editor ] ].
	
	container addChild: statusLabel.
	container addChild: editor.
	^ container
]

{ #category : 'building' }
ZealExpanderAttribute >> buildExternalSource [
	"Build a Zeal-style display for an external (digest) definition"
	| stream |
	stream := WriteStream on: String new.
	
	"Convert the signature to Zeal style"
	(zealNode isKindOf: ZealFunction) ifTrue: [
		| methodName retType |
		methodName := zealNode name copyReplaceAll: '_' with: '-'.
		methodName := (methodName first isUppercase) 
			ifTrue: [ methodName first asLowercase asString , methodName allButFirst ]
			ifFalse: [ methodName ].
		retType := zealNode type ifNil: ['void'].
		stream nextPutAll: '(defn '.
		stream nextPutAll: (self kebabCase: zealNode name).
		stream nextPut: $:; nextPutAll: retType.
		
		"Parse params from rawSource if available"
		zealNode rawSource ifNotNil: [:raw |
			| paramStr |
			paramStr := ((raw copyAfter: $() copyUpTo: $)) trimBoth.
			stream nextPutAll: ' ['.
			paramStr notEmpty ifTrue: [
				(paramStr substrings: ',') do: [:p |
					| parts pName pType |
					parts := p trimBoth substrings: ':'.
					pName := parts first trimBoth.
					pType := parts size > 1 ifTrue: [parts second trimBoth] ifFalse: ['any'].
					stream nextPutAll: (self kebabCase: pName); nextPut: $:; nextPutAll: pType ]
				separatedBy: [ stream nextPut: $  ] ].
			stream nextPut: $] ].
		stream cr; nextPutAll: '    ; external — ' ].
	
	(zealNode isKindOf: ZealClass) ifTrue: [
		stream nextPutAll: '(defclass '; nextPutAll: (self kebabCase: zealNode name).
		zealNode superclass ifNotNil: [:sc | 
			stream nextPutAll: ' ['; nextPutAll: (self kebabCase: sc); nextPut: $] ].
		zealNode fields do: [:f |
			stream cr; nextPutAll: '    (def '; nextPutAll: (self kebabCase: f name).
			f type ifNotNil: [:t | stream nextPut: $:; nextPutAll: t ].
			stream nextPut: $) ].
		zealNode methods do: [:m |
			stream cr; nextPutAll: '    (defn '; nextPutAll: (self kebabCase: m name).
			m type ifNotNil: [:t | stream nextPut: $:; nextPutAll: t ].
			stream nextPutAll: ' [])' ] ].
	
	"Parent info"
	zealNode parent ifNotNil: [:p |
		stream nextPutAll: 'defined on: '; nextPutAll: (self kebabCase: p name).
		(p respondsTo: #superclass) ifTrue: [
			p superclass ifNotNil: [:sc | stream nextPutAll: ' ['; nextPutAll: (self kebabCase: sc); nextPut: $] ] ] ].
	
	stream nextPut: $).
	^ stream contents
]

{ #category : 'initialization' }
ZealExpanderAttribute >> initialize [
	super initialize.
	self attributesCreatingBlock: [ 
		BrTextAdornmentDynamicAttribute new
			beAppend;
			stencil: [ self buildExpandedEditor ] ]
]

{ #category : 'accessing' }
ZealExpanderAttribute >> isTopLevel [
	^ isTopLevel ifNil: [ true ]
]

{ #category : 'accessing' }
ZealExpanderAttribute >> isTopLevel: aBoolean [
	isTopLevel := aBoolean
]

{ #category : 'private' }
ZealExpanderAttribute >> kebabCase: aString [
	"Convert PascalCase or snake_case to kebab-case"
	| result |
	result := WriteStream on: String new.
	aString do: [:ch |
		ch = $_ ifTrue: [ result nextPut: $- ]
		ifFalse: [ (ch isUppercase and: [result position > 0]) 
			ifTrue: [ result nextPut: $-; nextPut: ch asLowercase ]
			ifFalse: [ result nextPut: ch asLowercase ] ] ].
	^ result contents
]

{ #category : 'overrides' }
ZealExpanderAttribute >> toggleExpandedOrCollapsedAttributesOn: aTBrTextEditorTextualPiece [
	"On collapse: top-level does clean refresh, nested does normal collapse."
	self isExpanded ifTrue: [
		self isExpanded: false.
		self isTopLevel ifTrue: [
			| node ed |
			node := browser instVarNamed: 'selectedNode'.
			ed := browser instVarNamed: 'zealEditor'.
			(node notNil and: [ed notNil]) ifTrue: [
				ed enqueueTask: (BlTaskAction new action: [ browser selectNode: node ]) ] ]
		ifFalse: [
			self applyExpandedOrCollapsedAttributesOnText: aTBrTextEditorTextualPiece text ].
		^ self ].
	self isExpanded: true.
	self applyExpandedOrCollapsedAttributesOnText: aTBrTextEditorTextualPiece text
]

{ #category : 'accessing' }
ZealExpanderAttribute >> zealNode: aZealNode [
	zealNode := aZealNode
]
