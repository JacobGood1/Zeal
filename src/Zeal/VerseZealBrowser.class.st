Class {
	#name : 'VerseZealBrowser',
	#superclass : 'ZealBrowser',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'opening' }
VerseZealBrowser class >> open [
	"Open Zeal launcher with themed folder picker."
	| space root titleLabel sampleBtn fileSelector |
	space := BlSpace new.
	space title: 'Zeal // Project Launcher'.
	space extent: 700@550.
	
	root := BlElement new.
	root layout: BlLinearLayout vertical.
	root constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	root background: ZealTheme backgroundColor.
	root padding: (BlInsets all: 20).
	
	titleLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme cursorColor; fontSize: 24; bold);
		text: 'ZEAL // PROJECT LAUNCHER'.
	root addChild: titleLabel.
	
	root addChild: (BlElement new constraintsDo: [:c | c horizontal matchParent. c vertical exact: 12 ]).
	
	sampleBtn := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude;
		label: 'Open Sample Project';
		action: [ space close. self openSample ];
		margin: (BlInsets bottom: 16).
	root addChild: sampleBtn.
	
	root addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Select a UEFN project folder:';
		margin: (BlInsets bottom: 8)).
	
	fileSelector := ZealFileSelector new.
	fileSelector folder: FileLocator home asFileReference.
	fileSelector fileFilterBlock: [ :entry | entry isDirectory or: [ entry basename endsWith: '.verse' ] ].
	fileSelector okAction: [ :selected :btn |
		| ref |
		ref := selected asFileReference.
		ref isDirectory
			ifTrue: [ space close. self openFolder: ref fullName ]
			ifFalse: [ space close. self openFolder: ref parent fullName ] ].
	fileSelector buttonLabel: 'Scan Project'.
	fileSelector constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	fileSelector background: (ZealTheme backgroundColor lighter).
	root addChild: fileSelector.
	
	space root addChild: root.
	space show.
	^ space
]

{ #category : 'opening' }
VerseZealBrowser class >> openFolder: aPathString [
	| project |
	project := ZealProject new scanFolder: aPathString asFileReference.
	^ self openProject: project
]

{ #category : 'opening' }
VerseZealBrowser class >> openProject: aZealProject [
	| browser space pager |
	browser := self new.
	browser project: aZealProject.
	pager := GtPager createWrappedOn: browser.
	pager background: ZealTheme backgroundColor.
	pager allChildrenBreadthFirstDo: [:c | 
		(c background isKindOf: BlPaintBackground) ifTrue: [
			c background paint color = Color white ifTrue: [
				c background: ZealTheme backgroundColor ] ] ].
	space := BlSpace new.
	space title: 'Zeal Browser // ' , aZealProject name.
	space extent: 1100@700.
	space root background: ZealTheme backgroundColor.
	space root addChild: pager.
	space show.
	^ browser
]

{ #category : 'opening' }
VerseZealBrowser class >> openSample [
	"Open a browser with a sample in-memory project for testing."
	| project mod1 mod2 |
	project := ZealProject new name: 'SampleGame'; path: '/SampleGame'.
	
	mod1 := ZealModule new name: 'Core'; kind: #folder; 
		usings: OrderedCollection new; definitions: OrderedCollection new.
	mod1 definitions add: (ZealCompiler compile: '(defstruct vector2 [x:float 0.0] [y:float 0.0])').
	mod1 definitions add: (ZealCompiler compile: '(defenum game-state main-menu playing paused game-over)').
	mod1 definitions add: (ZealCompiler compile: '(defn calculate-score:public:int [base:int bonus:int] (+ base (* bonus 2)))').
	mod1 definitions do: [:d | d parent: mod1].
	mod1 parent: project.
	
	mod2 := ZealModule new name: 'Characters'; kind: #folder;
		usings: OrderedCollection new; definitions: OrderedCollection new.
	mod2 definitions add: (ZealCompiler compile: '(defclass character:concrete (entity) (var health:int 100) (var level:int 1) (defn take-damage:void [amount:int] (set health (Max 0 (- health amount)))) (defn is-alive:decides:void (> health 0)))').
	mod2 definitions add: (ZealCompiler compile: '(defclass player:concrete (character) (var score:int 0) (defn add-score:void [points:int] (set score (+ score points))))').
	mod2 definitions do: [:d | d parent: mod2].
	mod2 parent: project.
	
	project modules add: mod1.
	project modules add: mod2.
	^ self openProject: project
]

{ #category : 'verse' }
VerseZealBrowser >> addCompiled: compiled to: aNode [
	"Add or replace a compiled definition. Matches by name AND parameter signature
	 to support Verse method overloading."
	(compiled isKindOf: ZealFunction) ifTrue: [
		| existing |
		compiled parent: aNode.
		(aNode respondsTo: #methods) ifTrue: [
			aNode methods ifNil: [ aNode methods: OrderedCollection new ].
			(aNode methods isKindOf: Array) ifTrue: [ aNode methods: aNode methods asOrderedCollection ].
			"Match by name AND param types (overloading)"
			existing := aNode methods detect: [:m | 
				(m isKindOf: ZealFunction) and: [
				m name asLowercase = compiled name asLowercase and: [
				(self paramSignatureOf: m) = (self paramSignatureOf: compiled) ]]] ifNone: [nil].
			existing ifNotNil: [
				aNode methods at: (aNode methods indexOf: existing) put: compiled ]
			ifNil: [ aNode methods add: compiled ] ].
		^ self ].
	
	(compiled isKindOf: ZealVariable) ifTrue: [
		| field |
		field := ZealField new name: compiled name; type: compiled type; 
			defaultValue: compiled value; isMutable: compiled isMutable.
		(aNode respondsTo: #fields) ifTrue: [
			| existing |
			aNode fields ifNil: [ aNode fields: OrderedCollection new ].
			(aNode fields isKindOf: Array) ifTrue: [ aNode fields: aNode fields asOrderedCollection ].
			existing := aNode fields detect: [:f | 
				((f respondsTo: #name) and: [f name notNil]) and: [f name asLowercase = compiled name asLowercase]] ifNone: [nil].
			existing ifNotNil: [
				aNode fields at: (aNode fields indexOf: existing) put: field ]
			ifNil: [ aNode fields add: field ] ]
		ifFalse: [
			(aNode respondsTo: #methods) ifTrue: [
				| existing |
				aNode methods ifNil: [ aNode methods: OrderedCollection new ].
				(aNode methods isKindOf: Array) ifTrue: [ aNode methods: aNode methods asOrderedCollection ].
				existing := aNode methods detect: [:m | 
					((m respondsTo: #name) and: [m name notNil]) and: [
					(m isKindOf: ZealFunction) not and: [m name asLowercase = compiled name asLowercase]]] ifNone: [nil].
				existing ifNotNil: [
					aNode methods at: (aNode methods indexOf: existing) put: compiled ]
				ifNil: [ aNode methods add: compiled ] ] ].
		^ self ]
]

{ #category : 'verse' }
VerseZealBrowser >> addMethodTo: aNode [
	"Add a new empty method to the class/interface"
	| newMethod |
	newMethod := ZealFunction new name: 'new-method'; type: 'void'; 
		parameters: OrderedCollection new; body: OrderedCollection new.
	newMethod parent: aNode.
	(aNode respondsTo: #methods) ifTrue: [
		aNode methods ifNil: [ aNode methods: OrderedCollection new ].
		(aNode methods isKindOf: Array) ifTrue: [ aNode methods: aNode methods asOrderedCollection ].
		aNode methods add: newMethod ]
]

{ #category : 'verse' }
VerseZealBrowser >> addSlotTo: aNode [
	"Add a new empty slot to the class/interface"
	| newField |
	newField := ZealField new name: 'new-field'; type: 'int'; isMutable: false.
	(aNode respondsTo: #fields) ifTrue: [
		aNode fields ifNil: [ aNode fields: OrderedCollection new ].
		(aNode fields isKindOf: Array) ifTrue: [ aNode fields: aNode fields asOrderedCollection ].
		aNode fields add: newField ]
	ifFalse: [
		"Interface stores fields in methods"
		(aNode respondsTo: #methods) ifTrue: [
			aNode methods ifNil: [ aNode methods: OrderedCollection new ].
			(aNode methods isKindOf: Array) ifTrue: [ aNode methods: aNode methods asOrderedCollection ].
			aNode methods add: (ZealVariable new name: 'new-field'; type: 'int'; isMutable: false) ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> addSlotTo: aNode mutable: isMutable [
	"Add a new empty slot to the class/interface"
	| newField |
	newField := ZealField new name: 'new-field'; type: 'int'; isMutable: isMutable.
	(aNode respondsTo: #fields) ifTrue: [
		aNode fields ifNil: [ aNode fields: OrderedCollection new ].
		(aNode fields isKindOf: Array) ifTrue: [ aNode fields: aNode fields asOrderedCollection ].
		aNode fields add: newField ]
	ifFalse: [
		(aNode respondsTo: #methods) ifTrue: [
			aNode methods ifNil: [ aNode methods: OrderedCollection new ].
			(aNode methods isKindOf: Array) ifTrue: [ aNode methods: aNode methods asOrderedCollection ].
			aNode methods add: (ZealVariable new name: 'new-field'; type: 'int'; isMutable: isMutable) ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> allModuleNames [
	"Collect all folder module names with paths"
	| result rootMod |
	result := OrderedCollection new.
	rootMod := project modules first.
	result add: rootMod name -> rootMod.
	self collectModuleNames: rootMod path: rootMod name into: result.
	^ result
]

{ #category : 'verse' }
VerseZealBrowser >> badgeLetterFor: item [
	(item isKindOf: ZealTreeGroup) ifTrue: [ ^ '▸' ].
	(item isKindOf: ZealModule) ifTrue: [ ^ 'M' ].
	(item isKindOf: ZealClass) ifTrue: [ ^ 'C' ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ 'I' ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ 'S' ].
	(item isKindOf: ZealEnum) ifTrue: [ ^ 'E' ].
	(item isKindOf: ZealFunction) ifTrue: [ ^ 'λ' ].
	(item isKindOf: ZealVariable) ifTrue: [ ^ 'V' ].
	^ '?'
]

{ #category : 'verse' }
VerseZealBrowser >> browseDefinitionAt: anEditor [
	"Find the word under cursor, resolve it, and open it"
	| text cursorPos source wordStart wordEnd word node |
	text := anEditor editor text asString.
	cursorPos := 0.
	anEditor editor cursors do: [:c | cursorPos := c position].
	cursorPos = 0 ifTrue: [ ^ self ].
	source := text.
	
	wordStart := cursorPos.
	wordEnd := cursorPos + 1.
	[ wordStart > 0 and: [
		| c | c := source at: wordStart.
		c isLetter or: [c isDigit or: [c = $- or: [c = $/ or: [c = $_]]]]
	] ] whileTrue: [ wordStart := wordStart - 1 ].
	wordStart := wordStart + 1.
	[ wordEnd <= source size and: [
		| c | c := source at: wordEnd.
		c isLetter or: [c isDigit or: [c = $- or: [c = $/ or: [c = $_ or: [c = $:]]]]]
	] ] whileTrue: [ wordEnd := wordEnd + 1 ].
	wordEnd := wordEnd - 1.
	
	(wordStart > wordEnd) ifTrue: [ ^ self ].
	word := source copyFrom: wordStart to: wordEnd.
	
	node := self resolveWord: word.
	node ifNil: [ ^ self ].
	
	"Try phlow spawnTool: first (works inside pager). Fallback to selectNode:."
	[ anEditor phlow spawnTool: (GtPhlowExplicitTool new
		name: (self toKebab: node name);
		stencil: [ self wrapInDarkPage: (self buildDefinitionView: node) ]) ]
	on: Error do: [
		"Not in a pager context — open in the main detail pane"
		self selectNode: node ]
]

{ #category : 'verse' }
VerseZealBrowser >> buildAddEditor: aNode inContainer: aContainer [
	"A Zeal code editor. Ctrl+S adds to class and rebuilds THIS container."
	| wrapper label editor initialText |
	wrapper := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4).
	
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11);
		text: 'Add to class (Ctrl+S to add):';
		margin: (BlInsets bottom: 4).
	
	initialText := addEditorText ifNil: [ '(defn new-method:void []
    )' ].
	
	editor := self newZealEditor: initialText.
	editor padding: (BlInsets all: 8).
	editor border: (BlBorder paint: (Color fromHexString: '50FA7B') width: 1).
	editor id: #zealAddEditor.
	
	addEditorCursorPos ifNotNil: [:pos |
		editor addEventHandlerOn: BlElementAddedToSceneGraphEvent do: [:e |
			editor editor navigator moveTo: (pos min: editor editor text size); apply.
			editor requestFocus ] ].
	
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [
			| src compiled cursorPos |
			src := editor editor text asString trimBoth.
			cursorPos := 0.
			editor editor cursors do: [:c | cursorPos := c position].
			src isEmpty ifFalse: [
				[ compiled := ZealCompiler compile: src.
				  compiled := (compiled isKindOf: Collection) ifTrue: [compiled] ifFalse: [{compiled}].
				  compiled do: [:each | self addCompiled: each to: aNode].
				  addEditorText := src.
				  addEditorCursorPos := cursorPos.
				  self persistNode: aNode.
				  self flashSuccess: editor.
				  self rebuildClassIn: aContainer node: aNode ]
				on: Error do: [:e | 
					self flashError: editor ] ] ]).
	
	wrapper addChild: label.
	wrapper addChild: editor.
	^ wrapper
]

{ #category : 'verse' }
VerseZealBrowser >> buildAllSlotsEditor: aNode inContainer: aContainer [
	"All slots editor. Ctrl+S saves to memory, generated class, and .verse file."
	| container allMembers fields zealLines editor |
	container := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 12);
		background: ZealTheme backgroundColor.
	
	container addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 16; bold);
		text: 'Slots: ' , (self toKebab: aNode name);
		margin: (BlInsets bottom: 8)).
	
	allMembers := OrderedCollection new.
	(aNode respondsTo: #fields) ifTrue: [ aNode fields ifNotNil: [:f | allMembers addAll: f ] ].
	(aNode respondsTo: #methods) ifTrue: [ aNode methods ifNotNil: [:m | allMembers addAll: m ] ].
	fields := allMembers reject: [:m | m isKindOf: ZealFunction ].
	
	zealLines := fields collect: [:f |
		| line isMut |
		isMut := (f respondsTo: #isMutable) ifTrue: [f isMutable] ifFalse: [false].
		line := isMut ifTrue: ['(var '] ifFalse: ['(def '].
		line := line , (self toKebab: f name).
		(f respondsTo: #type) ifTrue: [ f type ifNotNil: [:t | line := line , ':' , t ] ].
		((f respondsTo: #defaultValue) ifTrue: [f defaultValue] ifFalse: [
			(f respondsTo: #value) ifTrue: [f value] ifFalse: [nil]]) ifNotNil: [:v |
			line := line , ' ' , ([String streamContents: [:s | v compileToZeal: s indent: 0]] on: Error do: [v printString]) ].
		line , ')' ].
	
	editor := self newZealEditor: (Character lf asString join: zealLines).
	editor padding: (BlInsets all: 8).
	editor border: (BlBorder paint: (Color fromHexString: '9580FF') width: 1).
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [
			| src compiled cursorPos |
			src := editor editor text asString trimBoth.
			cursorPos := 0.
			editor editor cursors do: [:c | cursorPos := c position].
			[ compiled := ZealCompiler compile: src.
			  compiled := (compiled isKindOf: Collection) ifTrue: [compiled] ifFalse: [{compiled}].
			  (aNode respondsTo: #fields) ifTrue: [
				  aNode fields: OrderedCollection new.
				  compiled do: [:each | self addCompiled: each to: aNode ] ]
			  ifFalse: [
				  | methods |
				  methods := aNode methods select: [:m | m isKindOf: ZealFunction].
				  aNode methods: methods asOrderedCollection.
				  compiled do: [:each | self addCompiled: each to: aNode ] ].
			  
			  "Persist class to generated class and .verse file"
			  self persistClassNode: aNode.
			  
			  self flashSuccess: editor.
			  self rebuildClassIn: aContainer node: aNode.
			  editor enqueueTask: (BlTaskAction new action: [
				  editor requestFocus.
				  editor editor navigator moveTo: (cursorPos min: editor editor text size); apply ]) ]
			on: Error do: [:e |
				self flashError: editor ] ]).
	
	container addChild: editor.
	^ container
]

{ #category : 'verse' }
VerseZealBrowser >> buildChatPanel [
	"Build the embedded Zeal Bot chat panel"
	| chat panel |
	chat := ZealBot new browser: self.
	chat systemPrompt: self chatSystemPrompt.
	
	panel := BlElement new
		id: #chatPanel;
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal exact: 400. c vertical matchParent ];
		background: (Color fromHexString: '1A1A1A');
		border: (BlBorder paint: (Color fromHexString: '333333') width: 1).
	panel addChild: chat.
	chat constraintsDo: [:c | c horizontal matchParent. c vertical matchParent].
	^ panel
]

{ #category : 'verse' }
VerseZealBrowser >> buildClassDetail: aNode [
	^ self buildClassDetail: aNode expandMethod: nil
]

{ #category : 'verse' }
VerseZealBrowser >> buildClassDetail: aNode expandMethod: aMethodOrNil [
	"Class/interface view: header, module, using, slots, extends, methods, source editor"
	| container allMembers fields methods mutableFields immutableFields |
	container := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
	
	container addChild: (self buildClassHeader: aNode).
	container addChild: (self buildModuleDropdown: aNode inContainer: container).
	container addChild: (self buildUsingEditor: aNode).
	container addChild: (self buildDivider).
	
	"Collect members"
	allMembers := OrderedCollection new.
	(aNode respondsTo: #fields) ifTrue: [ aNode fields ifNotNil: [:f | allMembers addAll: f ] ].
	(aNode respondsTo: #methods) ifTrue: [ aNode methods ifNotNil: [:m | allMembers addAll: m ] ].
	fields := allMembers select: [:m | (m isKindOf: ZealFunction) not ].
	methods := allMembers select: [:m | m isKindOf: ZealFunction ].
	mutableFields := fields select: [:f | (f respondsTo: #isMutable) and: [f isMutable]].
	immutableFields := fields reject: [:f | (f respondsTo: #isMutable) and: [f isMutable]].
	
	"Slots"
	fields notEmpty ifTrue: [
		| columnsRow leftCol rightCol |
		columnsRow := BlElement new
			layout: BlLinearLayout horizontal;
			constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
		leftCol := BlElement new layout: BlLinearLayout vertical;
			constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ]; padding: (BlInsets right: 8).
		leftCol addChild: (self buildSectionLabel: 'Slots').
		mutableFields do: [:f | leftCol addChild: (self buildSlotItem: f forClass: aNode inContainer: container) ].
		rightCol := BlElement new layout: BlLinearLayout vertical;
			constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ]; padding: (BlInsets left: 8).
		rightCol addChild: (self buildSectionLabel: 'Immutable Slots').
		immutableFields do: [:f | rightCol addChild: (self buildSlotItem: f forClass: aNode inContainer: container) ].
		columnsRow addChild: leftCol. columnsRow addChild: rightCol.
		container addChild: columnsRow.
		container addChild: (self buildDivider) ].
	
	"Extends"
	container addChild: (self buildExtendsEditor: aNode inContainer: container).
	container addChild: (self buildDivider).
	
	"Methods"
	methods notEmpty ifTrue: [
		container addChild: (self buildSectionLabel: 'Methods').
		methods do: [:m |
			| item |
			item := self buildMethodItem: m forClass: aNode inContainer: container.
			(aMethodOrNil notNil and: [m name = aMethodOrNil name]) ifTrue: [
				item children first fireEvent: BlClickEvent new ].
			container addChild: item ] ].
	
	container addChild: (self buildDivider).
	container addChild: (self buildClassSourceEditor: aNode inContainer: container).
	
	^ container
]

{ #category : 'verse' }
VerseZealBrowser >> buildClassHeader: aNode [
	"Header — type label + name + show in folder button"
	| header topRow typeLabel |
	header := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 4).
	
	topRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
	
	typeLabel := (aNode isKindOf: ZealInterface) ifTrue: ['interface'] ifFalse: ['class'].
	topRow addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 20; bold);
		text: typeLabel , ' ' , (self toKebab: aNode name)).
	topRow addChild: (self buildShowInFolderButton: aNode).
	header addChild: topRow.
	
	((aNode respondsTo: #specifiers) and: [aNode specifiers notNil and: [aNode specifiers notEmpty]]) ifTrue: [
		header addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: (Color fromHexString: '888888'); fontSize: 11);
			text: 'specifiers: ' , (', ' join: aNode specifiers);
			margin: (BlInsets top: 2)) ].
	
	^ header
]

{ #category : 'verse' }
VerseZealBrowser >> buildClassSourceEditor: aNode inContainer: aContainer [
	"Full Zeal source editor for the entire class. Ctrl+S recompiles and updates."
	| wrapper label editor zealSrc |
	wrapper := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4).
	
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11);
		text: 'Source (Ctrl+S to update class):';
		margin: (BlInsets bottom: 4).
	
	zealSrc := [aNode compileToZeal] on: Error do: [''].
	
	editor := self newZealEditor: zealSrc.
	editor padding: (BlInsets all: 8).
	editor border: (BlBorder paint: (Color fromHexString: '50FA7B') width: 1).
	
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self compileClassSource: editor forNode: aNode inContainer: aContainer ]).
	
	wrapper addChild: label.
	wrapper addChild: editor.
	^ wrapper
]

{ #category : 'verse' }
VerseZealBrowser >> buildCommandBar [
	"Input bar for creating modules and definitions"
	| wrapper label editor |
	wrapper := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
	
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11);
		text: 'New definition (Ctrl+S)';
		margin: (BlInsets top: 4 left: 6 bottom: 2 right: 0).
	
	editor := self newZealEditor: ''.
	editor constraintsDo: [:c | c horizontal matchParent. c vertical exact: 60 ].
	editor padding: (BlInsets all: 6).
	editor margin: (BlInsets top: 0 left: 4 bottom: 4 right: 4).
	editor border: (BlBorder paint: (Color fromHexString: '50FA7B') width: 1).
	
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [
			| input cleaned compiled node resolved isModule |
			input := editor editor text asString trimBoth.
			input isEmpty ifFalse: [
				"Strip parens and check for defmodule"
				cleaned := input.
				(cleaned first = $() ifTrue: [ cleaned := cleaned allButFirst ].
				(cleaned last = $)) ifTrue: [ cleaned := cleaned allButLast ].
				cleaned := cleaned trimBoth.
				isModule := cleaned beginsWith: 'defmodule '.
				isModule ifTrue: [
					self createModule: (cleaned allButFirst: 10) trimBoth.
					self flashSuccess: editor ]
				ifFalse: [ 
					[ compiled := ZealCompiler compile: input.
					  node := (compiled isKindOf: Collection) ifTrue: [compiled first] ifFalse: [compiled].
					  self createDefinition: input.
					  self flashSuccess: editor.
					  resolved := self resolveWord: node name.
					  resolved ifNotNil: [ self selectNode: resolved ] ]
					on: Error do: [
						self flashError: editor ] ] ] ]).
	
	wrapper addChild: label.
	wrapper addChild: editor.
	^ wrapper
]

{ #category : 'verse' }
VerseZealBrowser >> buildCompileAllButton [
	"Button that compiles all definitions and writes .verse files"
	| btn |
	btn := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ];
		padding: (BlInsets top: 4 left: 10 bottom: 4 right: 10);
		background: (Color fromHexString: '2E8B57');
		geometry: (BlRoundedRectangleGeometry cornerRadius: 4);
		mouseCursor: BlHandCursor new.
	btn addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: Color white; fontSize: 12; bold);
		text: 'Compile All').
	btn addEventHandlerOn: BlMouseEnterEvent do: [:e | btn background: (Color fromHexString: '3AAF6E') ].
	btn addEventHandlerOn: BlMouseLeaveEvent do: [:e | btn background: (Color fromHexString: '2E8B57') ].
	btn addEventHandlerOn: BlClickEvent do: [:e | self compileAll ].
	^ btn
]

{ #category : 'verse' }
VerseZealBrowser >> buildDefinitionView: aNode [
	"Build a view for any definition with module, using, and code editor"
	| container source editor |
	((aNode isKindOf: ZealClass) or: [aNode isKindOf: ZealInterface]) ifTrue: [
		^ self buildClassDetail: aNode ].
	
	((aNode isKindOf: ZealFunction) and: [aNode parent notNil and: [
		(aNode parent isKindOf: ZealClass) or: [aNode parent isKindOf: ZealInterface]]]) ifTrue: [
		^ self buildClassDetail: aNode parent expandMethod: aNode ].
	
	container := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 12);
		background: ZealTheme backgroundColor.
	
	container addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 16; bold);
		text: (self labelFor: aNode);
		margin: (BlInsets bottom: 4)).
	
	container addChild: (self buildModuleDropdown: aNode inContainer: container).
	container addChild: (self buildUsingEditor: aNode).
	container addChild: (self buildDivider).
	
	source := self zealSourceFor: aNode generatedClass: (self generatedClassFor: aNode).
	editor := self newZealEditor: source.
	editor padding: (BlInsets all: 8).
	editor border: (BlBorder paint: (Color fromHexString: '9580FF') width: 1).
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self compileAndSave: editor forNode: aNode ]).
	container addChild: editor.
	
	^ container
]

{ #category : 'verse' }
VerseZealBrowser >> buildDetail [
	detailElement := BlElement new.
	detailElement layout: BlLinearLayout vertical.
	detailElement constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
	detailElement background: ZealTheme backgroundColor.
	detailElement padding: (BlInsets all: 12).
	self showWelcome.
	^ detailElement asScrollableElement
]

{ #category : 'verse' }
VerseZealBrowser >> buildExtendsEditor: aNode inContainer: aContainer [
	"Editable extends field for classes/interfaces"
	| row extensionsEditor currentExtensions strategy |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4 bottom: 4).
	
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 13; bold);
		text: 'extends: ';
		margin: (BlInsets right: 4)).
	
	currentExtensions := OrderedCollection new.
	((aNode respondsTo: #superclass) and: [aNode superclass notNil]) ifTrue: [
		currentExtensions add: (self toKebab: aNode superclass) ].
	((aNode respondsTo: #interfaces) and: [aNode interfaces notNil]) ifTrue: [
		aNode interfaces do: [:i | currentExtensions add: (self toKebab: i) ] ].
	((aNode respondsTo: #parents) and: [aNode parents notNil]) ifTrue: [
		aNode parents do: [:p | currentExtensions add: (self toKebab: p) ] ].
	
	extensionsEditor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: ((', ' join: currentExtensions) asRopedText foreground: ZealTheme symbolColor);
		background: (ZealTheme backgroundColor darker);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 4);
		border: (BlBorder paint: (Color fromHexString: '444444') width: 1).
	
	strategy := ZealExtensionCompletionStrategy new project: project.
	(GtCompletionController on: extensionsEditor strategy: strategy) install.
	
	extensionsEditor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [
			| newExts parts |
			newExts := extensionsEditor editor text asString trimBoth.
			parts := (newExts substrings: ',') collect: [:p | p trimBoth].
			parts := parts reject: [:p | p isEmpty].
			(aNode respondsTo: #superclass:) ifTrue: [
				aNode superclass: (parts isEmpty ifTrue: [nil] ifFalse: [parts first]) ].
			(aNode respondsTo: #interfaces:) ifTrue: [
				aNode interfaces: (parts size > 1 ifTrue: [parts allButFirst] ifFalse: [#()]) ].
			(aNode respondsTo: #parents:) ifTrue: [
				aNode parents: parts ].
			self persistNode: aNode.
			self flashSuccess: extensionsEditor ]).
	
	row addChild: extensionsEditor.
	^ row
]

{ #category : 'verse' }
VerseZealBrowser >> buildMethodItem: aMethod [
	"A collapsible method — simple toggle with arrow (no class context)"
	| container headerRow sig expanded contentHolder arrow label |
	sig := (self toKebab: aMethod name).
	aMethod type ifNotNil: [:t | sig := sig , ':' , t ].
	sig := sig , ' ['.
	sig := sig , (', ' join: (aMethod parameters collect: [:p | 
		| ps |
		ps := self toKebab: p name.
		p type ifNotNil: [:t | ps := ps , ':' , t ].
		ps ])).
	sig := sig , ']'.
	
	container := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 2 left: 8 bottom: 2 right: 0).
	
	contentHolder := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		visibility: BlVisibility gone.
	
	expanded := false.
	
	headerRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 4);
		background: (ZealTheme backgroundColor darker).
	
	arrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme parenColor; fontSize: 11);
		text: '▶';
		margin: (BlInsets right: 6).
	
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
		text: sig.
	
	headerRow addChild: arrow.
	headerRow addChild: label.
	
	headerRow addEventHandlerOn: BlClickEvent do: [:e |
		| source editor |
		expanded := expanded not.
		expanded ifTrue: [
			arrow text: ('▼' asRopedText foreground: ZealTheme parenColor).
			contentHolder removeChildren.
			source := [aMethod compileToZeal] on: Error do: [''].
			editor := self newZealEditor: source.
			editor margin: (BlInsets top: 4).
			editor border: (BlBorder paint: (Color fromHexString: '9580FF') width: 1).
			editor addShortcut: (BlShortcutWithAction new 
				combination: BlKeyCombination primaryS;
				action: [ self compileAndSave: editor forNode: aMethod ]).
			contentHolder addChild: editor.
			contentHolder visibility: BlVisibility visible ]
		ifFalse: [
			arrow text: ('▶' asRopedText foreground: ZealTheme parenColor).
			contentHolder visibility: BlVisibility gone ] ].
	
	container addChild: headerRow.
	container addChild: contentHolder.
	^ container
]

{ #category : 'verse' }
VerseZealBrowser >> buildMethodItem: aMethod forClass: aClassNode inContainer: aContainer [
	"A collapsible method with minus button to remove"
	| container headerRow sig expanded contentHolder arrow label minusBtn |
	sig := (self toKebab: aMethod name).
	aMethod type ifNotNil: [:t | sig := sig , ':' , t ].
	sig := sig , ' ['.
	sig := sig , (', ' join: (aMethod parameters collect: [:p | 
		| ps |
		ps := self toKebab: p name.
		p type ifNotNil: [:t | ps := ps , ':' , t ].
		ps ])).
	sig := sig , ']'.
	
	container := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 2 left: 8 bottom: 2 right: 0).
	
	contentHolder := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		visibility: BlVisibility gone.
	
	expanded := false.
	
	headerRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 4);
		background: (ZealTheme backgroundColor darker).
	
	minusBtn := self buildMinusButton: [
			(aClassNode respondsTo: #methods) ifTrue: [
				aClassNode methods ifNotNil: [:ms | ms remove: aMethod ifAbsent: [] ] ].
			self persistNode: aClassNode.
			self rebuildClassIn: aContainer node: aClassNode ].
	
	arrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme parenColor; fontSize: 11);
		text: '▶';
		margin: (BlInsets right: 6).
	
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
		text: sig.
	
	headerRow addChild: minusBtn.
	headerRow addChild: arrow.
	headerRow addChild: label.
	
	headerRow addEventHandlerOn: BlClickEvent do: [:e |
		| source editor |
		(e target == minusBtn or: [minusBtn children anySatisfy: [:c | e target == c]]) ifFalse: [
			expanded := expanded not.
			expanded ifTrue: [
				arrow text: ('▼' asRopedText foreground: ZealTheme parenColor).
				contentHolder removeChildren.
				"Use compileToZeal directly — don't look up generated class for methods"
				source := [aMethod compileToZeal] on: Error do: [''].
				editor := self newZealEditor: source.
				editor margin: (BlInsets top: 4).
				editor border: (BlBorder paint: (Color fromHexString: '9580FF') width: 1).
				editor addShortcut: (BlShortcutWithAction new 
					combination: BlKeyCombination primaryS;
					action: [ self compileAndSave: editor forNode: aMethod ]).
				contentHolder addChild: editor.
				contentHolder visibility: BlVisibility visible ]
			ifFalse: [
				arrow text: ('▶' asRopedText foreground: ZealTheme parenColor).
				contentHolder visibility: BlVisibility gone ] ] ].
	
	container addChild: headerRow.
	container addChild: contentHolder.
	^ container
]

{ #category : 'verse' }
VerseZealBrowser >> buildMinusButton: aBlock [
	"A themed minus button"
	| btn label |
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: (Color fromHexString: 'CCCCCC'); fontSize: 14);
		text: '−'.
	btn := BlElement new
		layout: BlFrameLayout new;
		constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ];
		padding: (BlInsets top: 1 left: 6 bottom: 1 right: 6);
		margin: (BlInsets right: 6);
		background: (Color fromHexString: '333333');
		geometry: (BlRoundedRectangleGeometry cornerRadius: 3);
		mouseCursor: BlHandCursor new;
		addChild: label.
	btn addEventHandlerOn: BlMouseEnterEvent do: [:e | btn background: (Color fromHexString: 'FF4444') ].
	btn addEventHandlerOn: BlMouseLeaveEvent do: [:e | btn background: (Color fromHexString: '333333') ].
	btn addEventHandlerOn: BlClickEvent do: [:e | e consumed: true. aBlock value ].
	^ btn
]

{ #category : 'verse' }
VerseZealBrowser >> buildModuleDropdown: aNode inContainer: aContainer [
	"A themed dropdown to move a definition between modules"
	| row currentMod moduleNames currentName btn |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4 bottom: 4).
	
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 13; bold);
		text: 'module: ';
		margin: (BlInsets right: 4)).
	
	currentMod := self currentModuleOf: aNode.
	moduleNames := self allModuleNames.
	currentName := currentMod ifNotNil: [currentMod name] ifNil: ['(none)'].
	
	btn := BlElement new
		layout: BlFrameLayout new;
		constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ];
		padding: (BlInsets top: 4 left: 10 bottom: 4 right: 10);
		background: (Color fromHexString: '333333');
		geometry: (BlRoundedRectangleGeometry cornerRadius: 4);
		mouseCursor: BlHandCursor new;
		addChild: (BrLabel new
			id: #moduleLabel;
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
			text: currentName).
	
	btn aptitude: (BrGlamorousWithDropdownAptitude
		handle: [
			BlElement new
				layout: BlFrameLayout new;
				constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ];
				padding: (BlInsets top: 4 left: 10 bottom: 4 right: 10);
				background: (Color fromHexString: '333333');
				geometry: (BlRoundedRectangleGeometry cornerRadius: 4);
				addChild: (BrLabel new
					aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
					text: ((self currentModuleOf: aNode) ifNotNil: [:m | m name] ifNil: ['(none)'])) ] asStencil
		content: [
			BrSimpleList new
				fitContentLimited;
				background: ZealTheme backgroundColor;
				border: (BlBorder paint: (Color fromHexString: '9580FF') width: 1);
				items: (self allModuleNames);
				itemStencil: [
					| item |
					item := BlElement new
						layout: BlFrameLayout new;
						constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
						padding: (BlInsets all: 6);
						mouseCursor: BlHandCursor new;
						addChild: (BrLabel new
							id: #itemLabel;
							aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor)).
					item addEventHandlerOn: BlMouseEnterEvent do: [:e |
						item background: (Color fromHexString: '444444') ].
					item addEventHandlerOn: BlMouseLeaveEvent do: [:e |
						item background: Color transparent ].
					item ];
				itemDataBinder: [:row2 :assoc |
					row2 childWithId: #itemLabel ifFound: [:lbl |
						lbl text: (assoc key asRopedText foreground: ZealTheme symbolColor) ] ifNone: [].
					row2 addEventHandlerOn: BlClickEvent do: [:e |
						self moveNode: aNode toModule: assoc value.
						self rebuildTree.
						btn childWithId: #moduleLabel ifFound: [:l |
							l text: (assoc value name asRopedText foreground: ZealTheme symbolColor) ] ifNone: [].
						btn dispatchEvent: BrDropdownHideWish new ] ] ] asStencil).
	
	row addChild: btn.
	^ row
]

{ #category : 'verse' }
VerseZealBrowser >> buildSectionWithAdd: title count: count action: aBlock [
	"Section label with a + button"
	| row label |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
	
	label := count > 0 
		ifTrue: [ title , ' (' , count printString , ')' ]
		ifFalse: [ title ].
	
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 15; bold);
		text: label).
	
	row addChild: (BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: '+';
		beSmallSize;
		margin: (BlInsets left: 8);
		action: aBlock).
	
	^ row
]

{ #category : 'verse' }
VerseZealBrowser >> buildShowInFolderButton: aNode [
	"Button that opens the .verse file location in Windows Explorer"
	^ BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Show in Folder';
		margin: (BlInsets left: 8);
		action: [
			| filePath |
			filePath := self verseFilePathForDefinition: aNode.
			filePath ifNotNil: [
				filePath asFileReference exists
					ifTrue: [
						GtExternalProcessBuilder new
							command: 'explorer';
							arg: '/select,'; arg: filePath fullName;
							spawn ]
					ifFalse: [
						"Open the containing folder"
						| dir |
						dir := filePath asFileReference parent.
						dir exists ifTrue: [
							GtExternalProcessBuilder new
								command: 'explorer';
								arg: dir fullName;
								spawn ] ] ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> buildSlotItem: aField forClass: aClassNode inContainer: aContainer [
	"A clickable slot row with minus button to remove"
	| row label isMut labelEl minusBtn |
	isMut := (aField respondsTo: #isMutable) ifTrue: [aField isMutable] ifFalse: [false].
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets top: 3 left: 12 bottom: 3 right: 4).
	
	"Minus button"
	minusBtn := self buildMinusButton: [
			(aClassNode respondsTo: #fields) ifTrue: [
				aClassNode fields ifNotNil: [:fs | fs remove: aField ifAbsent: [] ] ].
			(aClassNode respondsTo: #methods) ifTrue: [
				aClassNode methods ifNotNil: [:ms | ms remove: aField ifAbsent: [] ] ].
			self rebuildClassIn: aContainer node: aClassNode ].
	row addChild: minusBtn.
	
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme operatorColor; fontSize: 15);
		text: (isMut ifTrue: ['~'] ifFalse: ['=']);
		margin: (BlInsets right: 6)).
	
	label := self toKebab: aField name.
	(aField respondsTo: #type) ifTrue: [ aField type ifNotNil: [:t | label := label , ':' , t ] ].
	((aField respondsTo: #defaultValue) ifTrue: [aField defaultValue] ifFalse: [
		(aField respondsTo: #value) ifTrue: [aField value] ifFalse: [nil]]) ifNotNil: [:v |
		label := label , ' = ' , ([String streamContents: [:s | v compileToZeal: s indent: 0]] on: Error do: [v printString]) ].
	
	labelEl := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 15);
		text: (label asRopedText monospace).
	
	row addEventHandlerOn: BlClickEvent do: [:e |
		(e target == minusBtn or: [minusBtn children anySatisfy: [:c | e target == c]]) ifFalse: [
			row phlow spawnTool: (GtPhlowExplicitTool new
				name: 'Slots';
				stencil: [ self wrapInDarkPage: (self buildAllSlotsEditor: aClassNode inContainer: aContainer) ]) ] ].
	row mouseCursor: BlHandCursor new.
	
	row addChild: labelEl.
	^ row
]

{ #category : 'verse' }
VerseZealBrowser >> buildTree [
	treeElement := BrSimpleTree new.
	treeElement
		nodeStencil: [
			BlElement new
				layout: BlLinearLayout horizontal alignCenterLeft;
				constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
				addChild: (BlElement new id: #removeHolder;
					layout: BlLinearLayout horizontal;
					constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ]);
				addChild: (BlElement new id: #iconHolder; 
					constraintsDo: [:c | c horizontal exact: 22. c vertical exact: 18 ]);
				addChild: (BrLabel new aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme foregroundColor; fontSize: 13); id: #name) ];
		nodeDataBinder: [ :row :item |
			row childWithId: #removeHolder ifFound: [:holder |
				holder removeChildren.
				((item isKindOf: ZealTreeGroup) or: [item isKindOf: ZealModule]) ifFalse: [
					holder addChild: (self buildMinusButton: [
						self removeDefinition: item. self rebuildTree ]) ] ].
			row childWithId: #iconHolder ifFound: [:holder |
				holder removeChildren.
				holder addChild: (self iconElementFor: item) ].
			row childWithId: #name ifFound: [:lbl |
				lbl text: ((self labelFor: item) asRopedText foreground: ZealTheme foregroundColor) ] ];
		items: project modules lazy: [ :item | self childrenOf: item ];
		when: BrSelectionChanged do: [:event |
			event indices ifNotEmpty: [:indices |
				treeElement selectedNodeDo: [:treeNode |
					self selectNode: treeNode value ] ] ].
	treeElement background: (ZealTheme backgroundColor lighter).
	treeElement constraintsDo: [:c | c horizontal exact: 280. c vertical matchParent ].
	treeElement padding: (BlInsets all: 8).
	^ treeElement
]

{ #category : 'verse' }
VerseZealBrowser >> buildUI [
	| leftPane topBar content mainLayout chatBtn |
	self removeChildren.
	
	topBar := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		background: (ZealTheme backgroundColor darker);
		padding: (BlInsets all: 6).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 14; bold);
		text: 'Zeal // ' , project name;
		margin: (BlInsets right: 12)).
	topBar addChild: (self buildCompileAllButton).
	
	"Chat toggle button"
	chatBtn := BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Chat';
		margin: (BlInsets left: 8);
		action: [ self toggleChat ].
	topBar addChild: chatBtn.
	
	content := BlElement new
		layout: BlLinearLayout horizontal;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	
	leftPane := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal exact: 280. c vertical matchParent ];
		background: (ZealTheme backgroundColor lighter).
	leftPane addChild: self buildTree.
	treeElement constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	leftPane addChild: self buildCommandBar.
	content addChild: leftPane.
	content addChild: self buildDetail.
	
	mainLayout := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	mainLayout addChild: topBar.
	mainLayout addChild: content.
	self addChild: mainLayout
]

{ #category : 'verse' }
VerseZealBrowser >> buildUsingEditor: aNode [
	"Editable using paths — comma separated, Ctrl+S to save, with module completion"
	| row editor currentUsings strategy |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 2 bottom: 4).
	
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 13; bold);
		text: 'using: ';
		margin: (BlInsets right: 4)).
	
	currentUsings := aNode usings collect: [:u | 
		(u respondsTo: #path) ifTrue: [u path] ifFalse: [u printString] ].
	
	editor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: ((', ' join: currentUsings) asRopedText foreground: ZealTheme symbolColor);
		background: (ZealTheme backgroundColor darker);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 4);
		border: (BlBorder paint: (Color fromHexString: '444444') width: 1).
	
	"Module completion"
	strategy := ZealModuleCompletionStrategy new project: project.
	editor enqueueTask: (BlTaskAction new action: [
		| controller |
		controller := GtCompletionController on: editor strategy: strategy.
		controller install.
		controller showOnTextModification: true ]).
	
	"Ctrl+S saves usings and persists to disk"
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [
			| text paths targetNode |
			text := editor editor text asString trimBoth.
			paths := (text substrings: ',') collect: [:p | p trimBoth].
			paths := paths reject: [:p | p isEmpty].
			aNode usings: (paths collect: [:p | ZealUsing new path: p]).
			"For methods/fields inside a class, persist the owning class"
			targetNode := ((aNode isKindOf: ZealClass) or: [aNode isKindOf: ZealInterface])
				ifTrue: [ aNode ]
				ifFalse: [ aNode owningClass ifNil: [ aNode ] ].
			self persistNode: targetNode.
			self flashSuccess: editor ]).
	
	row addChild: editor.
	^ row
]

{ #category : 'verse' }
VerseZealBrowser >> chatSystemPrompt [
	^ 'You are a Zeal programming assistant embedded in the Zeal IDE.
Zeal is a Lisp-syntax language that transpiles to Epic Verse (UEFN).

IMPORTANT: Use ```zeal for code blocks. NEVER use ```clojure or ```lisp.

KEY TOOLS — use these to make changes:
- zealUpdateDefinition(name, zealCode) — Update or replace ANY definition (function, class, interface, etc.). Use this for top-level definitions.
- zealAddToClass(className, zealCode) — Add a field or method to a class, or replace the entire class.
- zealGetDefinition(name) — Look up any definition by name. Use before modifying.
- zealCompile(zealSource) — Test-compile Zeal to Verse without saving.
- zealListDefinitions(moduleName) — List definitions (empty string = all modules).
- zealSyntaxReference() — Get Zeal syntax reference.
- zealSetUsings(name, usings) — Set using declarations on a definition. Comma-separated paths like "/Verse.org/Random, /Fortnite.com/Devices".

WORKFLOW: When asked to modify code, ALWAYS:
1. Use zealGetDefinition to see current code
2. Use zealUpdateDefinition or zealAddToClass to make the change
3. If external modules are needed, use zealSetUsings to add the using paths
4. Confirm what you changed

Be concise. Context about the selected definition is provided below.'
]

{ #category : 'verse' }
VerseZealBrowser >> childrenOf: item [
	"Modules show definitions grouped by type, alphabetically sorted."
	(item isKindOf: ZealModule) ifTrue: [ 
		| allDefs subModules classes interfaces structs enums functions variables groups |
		allDefs := OrderedCollection new.
		subModules := OrderedCollection new.
		item definitions do: [:d |
			(d isKindOf: ZealModule) ifTrue: [ subModules add: d ]
			ifFalse: [ allDefs add: d ] ].
		
		classes := (allDefs select: [:d | d isKindOf: ZealClass]) sorted: [:a :b | a name asLowercase < b name asLowercase].
		interfaces := (allDefs select: [:d | d isKindOf: ZealInterface]) sorted: [:a :b | a name asLowercase < b name asLowercase].
		structs := (allDefs select: [:d | d isKindOf: ZealStruct]) sorted: [:a :b | a name asLowercase < b name asLowercase].
		enums := (allDefs select: [:d | d isKindOf: ZealEnum]) sorted: [:a :b | a name asLowercase < b name asLowercase].
		functions := (allDefs select: [:d | d isKindOf: ZealFunction]) sorted: [:a :b | a name asLowercase < b name asLowercase].
		variables := (allDefs select: [:d | (d isKindOf: ZealVariable) or: [d isKindOf: ZealField]]) sorted: [:a :b | a name asLowercase < b name asLowercase].
		subModules := subModules sorted: [:a :b | a name asLowercase < b name asLowercase].
		
		groups := OrderedCollection new.
		subModules notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Modules'; items: subModules) ].
		classes notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Classes'; items: classes) ].
		interfaces notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Interfaces'; items: interfaces) ].
		structs notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Structs'; items: structs) ].
		enums notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Enums'; items: enums) ].
		functions notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Functions'; items: functions) ].
		variables notEmpty ifTrue: [ groups add: (ZealTreeGroup new name: 'Variables'; items: variables) ].
		^ groups ].
	
	(item isKindOf: ZealTreeGroup) ifTrue: [ ^ item items ].
	^ #()
]

{ #category : 'verse' }
VerseZealBrowser >> collectModuleNames: aModule path: prefix into: result [
	"Only collect folder modules, NOT file namespaces"
	aModule definitions do: [:d |
		((d isKindOf: ZealModule) and: [d kind = #folder]) ifTrue: [
			| fullPath |
			fullPath := prefix isEmpty 
				ifTrue: [ d name ] 
				ifFalse: [ prefix , '/' , d name ].
			result add: fullPath -> d.
			self collectModuleNames: d path: fullPath into: result ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> compileAll [
	"Compile all definitions and write each to its own .verse file"
	| count |
	count := 0.
	project modules do: [:mod |
		mod definitions do: [:ns |
			(ns isKindOf: ZealModule) ifTrue: [
				ns definitions do: [:defn |
					((defn respondsTo: #name) and: [defn name notNil]) ifTrue: [
						| zealSrc verseStr genClass filePath |
						"Get Zeal source"
						genClass := self generatedClassFor: defn.
						zealSrc := self zealSourceFor: defn generatedClass: genClass.
						
						"Compile to Verse"
						[ | compiled nodes |
						  compiled := ZealCompiler compile: zealSrc.
						  nodes := (compiled isKindOf: Collection) ifTrue: [compiled] ifFalse: [{compiled}].
						  verseStr := String streamContents: [:s |
							nodes do: [:n | n compileToVerse: s indent: 0] separatedBy: [s cr; cr] ].
						  
						  "Store in generated class"
						  genClass ifNotNil: [
							genClass class compile: ('zealSource
	^ ' , zealSrc printString) classified: 'zeal'.
							genClass class compile: ('verseSource
	^ ' , verseStr printString) classified: 'zeal' ].
						  
						  "Write .verse file with using declarations"
						  filePath := self verseFilePathForDefinition: defn.
						  filePath ifNotNil: [
							filePath asFileReference ensureDelete.
							filePath asFileReference writeStreamDo: [:ws |
								defn usings do: [:u | ws nextPutAll: 'using { '; nextPutAll: u path; nextPutAll: ' }'; cr].
								defn usings notEmpty ifTrue: [ws cr].
								ws nextPutAll: verseStr ] ].
						  
						  count := count + 1 ]
						on: Error do: [ "skip broken definitions" ] ] ] ] ] ].
	
	Smalltalk globals at: #ZealDebug put: 'Compiled ' , count printString , ' definitions'
]

{ #category : 'actions' }
VerseZealBrowser >> compileAndSave: anEditor forNode: aNode [
	"Compile Zeal → sync node → persist to class and .verse file."
	| zealSource compiled compiledNodes isExpander oldZeal |
	zealSource := anEditor editor text asString.
	
	[ compiled := ZealCompiler compile: zealSource ] on: Error do: [:e |
		self flashError: anEditor. ^ self ].
	
	compiledNodes := (compiled isKindOf: Collection) ifTrue: [compiled] ifFalse: [{compiled}].
	
	"Verify verse output compiles"
	[compiledNodes do: [:n | n compileToVerse]] on: Error do: [:e |
		self flashError: anEditor. ^ self ].
	
	aNode rawSource: nil.
	isExpander := aNode ~~ selectedNode.
	
	"Capture old zeal BEFORE syncing"
	oldZeal := [String streamContents: [:s | aNode compileToZeal: s indent: 0]] on: Error do: [nil].
	
	"Sync node if single definition"
	(compiledNodes size = 1 and: [isExpander not or: [(aNode isKindOf: ZealModule) not]]) ifTrue: [
		self syncNode: aNode withCompiled: compiledNodes first ].
	
	"Persist — uses unified persistNode:"
	self persistNode: aNode.
	
	"If saving a method/field inside a class, also persist the owning class"
	(aNode parent notNil and: [
		(aNode parent isKindOf: ZealClass) or: [aNode parent isKindOf: ZealInterface]]) ifTrue: [
		self persistNode: aNode parent ].
	
	self flashSuccess: anEditor.
	
	"Surgical update for expander saves"
	(isExpander and: [zealEditor notNil]) ifTrue: [
		(oldZeal notNil and: [zealEditor editor text asString includesSubstring: oldZeal]) ifTrue: [
			| edText newZealSource |
			edText := zealEditor editor text asString.
			newZealSource := edText copyReplaceAll: oldZeal with: zealSource.
			zealEditor editor text: (newZealSource asRopedText).
			self scheduleRehighlight: zealEditor ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> compileClassSource: editor forNode: aNode inContainer: aContainer [
	"Compile the full class source editor, rebuild the view, restore cursor"
	| src compiled cursorPos |
	src := editor editor text asString trimBoth.
	src isEmpty ifTrue: [ ^ self ].
	
	cursorPos := 0.
	editor editor cursors do: [:c | cursorPos := c position].
	
	[ compiled := ZealCompiler compile: src.
	  compiled := (compiled isKindOf: Collection) ifTrue: [compiled first] ifFalse: [compiled] ]
		on: Error do: [:e | self flashError: editor. ^ self ].
	
	"If they typed a field or method, add it to the class"
	((compiled isKindOf: ZealFunction) or: [compiled isKindOf: ZealVariable]) ifTrue: [
		self addCompiled: compiled to: aNode.
		self persistNode: aNode.
		self flashSuccess: editor.
		self rebuildClassIn: aContainer node: aNode.
		^ self ].
	
	((compiled isKindOf: ZealClass) or: [compiled isKindOf: ZealInterface]) ifFalse: [
		self flashError: editor. ^ self ].
	
	"Replace the class"
	compiled generatedClass: aNode generatedClass.
	compiled usings: aNode usings.
	
	project modules do: [:m |
		| defs idx |
		defs := (m instVarNamed: 'definitions') asOrderedCollection.
		idx := defs indexOf: aNode.
		idx > 0 ifTrue: [
			defs at: idx put: compiled.
			m instVarNamed: 'definitions' put: defs asArray ] ].
	
	self persistNode: compiled.
	selectedNode := compiled.
	self rebuildTree.
	self selectNode: compiled.
	
	"Restore cursor in the new source editor"
	detailElement allChildrenBreadthFirstDo: [:el |
		(el isKindOf: BrEditor) ifTrue: [
			| border |
			border := [el border paint color green > 0.8] on: Error do: [false].
			border ifTrue: [
				el enqueueTask: (BlTaskAction new action: [
					el requestFocus.
					el editor navigator moveTo: (cursorPos min: el editor text size); apply ]) ] ] ]
]

{ #category : 'building' }
VerseZealBrowser >> configureZealEditor: anEditor [
	"Verse editor: shared setup + completion + browse shortcut"
	super configureZealEditor: anEditor.
	self setupCompletion: anEditor.
	
	anEditor addShortcut: (BlShortcutWithAction new
		combination: (BlKeyCombination builder control b build);
		action: [ self browseDefinitionAt: anEditor ])
]

{ #category : 'verse' }
VerseZealBrowser >> createDefinition: zealSource [
	"Compile Zeal source and add/replace definition directly in the root module."
	| compiled nodes rootMod |
	[ compiled := ZealCompiler compile: zealSource ] on: Error do: [ ^ self ].
	nodes := (compiled isKindOf: Collection) ifTrue: [compiled] ifFalse: [{compiled}].
	rootMod := project modules first.
	
	nodes do: [:node |
		| nodeName |
		nodeName := (node respondsTo: #name) ifTrue: [node name] ifFalse: [nil].
		nodeName ifNotNil: [
			"Remove any existing definition with same name"
			rootMod definitions: (rootMod definitions asOrderedCollection reject: [:d |
				((d respondsTo: #name) and: [d name notNil]) and: [
				d name asLowercase = nodeName asLowercase] ]) asArray ] ].
	
	"Add all new nodes directly to root module"
	nodes do: [:node |
		rootMod definitions: (rootMod definitions asOrderedCollection add: node; yourself) asArray.
		self persistDefinition: node inNamespace: rootMod ].
	
	self rebuildTree
]

{ #category : 'verse' }
VerseZealBrowser >> createModule: nameStr [
	"Create a folder module — removes any existing definition with same name first"
	| parts current packageName parentClassName parentClass |
	parts := nameStr substrings: '/'.
	current := project modules first.
	packageName := 'ZealProject-' , (project name copyReplaceAll: ' ' with: '').
	parentClassName := 'Zeal_' , (ZealClassGenerator toPascalCase: project name) , '_' , (ZealClassGenerator toPascalCase: current name).
	parentClass := Smalltalk globals at: parentClassName asSymbol ifAbsent: [nil].
	
	parts do: [:part |
		| existing newMod modClassName modClass toRemove |
		"Remove any non-folder definition with same name"
		toRemove := current definitions asOrderedCollection select: [:d |
			((d respondsTo: #name) and: [d name notNil and: [d name asLowercase = part asLowercase]]) 
				and: [((d isKindOf: ZealModule) and: [d kind = #folder]) not] ].
		toRemove do: [:d | 
			(self generatedClassFor: d) ifNotNil: [:gc | gc removeFromSystem ] ].
		current definitions: (current definitions asOrderedCollection removeAll: toRemove; yourself) asArray.
		
		existing := current definitions asOrderedCollection
			detect: [:d | (d isKindOf: ZealModule) and: [d name = part and: [d kind = #folder]]] 
			ifNone: [nil].
		existing ifNotNil: [ 
			current := existing.
			parentClass := Smalltalk globals at: (parentClassName , '_' , (ZealClassGenerator toPascalCase: part)) asSymbol ifAbsent: [parentClass].
			parentClassName := parentClassName , '_' , (ZealClassGenerator toPascalCase: part) ]
		ifNil: [
			newMod := ZealModule new name: part; kind: #folder; definitions: #().
			current definitions: (current definitions asOrderedCollection add: newMod; yourself) asArray.
			parentClass ifNotNil: [
				modClassName := parentClassName , '_' , (ZealClassGenerator toPascalCase: part).
				modClass := ZealClassGenerator ensureClass: modClassName superclass: parentClass trait: TZealModule package: packageName.
				modClass class compile: ('zealSource ^ ''module: ' , part , '''') classified: 'zeal'.
				modClass class compile: ('verseSource ^ ''module: ' , part , '''') classified: 'zeal'.
				parentClass := modClass.
				parentClassName := modClassName ].
			current := newMod ] ].
	
	self rebuildTree
]

{ #category : 'verse' }
VerseZealBrowser >> currentModuleOf: aNode [
	"Find which module a definition currently lives in"
	| found |
	found := nil.
	project modules do: [:mod |
		self searchModule: mod forNode: aNode path: '' found: [:m | found := m ] ].
	^ found
]

{ #category : 'verse' }
VerseZealBrowser >> expandedNodeNames [
	"Get names of currently expanded expander nodes from the main editor"
	| names |
	names := OrderedCollection new.
	zealEditor ifNil: [ ^ names ].
	zealEditor editor text 
		attributeRunsDo: [:start :end :attrs |
			attrs do: [:a |
				(a isKindOf: ZealExpanderAttribute) ifTrue: [
					a isExpanded ifTrue: [ 
						(a instVarNamed: 'zealNode') ifNotNil: [:n | names add: n name ] ] ] ] ].
	^ names
]

{ #category : 'verse' }
VerseZealBrowser >> generatedClassFor: aNode [
	"Find the generated Smalltalk class for a ZealNode. 
	 Checks cached reference first, then name-based lookup."
	| name gc |
	(aNode respondsTo: #generatedClass) ifTrue: [
		gc := aNode generatedClass.
		gc ifNotNil: [ ^ gc ] ].
	(aNode respondsTo: #name) ifFalse: [ ^ nil ].
	name := aNode name ifNil: [ ^ nil ].
	gc := Smalltalk allClassesAndTraits 
		detect: [:c | 
			(c name beginsWith: 'Zeal_') and: [
				c name endsWith: '_' , (ZealClassGenerator toPascalCase: name) ] ]
		ifNone: [ nil ].
	"Cache it on the node"
	(gc notNil and: [aNode respondsTo: #generatedClass:]) ifTrue: [ aNode generatedClass: gc ].
	^ gc
]

{ #category : 'verse' }
VerseZealBrowser >> highlightWithExpanders: zealText [
	^ self highlightWithExpanders: zealText nested: false
]

{ #category : 'verse' }
VerseZealBrowser >> highlightWithExpanders: zealText nested: isNested [
	"Highlight Zeal source and attach inline expanders"
	| highlighted resolver |
	highlighted := ZealTheme highlight: zealText.
	resolver := ZealCompiler currentResolver ifNil: [ 
		project ifNotNil: [ ZealTypeResolver forProject: project ] ].
	ZealTheme attachExpanders: highlighted source: zealText resolver: resolver browser: self nested: isNested.
	^ highlighted
]

{ #category : 'verse' }
VerseZealBrowser >> iconColorFor: item [
	"Muted colors for tree badges"
	(item isKindOf: ZealTreeGroup) ifTrue: [ ^ Color fromHexString: '444444' ].
	(item isKindOf: ZealModule) ifTrue: [ ^ Color fromHexString: '2D6A8A' ].
	(item isKindOf: ZealClass) ifTrue: [ ^ Color fromHexString: '6B5AA6' ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ Color fromHexString: '2E8B57' ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ Color fromHexString: '8B5A6B' ].
	(item isKindOf: ZealEnum) ifTrue: [ ^ Color fromHexString: '8B6E2E' ].
	(item isKindOf: ZealFunction) ifTrue: [ ^ Color fromHexString: '4A7A8A' ].
	(item isKindOf: ZealVariable) ifTrue: [ ^ Color fromHexString: '7A5A9A' ].
	^ Color fromHexString: '555555'
]

{ #category : 'verse' }
VerseZealBrowser >> iconElementFor: item [
	"Colored badge with letter — visible on dark theme"
	| badge label |
	badge := BlElement new
		layout: BlFrameLayout new;
		constraintsDo: [:c | c horizontal exact: 22. c vertical exact: 18 ];
		geometry: (BlRoundedRectangleGeometry cornerRadius: 3);
		background: (self iconColorFor: item);
		margin: (BlInsets right: 6).
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: Color white; fontSize: 11; bold);
		text: (self badgeLetterFor: item);
		constraintsDo: [:c | c frame horizontal alignCenter. c frame vertical alignCenter ].
	badge addChild: label.
	^ badge
]

{ #category : 'verse' }
VerseZealBrowser >> iconFor: item [
	"Return an emoji icon for tree items"
	(item isKindOf: ZealModule) ifTrue: [ ^ '📦 ' ].
	(item isKindOf: ZealClass) ifTrue: [ ^ '🔷 ' ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ '🔶 ' ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ '🧱 ' ].
	(item isKindOf: ZealEnum) ifTrue: [ ^ '📋 ' ].
	(item isKindOf: ZealFunction) ifTrue: [ ^ '⚡ ' ].
	(item isKindOf: ZealVariable) ifTrue: [ ^ '💎 ' ].
	^ '▪ '
]

{ #category : 'verse' }
VerseZealBrowser >> labelFor: item [
	(item isKindOf: ZealTreeGroup) ifTrue: [ ^ item name ].
	(item isKindOf: ZealModule) ifTrue: [ ^ item name ].
	(item isKindOf: ZealClass) ifTrue: [ ^ item name ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ item name ].
	(item isKindOf: ZealEnum) ifTrue: [ ^ item name ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ item name ].
	(item isKindOf: ZealFunction) ifTrue: [
		^ item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealVariable) ifTrue: [ 
		^ item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealField) ifTrue: [ 
		^ item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealCompileError) ifTrue: [ ^ '! ' , (item message copyFrom: 1 to: (item message size min: 50)) ].
	^ item printString
]

{ #category : 'verse' }
VerseZealBrowser >> metadataForNode: aNode [
	"Extract all metadata from a node as a dictionary for storage on the generated class"
	| meta |
	meta := Dictionary new.
	meta at: 'name' put: aNode name.
	meta at: 'type' put: ((aNode respondsTo: #type) ifTrue: [aNode type] ifFalse: [nil]).
	meta at: 'nodeClass' put: aNode class name asString.
	meta at: 'specifiers' put: aNode specifiers asArray.
	meta at: 'usings' put: ((aNode respondsTo: #usings) 
		ifTrue: [aNode usings collect: [:u | (u respondsTo: #path) ifTrue: [u path] ifFalse: [u printString]]]
		ifFalse: [#()]) asArray.
	
	"Class/interface specific"
	(aNode isKindOf: ZealClass) ifTrue: [
		meta at: 'superclass' put: aNode superclass.
		meta at: 'interfaces' put: aNode interfaces asArray.
		meta at: 'fields' put: (aNode fields collect: [:f |
			Dictionary new
				at: 'name' put: f name;
				at: 'type' put: ((f respondsTo: #type) ifTrue: [f type] ifFalse: [nil]);
				at: 'mutable' put: ((f respondsTo: #isMutable) ifTrue: [f isMutable] ifFalse: [false]);
				at: 'default' put: ([String streamContents: [:s | 
					((f respondsTo: #defaultValue) ifTrue: [f defaultValue] ifFalse: [
					 (f respondsTo: #value) ifTrue: [f value] ifFalse: [nil]]) 
						ifNotNil: [:v | v compileToZeal: s indent: 0]]] on: Error do: [nil]);
				yourself ]) asArray.
		meta at: 'methods' put: (aNode methods collect: [:m |
			Dictionary new
				at: 'name' put: m name;
				at: 'type' put: m type;
				at: 'specifiers' put: m specifiers asArray;
				at: 'params' put: (m parameters collect: [:p | 
					Dictionary new at: 'name' put: p name; at: 'type' put: p type; yourself]) asArray;
				at: 'zealSource' put: ([String streamContents: [:s | m compileToZeal: s indent: 0]] on: Error do: ['']);
				yourself ]) asArray ].
	
	"Interface — same as class"
	(aNode isKindOf: ZealInterface) ifTrue: [
		meta at: 'interfaces' put: ((aNode respondsTo: #interfaces) ifTrue: [aNode interfaces asArray] ifFalse: [#()]).
		meta at: 'fields' put: ((aNode respondsTo: #fields) ifTrue: [aNode fields collect: [:f |
			Dictionary new
				at: 'name' put: f name;
				at: 'type' put: ((f respondsTo: #type) ifTrue: [f type] ifFalse: [nil]);
				at: 'mutable' put: ((f respondsTo: #isMutable) ifTrue: [f isMutable] ifFalse: [false]);
				yourself ]] ifFalse: [#()]) asArray.
		meta at: 'methods' put: ((aNode respondsTo: #methods) ifTrue: [aNode methods collect: [:m |
			Dictionary new
				at: 'name' put: m name;
				at: 'type' put: m type;
				at: 'zealSource' put: ([String streamContents: [:s | m compileToZeal: s indent: 0]] on: Error do: ['']);
				yourself ]] ifFalse: [#()]) asArray ].
	
	"Function specific"
	(aNode isKindOf: ZealFunction) ifTrue: [
		meta at: 'params' put: (aNode parameters collect: [:p |
			Dictionary new at: 'name' put: p name; at: 'type' put: p type; yourself]) asArray.
		meta at: 'effects' put: ((aNode respondsTo: #effects) ifTrue: [aNode effects asArray] ifFalse: [#()]) ].
	
	"Variable specific"
	(aNode isKindOf: ZealVariable) ifTrue: [
		meta at: 'mutable' put: aNode isMutable ].
	
	^ meta
]

{ #category : 'verse' }
VerseZealBrowser >> moveNode: aNode toModule: targetModule [
	"Move a definition from its current module to targetModule"
	| currentMod |
	currentMod := self currentModuleOf: aNode.
	currentMod ifNotNil: [
		currentMod definitions: (currentMod definitions asOrderedCollection 
			reject: [:d | d == aNode]) asArray ].
	targetModule definitions: (targetModule definitions asOrderedCollection 
		add: aNode; yourself) asArray
]

{ #category : 'verse' }
VerseZealBrowser >> newZealEditor: sourceText [
	"Create a fully configured Zeal code editor using the styler system."
	| editor styler |
	styler := ZealTextStyler new project: project; browser: self.
	editor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: sourceText asRopedText;
		background: (ZealTheme backgroundColor);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 6).
	editor editor styler: styler.
	self configureZealEditor: editor.
	^ editor
]

{ #category : 'verse' }
VerseZealBrowser >> paramSignatureOf: aFunction [
	"Return a string representing the parameter types for overload comparison"
	^ ', ' join: (aFunction parameters collect: [:p | p type ifNil: ['any']])
]

{ #category : 'verse' }
VerseZealBrowser >> persistClassNode: aNode [
	"Delegate to unified persistence"
	self persistNode: aNode
]

{ #category : 'verse' }
VerseZealBrowser >> persistDefinition: aNode inNamespace: aNs [
	"Generate a Smalltalk class for a definition directly under the module class"
	| packageName projectPrefix modClassName moduleClass defClass zealSrc verseSrc modName |
	(aNode respondsTo: #name) ifFalse: [ ^ self ].
	aNode name ifNil: [ ^ self ].
	
	modName := project modules first name.
	modName ifNil: [ ^ self ].
	
	packageName := 'ZealProject-' , (project name copyReplaceAll: ' ' with: '').
	projectPrefix := 'Zeal_' , (ZealClassGenerator toPascalCase: project name).
	modClassName := projectPrefix , '_' , (ZealClassGenerator toPascalCase: modName).
	
	moduleClass := Smalltalk globals at: modClassName asSymbol ifAbsent: [nil].
	moduleClass ifNil: [ ^ self ].
	
	defClass := ZealClassGenerator generateDef: aNode parent: moduleClass package: packageName.
	defClass ifNotNil: [
		aNode generatedClass: defClass.
		zealSrc := [String streamContents: [:s | aNode compileToZeal: s indent: 0]] on: Error do: [''].
		verseSrc := [String streamContents: [:s | aNode compileToVerse: s indent: 0]] on: Error do: [''].
		defClass class compile: ('zealSource
	^ ' , zealSrc printString) classified: 'zeal'.
		defClass class compile: ('verseSource
	^ ' , verseSrc printString) classified: 'zeal' ]
]

{ #category : 'verse' }
VerseZealBrowser >> persistMetadata: aNode to: genClass [
	"Store all node metadata as class-side methods on the generated class.
	 Prefix with 'zeal' where it collides with Smalltalk built-ins."
	
	"Common"
	genClass class compile: ('zealName ^ ', aNode name printString) classified: 'metadata'.
	genClass class compile: ('zealNodeType ^ ', aNode class name printString) classified: 'metadata'.
	genClass class compile: ('zealSpecifiers ^ ', aNode specifiers asArray printString) classified: 'metadata'.
	genClass class compile: ('zealUsings ^ ', ((aNode respondsTo: #usings)
		ifTrue: [(aNode usings collect: [:u | (u respondsTo: #path) ifTrue: [u path] ifFalse: [u printString]]) asArray]
		ifFalse: [#()]) printString) classified: 'metadata'.
	
	"Function"
	(aNode isKindOf: ZealFunction) ifTrue: [
		genClass class compile: ('zealReturnType ^ ', aNode type printString) classified: 'metadata'.
		genClass class compile: ('zealParams ^ ', (aNode parameters collect: [:p | { p name. p type }]) asArray printString) classified: 'metadata'.
		genClass class compile: ('zealEffects ^ ', ((aNode respondsTo: #effects) ifTrue: [aNode effects asArray] ifFalse: [#()]) printString) classified: 'metadata' ].
	
	"Variable"
	(aNode isKindOf: ZealVariable) ifTrue: [
		genClass class compile: ('zealVarType ^ ', aNode type printString) classified: 'metadata'.
		genClass class compile: ('zealIsMutable ^ ', aNode isMutable printString) classified: 'metadata' ].
	
	"Class / Interface"
	((aNode isKindOf: ZealClass) or: [aNode isKindOf: ZealInterface]) ifTrue: [
		genClass class compile: ('zealSuperclass ^ ', ((aNode respondsTo: #superclass) ifTrue: [aNode superclass] ifFalse: [nil]) printString) classified: 'metadata'.
		genClass class compile: ('zealInterfaces ^ ', ((aNode respondsTo: #interfaces) ifTrue: [aNode interfaces asArray] ifFalse: [#()]) printString) classified: 'metadata'.
		genClass class compile: ('zealFields ^ ', (aNode fields collect: [:f |
			{ f name. 
			  (f respondsTo: #type) ifTrue: [f type] ifFalse: [nil]. 
			  (f respondsTo: #isMutable) ifTrue: [f isMutable] ifFalse: [false].
			  ([String streamContents: [:s | 
				((f respondsTo: #defaultValue) ifTrue: [f defaultValue] ifFalse: [
				 (f respondsTo: #value) ifTrue: [f value] ifFalse: [nil]])
					ifNotNil: [:v | v compileToZeal: s indent: 0]]] on: Error do: [nil]) }]) asArray printString) classified: 'metadata'.
		genClass class compile: ('zealMethods ^ ', (aNode methods collect: [:m |
			{ m name.
			  m type.
			  m specifiers asArray.
			  ((m respondsTo: #effects) ifTrue: [m effects asArray] ifFalse: [#()]).
			  (m parameters collect: [:p | { p name. p type }]) asArray.
			  ([String streamContents: [:s | m compileToZeal: s indent: 0]] on: Error do: ['']) }]) asArray printString) classified: 'metadata' ].
	
	"Enum"
	(aNode isKindOf: ZealEnum) ifTrue: [
		genClass class compile: ('zealValues ^ ', ((aNode respondsTo: #values) ifTrue: [aNode values asArray] ifFalse: [#()]) printString) classified: 'metadata' ]
]

{ #category : 'verse' }
VerseZealBrowser >> persistNode: aNode [
	"Persist a node's complete state to class variables, zealSource, verseSource, and .verse file."
	| genClass zealSrc verseSrc filePath lf |
	genClass := self generatedClassFor: aNode.
	genClass ifNil: [ ^ self ].
	lf := String lf.
	
	zealSrc := [String streamContents: [:s | aNode compileToZeal: s indent: 0]] on: Error do: [''].
	verseSrc := [String streamContents: [:s | aNode compileToVerse: s indent: 0]] on: Error do: [''].
	
	"Store source methods"
	genClass class compile: ('zealSource
	^ ', zealSrc printString) classified: 'zeal'.
	genClass class compile: ('verseSource
	^ ', verseSrc printString) classified: 'zeal'.
	
	"Store metadata as class variables"
	self persistMetadata: aNode to: genClass.
	
	"Write .verse file"
	filePath := self verseFilePathForDefinition: aNode.
	filePath ifNotNil: [
		| usingPaths |
		usingPaths := (aNode respondsTo: #usings)
			ifTrue: [aNode usings collect: [:u | (u respondsTo: #path) ifTrue: [u path] ifFalse: [u printString]]]
			ifFalse: [#()].
		[filePath asFileReference ensureDelete.
		 filePath asFileReference writeStreamDo: [:ws |
			usingPaths do: [:p | ws nextPutAll: 'using { '; nextPutAll: p; nextPutAll: ' }'; nextPutAll: lf].
			usingPaths notEmpty ifTrue: [ws nextPutAll: lf].
			ws nextPutAll: verseSrc]]
			on: Error do: [:e | ] ].
	
	ZealCompiler currentResolver ifNotNil: [:r | r invalidateAll]
]

{ #category : 'verse' }
VerseZealBrowser >> rebuildClassIn: parentElement node: aNode [
	"Rebuild the class detail inside its own parent element"
	| newDetail |
	newDetail := self buildClassDetail: aNode.
	parentElement removeChildren.
	parentElement addChild: newDetail
]

{ #category : 'verse' }
VerseZealBrowser >> rebuildTree [
	"Refresh tree items and restore expanded state"
	| expandedNames root |
	expandedNames := Set new.
	root := treeElement viewModel root.
	root childrenNodesDo: [:treeNode |
		treeNode isExpanded ifTrue: [
			| val |
			val := treeNode value.
			(val respondsTo: #name) ifTrue: [ expandedNames add: val name ] ].
		treeNode childrenNodesDo: [:child |
			child isExpanded ifTrue: [
				| val |
				val := child value.
				(val respondsTo: #name) ifTrue: [ expandedNames add: val name ] ] ] ].
	
	treeElement items: project modules lazy: [:item | self childrenOf: item].
	
	expandedNames notEmpty ifTrue: [
		treeElement expandSuchThat: [:treeNode |
			| val |
			val := treeNode value.
			(val respondsTo: #name) and: [expandedNames includes: val name] ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> refreshClassView: aNode [
	"Rebuild the class detail view wherever it currently lives.
	 If it's in detailElement (selected from tree), rebuild there.
	 If it's in a pager page (via Ctrl+B), rebuild in that page."
	((selectedNode == aNode) or: [selectedNode isNil]) ifTrue: [
		"It's the main view — safe to rebuild detailElement"
		detailElement removeChildren.
		detailElement addChild: (self buildClassDetail: aNode) ]
]

{ #category : 'verse' }
VerseZealBrowser >> removeDefinition: aNode [
	"Remove a definition from the project and delete its generated class"
	| genClass |
	"Remove from module"
	project modules do: [:mod |
		self removeNodeFromModule: mod node: aNode ].
	"Remove generated class"
	genClass := self generatedClassFor: aNode.
	genClass ifNotNil: [ genClass removeFromSystem ]
]

{ #category : 'verse' }
VerseZealBrowser >> removeNodeFromModule: aModule node: aNode [
	"Recursively remove a node from a module"
	aModule definitions: (aModule definitions asOrderedCollection reject: [:d | d == aNode]) asArray.
	aModule definitions do: [:d |
		(d isKindOf: ZealModule) ifTrue: [ self removeNodeFromModule: d node: aNode ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> reopenExpanders: nodeNames [
	"After rebuilding, find expander attributes matching nodeNames and expand them"
	| text |
	nodeNames isEmpty ifTrue: [ ^ self ].
	zealEditor ifNil: [ ^ self ].
	text := zealEditor editor text.
	text attributeRunsDo: [:start :end :attrs |
		attrs do: [:a |
			(a isKindOf: ZealExpanderAttribute) ifTrue: [
				(a instVarNamed: 'zealNode') ifNotNil: [:n |
					(nodeNames includes: n name) ifTrue: [
						a isExpanded ifFalse: [
							a isExpanded: true.
							a applyExpandedOrCollapsedAttributesOnText: text ] ] ] ] ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> searchModule: aModule forNode: aNode path: prefix found: foundBlock [
	"Recursively search for a node in modules"
	aModule definitions do: [:d |
		(d isKindOf: ZealModule) ifTrue: [
			d definitions do: [:dd |
				(dd == aNode) ifTrue: [ foundBlock value: d ] ].
			self searchModule: d forNode: aNode path: '' found: foundBlock ]
		ifFalse: [
			(d == aNode) ifTrue: [ foundBlock value: aModule ] ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> selectNode: aNode [
	| verseText zealText generatedClass headerRow |
	selectedNode := aNode.
	
	"Modules just expand in the tree"
	(aNode isKindOf: ZealModule) ifTrue: [ ^ self ].
	(aNode isKindOf: ZealTreeGroup) ifTrue: [ ^ self ].
	
	detailElement removeChildren.
	
	"Classes and interfaces get a GT-style inspector view"
	((aNode isKindOf: ZealClass) or: [aNode isKindOf: ZealInterface]) ifTrue: [
		detailElement addChild: (self buildClassDetail: aNode).
		^ self ].
	
	"Everything else: header row with name + show in folder"
	headerRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ].
	headerRow addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 18; bold);
		text: (self labelFor: aNode)).
	headerRow addChild: (self buildShowInFolderButton: aNode).
	detailElement addChild: headerRow.
	
	generatedClass := self generatedClassFor: aNode.
	detailElement addChild: (self buildModuleDropdown: aNode inContainer: detailElement).
	detailElement addChild: (self buildUsingEditor: aNode).
	
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 12);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets top: 12 left: 0 bottom: 4 right: 0)).
	
	zealText := self zealSourceFor: aNode generatedClass: generatedClass.
	
	zealEditor := self newZealEditor: zealText.
	zealEditor background: (ZealTheme backgroundColor darker).
	zealEditor margin: (BlInsets bottom: 8).
	zealEditor padding: (BlInsets all: 8).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: BlKeyCombination primaryS;
		action: [ self compileAndSave: zealEditor forNode: aNode ]).
	detailElement addChild: zealEditor.
	
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Verse:';
		margin: (BlInsets top: 4 left: 0 bottom: 4 right: 0)).
	
	verseText := generatedClass
		ifNotNil: [ generatedClass verseSource ]
		ifNil: [ [ aNode compileToVerse ] on: Error do: [:e | 'Error: ' , e messageText ] ].
	detailElement addChild: (BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: (verseText asRopedText foreground: ZealTheme foregroundColor);
		background: (ZealTheme backgroundColor darker);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		beReadOnlyWithSelection;
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8);
		id: #verseOutput)
]

{ #category : 'verse' }
VerseZealBrowser >> setupCompletion: anEditor [
	"Install themed code completion"
	| strategy controller |
	strategy := ZealCompletionStrategy new project: project.
	controller := GtCompletionController on: anEditor strategy: strategy.
	controller install.
	completionController := controller.
	
	"Theme the overlay popup (list is created lazily, gets overlay bg)"
	(controller instVarNamed: 'overlay') ifNotNil: [:overlay |
		overlay background: ZealTheme backgroundColor.
		overlay border: (BlBorder paint: (Color fromHexString: '9580FF') width: 1) ]
]

{ #category : 'verse' }
VerseZealBrowser >> setupRehighlight: anEditor [
	"Debounced rehighlight on text changes"
	anEditor editor
		when: BrTextEditorInsertedEvent do: [:e | self scheduleRehighlight: anEditor ];
		when: BrTextEditorDeletedEvent do: [:e | self scheduleRehighlight: anEditor ]
]

{ #category : 'verse' }
VerseZealBrowser >> showClassDetail: cls [
	cls superclass ifNotNil: [:p |
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme operatorColor; fontSize: 12);
			text: 'Superclass: ' , p) ].
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Fields: ' , cls fields size printString , '  Methods: ' , cls methods size printString)
]

{ #category : 'verse' }
VerseZealBrowser >> showEnumDetail: en [
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Values: ' , (en values joinUsing: ', '))
]

{ #category : 'verse' }
VerseZealBrowser >> showFunctionDetail: func [
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Parameters:').
	func parameters do: [:p |
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor);
			text: '  ' , p name , (p type ifNotNil: [':' , p type] ifNil: ['']);
			margin: (BlInsets left: 12)) ]
]

{ #category : 'verse' }
VerseZealBrowser >> showModuleDetail: mod [
	mod usings notEmpty ifTrue: [
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
			text: 'Usings:';
			margin: (BlInsets top: 8 bottom: 4)).
		mod usings do: [:u |
			detailElement addChild: (BrLabel new
				aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme keywordColor);
				text: '  ' , u path;
				margin: (BlInsets left: 12)) ] ].
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Definitions: ' , mod definitions size printString , ' (' , (mod definitions select: [:d | d isKindOf: ZealCompileError]) size printString , ' errors)';
		margin: (BlInsets top: 8))
]

{ #category : 'verse' }
VerseZealBrowser >> showWelcome [
	detailElement removeChildren.
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 16);
		text: 'Select a definition to view details')
]

{ #category : 'verse' }
VerseZealBrowser >> splitTopLevelForms: aString [
	"Split Zeal source into top-level forms by matching parens at depth 0"
	| forms current depth inString |
	forms := OrderedCollection new.
	current := WriteStream on: String new.
	depth := 0. inString := false.
	1 to: aString size do: [:i |
		| ch |
		ch := aString at: i.
		ch = $" ifTrue: [ inString := inString not ].
		inString ifFalse: [
			ch = $( ifTrue: [ depth := depth + 1 ].
			ch = $) ifTrue: [ depth := depth - 1 ] ].
		current nextPut: ch.
		(depth = 0 and: [inString not and: [current contents trimBoth notEmpty and: [
			current contents trimBoth last = $)]]]) ifTrue: [
			forms add: current contents trimBoth.
			current := WriteStream on: String new ] ].
	current contents trimBoth notEmpty ifTrue: [ forms add: current contents trimBoth ].
	^ forms
]

{ #category : 'verse' }
VerseZealBrowser >> storeIndividualZeal: fullZealSource forDefinitions: compiledNodes [
	"Parse the full Zeal source into individual definitions and store each in its generated class"
	| zealParts |
	zealParts := self splitTopLevelForms: fullZealSource.
	
	compiledNodes doWithIndex: [:node :idx |
		| genClass defnZeal defnVerse |
		genClass := self generatedClassFor: node.
		genClass ifNotNil: [
			defnZeal := (idx <= zealParts size) ifTrue: [zealParts at: idx] ifFalse: [''].
			defnVerse := [String streamContents: [:s | node compileToVerse: s indent: 0]] on: Error do: [''].
			genClass class compile: ('zealSource
	^ ' , defnZeal printString) classified: 'zeal'.
			genClass class compile: ('verseSource
	^ ' , defnVerse printString) classified: 'zeal' ] ]
]

{ #category : 'verse' }
VerseZealBrowser >> surgicallyReplace: oldText with: newText in: mainEditor [
	"Replace oldText with newText in the main editor, preserving other attributes.
	 If oldText not found (nested expander case), skip silently."
	| mainStr startIdx endIdx highlighted |
	(mainEditor isNil or: [oldText isNil or: [newText isNil]]) ifTrue: [ ^ self ].
	oldText = newText ifTrue: [ ^ self ].
	mainStr := mainEditor editor text asString.
	startIdx := mainStr findString: oldText startingAt: 1.
	startIdx = 0 ifTrue: [ ^ self ]. "Not in main editor — nested expander, skip"
	endIdx := startIdx + oldText size - 1.
	
	suppressRehighlight := true.
	mainEditor editor deleter from: startIdx - 1 to: endIdx; delete.
	mainEditor editor inserter 
		at: startIdx - 1;
		string: newText;
		withoutCursorUpdate;
		withoutSelectionUpdate;
		insert.
	
	"Re-highlight the inserted text"
	highlighted := ZealTheme highlight: newText.
	1 to: newText size do: [:i |
		(highlighted attributesAt: i) do: [:a |
			(mainEditor editor text from: startIdx - 1 + i to: startIdx - 1 + i) attribute: a ] ].
	
	suppressRehighlight := false
]

{ #category : 'verse' }
VerseZealBrowser >> surgicallyUpdate: aNode in: mainEditor [
	"Find the old definition text in the main editor and replace it with the new stored Zeal."
	| mainText oldZeal newZeal startIdx endIdx highlighted |
	mainEditor ifNil: [ ^ self ].
	mainText := mainEditor editor text asString.
	
	oldZeal := [String streamContents: [:s | aNode compileToZeal: s indent: 0]] on: Error do: [ ^ self ].
	newZeal := [(self generatedClassFor: aNode) zealSource] on: Error do: [ ^ self ].
	(newZeal isNil or: [oldZeal isNil]) ifTrue: [ ^ self ].
	oldZeal = newZeal ifTrue: [ ^ self ].
	
	startIdx := mainText findString: oldZeal startingAt: 1.
	startIdx = 0 ifTrue: [ ^ self ].
	endIdx := startIdx + oldZeal size - 1.
	
	mainEditor editor deleter from: startIdx - 1 to: endIdx; delete.
	mainEditor editor inserter 
		at: startIdx - 1;
		string: newZeal;
		withoutCursorUpdate;
		withoutSelectionUpdate;
		insert
]

{ #category : 'verse' }
VerseZealBrowser >> syncNode: aNode withCompiled: compiledNode [
	"Update the project tree node with properties from the freshly compiled node"
	aNode name: compiledNode name.
	(aNode respondsTo: #type:) ifTrue: [ aNode type: compiledNode type ].
	(aNode respondsTo: #specifiers:) ifTrue: [ aNode specifiers: compiledNode specifiers ].
	(aNode respondsTo: #fields:) ifTrue: [
		(compiledNode respondsTo: #fields) ifTrue: [ aNode fields: compiledNode fields ] ].
	(aNode respondsTo: #methods:) ifTrue: [
		(compiledNode respondsTo: #methods) ifTrue: [ aNode methods: compiledNode methods ] ].
	(aNode respondsTo: #parameters:) ifTrue: [
		(compiledNode respondsTo: #parameters) ifTrue: [ aNode parameters: compiledNode parameters ] ].
	(aNode respondsTo: #body:) ifTrue: [
		(compiledNode respondsTo: #body) ifTrue: [ aNode body: compiledNode body ] ].
	(aNode respondsTo: #superclass:) ifTrue: [
		(compiledNode respondsTo: #superclass) ifTrue: [ aNode superclass: compiledNode superclass ] ].
	(aNode respondsTo: #interfaces:) ifTrue: [
		(compiledNode respondsTo: #interfaces) ifTrue: [ aNode interfaces: compiledNode interfaces ] ]
]

{ #category : 'hooks' }
VerseZealBrowser >> themeClass [
	^ VerseZealTheme
]

{ #category : 'verse' }
VerseZealBrowser >> toKebab: aString [
	"Convert PascalCase/snake_case to kebab-case"
	| result |
	result := WriteStream on: String new.
	aString do: [:ch |
		ch = $_ ifTrue: [ result nextPut: $- ]
		ifFalse: [ (ch isUppercase and: [result position > 0]) 
			ifTrue: [ result nextPut: $-; nextPut: ch asLowercase ]
			ifFalse: [ result nextPut: ch asLowercase ] ] ].
	^ result contents
]

{ #category : 'verse' }
VerseZealBrowser >> toggleChat [
	"Toggle the chat panel on the right side"
	| content chatPanel |
	content := self children first children last. "The horizontal content element"
	chatPanel := content childWithId: #chatPanel ifFound: [:p | p] ifNone: [nil].
	
	chatPanel ifNotNil: [
		"Remove chat"
		content removeChild: chatPanel.
		^ self ].
	
	"Add chat"
	chatPanel := self buildChatPanel.
	content addChild: chatPanel
]

{ #category : 'verse' }
VerseZealBrowser >> verseFilePathFor: aNamespace [
	"Find the .verse file path for a namespace (ZealModule kind: #file)."
	| dir files |
	((aNamespace isKindOf: ZealModule) and: [aNamespace kind = #file]) ifFalse: [ ^ nil ].
	project ifNil: [ ^ nil ].
	dir := project path asFileReference.
	files := dir allFiles select: [:f | 
		f extension = 'verse' and: [f basenameWithoutExtension = aNamespace name] ].
	files ifEmpty: [ ^ nil ] ifNotEmpty: [ ^ files first fullName ]
]

{ #category : 'verse' }
VerseZealBrowser >> verseFilePathForDefinition: aNode [
	"Build .verse file path from the generated class hierarchy. 
	 Uses the actual Fortnite Projects Content folder."
	| genClass segments parts contentDir |
	genClass := self generatedClassFor: aNode.
	genClass ifNil: [ ^ nil ].
	
	"Find Content folder — try UEFN project path first, then project path"
	contentDir := ('C:\Users\Jacob Goodson\Documents\Fortnite Projects\', project name, '\Content') asFileReference.
	contentDir exists ifFalse: [
		contentDir := project path asFileReference / 'Content'.
		contentDir exists ifFalse: [
			contentDir ensureCreateDirectory ] ].
	
	"Class name: Zeal_Project_Module_Namespace_Definition"
	segments := genClass name substrings: '_'.
	segments size < 3 ifTrue: [ ^ nil ].
	parts := (segments copyFrom: 3 to: segments size) collect: [:p |
		| result |
		result := WriteStream on: String new.
		p do: [:ch |
			(ch isUppercase and: [result position > 0])
				ifTrue: [ result nextPut: $-; nextPut: ch asLowercase ]
				ifFalse: [ result nextPut: ch asLowercase ] ].
		result contents ].
	
	^ contentDir / ('zeal-' , ('-' join: parts) , '.verse')
]

{ #category : 'verse' }
VerseZealBrowser >> wrapInDarkPage: anElement [
	"Wrap an element in a scrollable dark container for pager pages"
	| inner |
	inner := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		background: ZealTheme backgroundColor;
		addChild: anElement.
	^ inner asScrollableElement
		background: ZealTheme backgroundColor;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ]
]

{ #category : 'verse' }
VerseZealBrowser >> writeNamespaceToFile: aNamespace path: filePath [
	"Write all definitions in a namespace to the .verse file.
	 Uses stored verse from generated classes when available."
	| stream |
	stream := String new writeStream.
	aNamespace usings do: [:u |
		stream nextPutAll: 'using { '; nextPutAll: u path; nextPutAll: ' }'.
		stream cr ].
	aNamespace usings notEmpty ifTrue: [ stream cr ].
	aNamespace definitions do: [:d |
		| genClass storedVerse |
		genClass := self generatedClassFor: d.
		storedVerse := genClass ifNotNil: [ [genClass verseSource] on: Error do: [nil] ].
		storedVerse 
			ifNotNil: [ stream nextPutAll: storedVerse ]
			ifNil: [ d compileToVerse: stream indent: 0 ].
		stream cr; cr ].
	filePath asFileReference writeStreamDo: [:ws | ws nextPutAll: stream contents ]
]

{ #category : 'verse' }
VerseZealBrowser >> zealSourceFor: aNode generatedClass: genClass [
	"Get Zeal source. For namespaces, assemble from children. 
	 For definitions, use stored Zeal from generated class if available."
	
	"Namespaces: assemble from child definitions"
	(aNode isKindOf: ZealModule) ifTrue: [
		^ self zealSourceForNamespace: aNode ].
	
	"Use stored Zeal from generated class if it exists"
	genClass ifNotNil: [
		| storedZeal |
		storedZeal := [genClass zealSource] on: Error do: [nil].
		storedZeal ifNotNil: [ ^ storedZeal ] ].
	
	"No generated class — decompile from node"
	^ [aNode compileToZeal] on: Error do: [:e | 'Error: ' , e messageText]
]

{ #category : 'verse' }
VerseZealBrowser >> zealSourceForNamespace: aModule [
	"Build Zeal source for a namespace by checking each definition's generated class first.
	 If a definition has stored Zeal (and its Verse matches), use that. Otherwise decompile."
	| parts |
	parts := OrderedCollection new.
	aModule definitions do: [:defn |
		| genClass zealSrc |
		genClass := self generatedClassFor: defn.
		zealSrc := self zealSourceFor: defn generatedClass: genClass.
		parts add: zealSrc ].
	^ (String cr , String cr) join: parts
]
