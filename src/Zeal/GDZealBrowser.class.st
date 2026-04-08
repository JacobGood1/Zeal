Class {
	#name : 'GDZealBrowser',
	#superclass : 'ZealBrowser',
	#instVars : [
		'typeSystem',
		'lspModel'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'opening' }
GDZealBrowser class >> open [
	"Open on the default project"
	^ self openOn: 'C:/projects/bible-app-warhill'
]

{ #category : 'opening' }
GDZealBrowser class >> openOn: aGodotPath [
	"Open a GDZeal browser on a Godot project, wrapped in a GtPager so that
	 compile success/error results can be spawned as pager pages."
	| proj browser pager space |
	proj := GDZealProject new.
	proj path: aGodotPath.
	proj name: aGodotPath asFileReference basename.
	proj loadFromDirectory.
	browser := self new.
	browser project: proj.
	browser typeSystem: (GDZealTypeSystem forProject: proj).
	pager := GtPager createWrappedOn: browser.
	pager background: GDZealTheme backgroundColor.
	pager allChildrenBreadthFirstDo: [ :c |
		(c background isKindOf: BlPaintBackground) ifTrue: [
			c background paint color = Color white ifTrue: [
				c background: GDZealTheme backgroundColor ] ] ].
	space := BlSpace new.
	space title: 'GDZeal // ' , proj name.
	space extent: 1100 @ 700.
	space root background: GDZealTheme backgroundColor.
	space root addChild: pager.
	space show.
	^ browser
]

{ #category : 'editing' }
GDZealBrowser >> applyFormat: zealEditor [
	"Apply full format — normalize indentation + parinfer"
	| currentText result cursorPos |
	currentText := zealEditor editor text asString.
	currentText isEmpty ifTrue: [ ^ self ].
	result := ZealParinfer format: currentText.
	result = currentText ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	zealEditor text: ((ZealTheme highlight: result)).
	zealEditor editor navigator
		moveTo: (cursorPos min: result size);
		apply
]

{ #category : 'editing' }
GDZealBrowser >> applyParinfer: zealEditor [
	"Apply parinfer indent mode — pure Smalltalk, instant"

	| currentText result cursorPos |
	currentText := zealEditor editor text asString.
	currentText isEmpty ifTrue: [ ^ self ].
	result := ZealParinfer indentMode: currentText.
	result = currentText ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	zealEditor text: ((ZealTheme highlight: result)).
	zealEditor editor navigator
		moveTo: (cursorPos min: result size);
		apply
]

{ #category : 'editing' }
GDZealBrowser >> barfForward: zealEditor [
	"Barf: push last expression out of the current form"
	| text cursorPos result |
	text := zealEditor editor text asString.
	text isEmpty ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	result := ZealParinfer barfForward: text at: cursorPos.
	result = text ifTrue: [ ^ self ].
	zealEditor text: ((ZealTheme highlight: result)).
	zealEditor editor navigator moveTo: (cursorPos min: result size); apply
]

{ #category : 'building - tabs' }
GDZealBrowser >> buildCategoryContent: aCategory [
	"Vertically-scrolling column of definition expander cards for the given category."
	| column scroll defs |
	defs := self definitionsForCategory: aCategory.
	column := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8).
	defs do: [ :d | column addChild: (self buildDefinitionExpander: d) ].
	defs isEmpty ifTrue: [
		column addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new 
				foreground: GDZealTheme commentColor; 
				fontSize: 12);
			text: 'No ' , aCategory , ' yet.';
			margin: (BlInsets all: 12)) ].
	scroll := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		clipChildren: true;
		background: GDZealTheme backgroundColor.
	scroll addChild: (column asScrollableElement
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		yourself).
	^ scroll
]

{ #category : 'building - tabs' }
GDZealBrowser >> buildCategoryTab: aCategory [
	"One tab: label = category name (capitalized), content = scrollable column of
	 inline-expandable definition cards. The per-tab aptitude is required for the
	 label to actually render in the header bar."
	| tab |
	tab := BrTab new.
	tab aptitude: BrGlamorousTabAptitude new.
	tab label: aCategory capitalized.
	tab stencil: [ self buildCategoryContent: aCategory ].
	^ tab
]

{ #category : 'building - tabs' }
GDZealBrowser >> buildCategoryTabs [
	"BrTabGroup with one tab per category present in the project."
	| group tabs |
	group := BrTabGroup new.
	group aptitude: BrGlamorousTabGroupAptitude new.
	group constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].
	tabs := self categoriesPresent collect: [ :cat | self buildCategoryTab: cat ].
	group addTabs: tabs.
	^ group
]

{ #category : 'building' }
GDZealBrowser >> buildCommandBar [
	| input |
	input := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		styler: GDZealTextStyler new;
		text: '';
		background: GDZealTheme backgroundColor;
		padding: (BlInsets all: 6);
		constraintsDo: [ :c | c horizontal matchParent. c vertical exact: 60 ].
	input addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self createFromInput: input ]).
	^ input
]

{ #category : 'building' }
GDZealBrowser >> buildCompileAllButton [
	^ BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Compile All';
		margin: (BlInsets right: 8);
		background: (Color fromHexString: '2D5A2D');
		action: [ | result |
			result := project compileAll.
			self inform: result key printString , ' compiled, ' , result value printString , ' errors' ]
]

{ #category : 'building' }
GDZealBrowser >> buildDefinitionBody: aDef [
	"Expanded card body: just the syntax-colored source editor.
	 Compile feedback is shown by spawning a pager page (success or error)
	 via compileNode:editor: — no inline diagnostics strip."
	| body editor |
	body := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets top: 4 left: 12 bottom: 8 right: 8).
	editor := self buildZealEditor: (aDef rawSource ifNil: [ '' ]).
	editor userData at: #defName put: aDef name.
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self compileNode: aDef editor: editor ]).
	body addChild: editor.
	^ body
]

{ #category : 'building - cards' }
GDZealBrowser >> buildDefinitionExpander: aDef [
	"Inline-expandable card for a single definition. Tagged with #defName in userData
	 so captureUiState can find it after a rebuild."
	| expander |
	expander := BrExpander new.
	expander aptitude: BrGlamorousExpanderAptitude new.
	expander 
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 2 bottom: 2);
		header: [ self buildDefinitionHeader: aDef ];
		content: [ self buildDefinitionBody: aDef ].
	expander userData at: #defName put: aDef name.
	^ expander
]

{ #category : 'building - cards' }
GDZealBrowser >> buildDefinitionHeader: aDef [
	"Compact header row: type tag (faded) + bold name."
	| row typeText |
	typeText := (aDef isKindOf: ZealClass)
		ifTrue: [ aDef superclass ifNil: [ '' ] ifNotNil: [ :s | s ] ]
		ifFalse: [ aDef class name allButFirst: 4 ].
	row := BlElement new
		layout: (BlLinearLayout horizontal alignCenterLeft);
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets top: 2 right: 8 bottom: 2 left: 0).
	typeText isEmpty ifFalse: [
		row addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new 
				foreground: GDZealTheme operatorColor;
				fontSize: 11);
			text: typeText;
			margin: (BlInsets right: 8)) ].
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new 
			foreground: GDZealTheme keywordColor;
			fontSize: 13;
			bold);
		text: aDef name).
	^ row
]

{ #category : 'building' }
GDZealBrowser >> buildDivider [
	^ BlElement new
		constraintsDo: [ :c | c horizontal matchParent. c vertical exact: 1 ];
		background: (Color fromHexString: '444444')
]

{ #category : 'building' }
GDZealBrowser >> buildErrorPage: anError [
	"Pager page shown after a compile failure or linter error. Lists the diagnostics
	 and shows the GDZeal source with the offending text underlined in red."
	| page header diagsBox sourceEditor text src |
	page := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		background: self themeClass backgroundColor;
		padding: (BlInsets top: 12 left: 16 bottom: 12 right: 16).
	header := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new
			fontSize: 16;
			foreground: Color red);
		text: 'Compile error'.
	diagsBox := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets top: 8 bottom: 8).
	anError linterDiags do: [ :d |
		diagsBox addChild: (self buildErrorPageRow: d) ].
	anError compilerError ifNotNil: [ :e |
		diagsBox addChild: (self buildErrorPageMessageRow: 'compile: ' , e messageText) ].
	"Editor with offending ranges underlined in red"
	src := anError source ifNil: [ '' ].
	text := self themeClass highlight: src.
	anError linterDiags do: [ :d |
		| sp ep |
		sp := d at: #startPos ifAbsent: [ nil ].
		ep := d at: #stopPos ifAbsent: [ nil ].
		(sp notNil and: [ ep notNil and: [ sp <= ep and: [ sp >= 1 and: [ ep <= text size ] ] ] ]) ifTrue: [
			(text from: sp to: ep)
				foreground: Color red;
				attribute: (BlTextDecorationAttribute new
					underline;
					color: Color red;
					thickness: 2) ] ].
	sourceEditor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: text;
		background: self themeClass backgroundColor;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		padding: (BlInsets all: 8).
	sourceEditor editor beReadOnlyWithSelection.
	page addChild: header.
	page addChild: diagsBox.
	page addChild: sourceEditor.
	^ page
]

{ #category : 'building' }
GDZealBrowser >> buildErrorPageMessageRow: aMessage [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new
			fontSize: 12;
			foreground: Color red);
		text: aMessage;
		padding: (BlInsets top: 2 bottom: 2)
]

{ #category : 'building' }
GDZealBrowser >> buildErrorPageRow: aDiag [
	| label msg |
	msg := aDiag at: #message ifAbsent: [ '?' ].
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new
			fontSize: 12;
			foreground: Color red);
		text: msg;
		padding: (BlInsets top: 2 bottom: 2).
	^ label
]

{ #category : 'building' }
GDZealBrowser >> buildFieldItem: aField [
	| label |
	label := aField name.
	aField type ifNotNil: [ :t | label := label , ' : ' , t ].
	aField defaultValue ifNotNil: [ :v |
		(v isKindOf: ZealLiteral) ifTrue: [ label := label , ' = ' , v value ] ].
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme colonChainColor; fontSize: 12);
		text: label;
		margin: (BlInsets left: 12)
]

{ #category : 'building' }
GDZealBrowser >> buildNewFileButton [
	^ BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: '+ New';
		margin: (BlInsets right: 8);
		action: [ self promptNewFile ]
]

{ #category : 'building' }
GDZealBrowser >> buildResultCodeTabLabel: aLabel text: aRopedText [
	"Build a single tab inside the compile-result page that just shows code in a
	 read-only editor. The aptitude is created without an explicit foreground so
	 per-character colors from the highlighter survive."
	| tab editor |
	editor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: aRopedText;
		background: self themeClass backgroundColor;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		padding: (BlInsets all: 8).
	editor editor beReadOnlyWithSelection.
	tab := BrTab new
		aptitude: BrGlamorousTabAptitude new;
		label: aLabel;
		stencil: [ editor ].
	^ tab
]

{ #category : 'building' }
GDZealBrowser >> buildResultPage: aResult [
	"Pager page shown after a successful compile. Header line + tab group with two
	 tabs: GDZeal source (syntax-highlighted) and the generated GDScript."
	| page header tabs zealText |
	page := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		background: self themeClass backgroundColor;
		padding: (BlInsets top: 12 left: 16 bottom: 12 right: 16).
	header := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new
			fontSize: 16;
			foreground: self themeClass foregroundColor);
		text: 'Compiled: ' , aResult definitionName , ' -> ' , aResult gdPath asString.
	tabs := BrTabGroup new
		aptitude: BrGlamorousTabGroupAptitude new;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].
	zealText := self themeClass highlight: (aResult source ifNil: [ '' ]).
	tabs addTab: (self buildResultCodeTabLabel: 'GDZeal source' text: zealText).
	tabs addTab: (self buildResultCodeTabLabel: 'GDScript' text: (aResult generated ifNil: [ '' ]) asRopedText).
	page addChild: header.
	page addChild: tabs.
	^ page
]

{ #category : 'building' }
GDZealBrowser >> buildSectionLabel: aString [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme specialFormColor; fontSize: 11);
		text: aString;
		margin: (BlInsets top: 8 bottom: 4)
]

{ #category : 'building' }
GDZealBrowser >> buildUI [
	"Pharo class-browser style:
	  topBar (project name + Compile All)
	  tabGroup (one tab per category, each containing inline-expandable definition cards)"
	| topBar |
	self removeChildren.
	
	topBar := BlElement new
		layout: (BlLinearLayout horizontal alignCenterLeft);
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		background: GDZealTheme backgroundColor darker;
		padding: (BlInsets all: 8).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new 
			foreground: GDZealTheme classRefColor; 
			fontSize: 14; 
			bold);
		text: 'GDZeal // ' , project name;
		margin: (BlInsets right: 12)).
	topBar addChild: self buildCompileAllButton.
	
	detailElement := self buildCategoryTabs.
	
	self addChild: topBar.
	self addChild: detailElement
]

{ #category : 'building' }
GDZealBrowser >> buildWelcome [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme commentColor; fontSize: 13);
		text: 'Select a definition or create a new one'
]

{ #category : 'ui' }
GDZealBrowser >> buildZealEditor: sourceString [
	"Create a fully configured GDZeal code editor with all Zeal-like features"
	| editor styler text |
	styler := GDZealTextStyler new.
	styler browser: self.
	"Pre-apply syntax highlighting so text is colored immediately"
	text := self themeClass highlight: sourceString.
	editor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: text;
		background: self themeClass backgroundColor;
		padding: (BlInsets all: 8);
		margin: (BlInsets top: 4);
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].
	editor editor styler: styler.
	self configureZealEditor: editor.
	^ editor
]

{ #category : 'refreshing' }
GDZealBrowser >> captureUiState [
	"Snapshot the on-screen state so we can restore it after a rebuildTree.
	 Returns a Dictionary with: selectedTabIndex, expandedNames (Set of String def names),
	 focusedName (String or nil), cursorPosition (Integer or nil)."
	| state expandedNames tabGroup |
	state := Dictionary new.
	state at: #expandedNames put: Set new.
	state at: #focusedName put: nil.
	state at: #cursorPosition put: nil.
	state at: #selectedTabIndex put: nil.
	"Active tab — find the BrTabGroup and read its viewModel selected index"
	tabGroup := nil.
	self allChildrenBreadthFirstDo: [ :c |
		(tabGroup isNil and: [ c isKindOf: BrTabGroup ]) ifTrue: [ tabGroup := c ] ].
	tabGroup ifNotNil: [
		tabGroup viewModel selectedTab ifNotNil: [ :t |
			state at: #selectedTabIndex put: (tabGroup tabs indexOf: t) ] ].
	"Walk all expanders, record those that are expanded, by definition name"
	expandedNames := state at: #expandedNames.
	self allChildrenBreadthFirstDo: [ :c |
		((c isKindOf: BrExpander) and: [ c isExpanded ]) ifTrue: [
			(c userData at: #defName ifAbsent: [ nil ]) 
				ifNotNil: [ :n | expandedNames add: n ] ] ].
	"Focused editor + cursor position"
	self allChildrenBreadthFirstDo: [ :c |
		((c isKindOf: BrEditor) and: [ c hasFocus ]) ifTrue: [
			| owner |
			owner := c userData at: #defName ifAbsent: [ nil ].
			owner ifNotNil: [
				state at: #focusedName put: owner.
				state at: #cursorPosition put: c editor cursors first position ] ] ].
	^ state
]

{ #category : 'building - tabs' }
GDZealBrowser >> categoriesPresent [
	"Distinct categories appearing in the project's definitions, in display order."
	| order present |
	project isNil ifTrue: [ ^ #() ].
	order := #('components' 'defcosystems' 'systems' 'entities' 'observers' 'misc').
	present := ((project allDefinitions select: [ :d | d isKindOf: ZealDefinition ])
		collect: [ :d | self categoryFor: d ]) asSet.
	^ (order select: [ :c | present includes: c ]) asArray
]

{ #category : 'categories' }
GDZealBrowser >> categoryFor: aDefinition [
	"Bucket a ZealDefinition into one of the GDZeal category groups based on its annotations.
	 Returns a String — the category column populates from these and the definition column
	 filters by them."
	| anns |
	anns := aDefinition annotations ifNil: [ ^ 'misc' ].
	"Defcosystem = component + fsm — must check before plain component"
	((anns includes: 'gecs_component') and: [ anns includes: 'fsm' ])
		ifTrue: [ ^ 'defcosystems' ].
	(anns includes: 'gecs_component') ifTrue: [ ^ 'components' ].
	(anns includes: 'gecs_system') ifTrue: [ ^ 'systems' ].
	(anns includes: 'gecs_entity') ifTrue: [ ^ 'entities' ].
	(anns includes: 'gecs_observer') ifTrue: [ ^ 'observers' ].
	^ 'misc'
]

{ #category : 'actions' }
GDZealBrowser >> compileAll [
	"Compile all .zeal files in the project"
	| zealDir count errors |
	zealDir := (godotPath , '/gdzeal') asFileReference.
	zealDir exists ifFalse: [ ^ self ].
	count := 0. errors := 0.
	registry := GDZealComponentRegistry new.
	"First pass: register all components"
	(zealDir allFiles select: [ :f | f extension = 'zeal' ]) do: [ :f |
		| source |
		source := f contents.
		(source includesSubstring: '(defcomp ') ifTrue: [
			| name |
			name := self extractDefName: source.
			name ifNotNil: [ registry register: name ] ] ].
	"Second pass: compile all"
	(zealDir allFiles select: [ :f | f extension = 'zeal' ]) do: [ :f |
		| source folder name gdScript path |
		source := f contents.
		folder := f parent basenameWithoutExtension.
		name := f basenameWithoutExtension.
		[ gdScript := GDZealCodeGenerator compile: source withRegistry: registry.
		  path := self gdScriptPathFor: name inFolder: folder.
		  (godotPath , '/' , path) asFileReference
			ensureDelete;
			writeStreamDo: [ :s | s nextPutAll: gdScript ].
		  count := count + 1 ]
		on: Error do: [ :e | errors := errors + 1 ] ].
	self inform: count printString , ' compiled, ' , errors printString , ' errors'
]

{ #category : 'actions' }
GDZealBrowser >> compileCurrentFile: editor statusLabel: statusLabel [
	"Compile the current editor content to GDScript and save"
	| source gdScript path folder name |
	source := editor editor text asString.
	folder := selectedFile value asFileReference parent basenameWithoutExtension.
	name := selectedFile key.
	
	"Save .zeal source"
	selectedFile value asFileReference
		ensureDelete;
		writeStreamDo: [ :s | s nextPutAll: source ].
	
	"Compile"
	[ gdScript := GDZealCodeGenerator compile: source withRegistry: registry.
	  "Determine output path"
	  path := self gdScriptPathFor: name inFolder: folder.
	  "Write .gd file"
	  (godotPath , '/' , path) asFileReference
		ensureDelete;
		writeStreamDo: [ :s | s nextPutAll: gdScript ].
	  statusLabel text: ('Compiled -> ' , path) asRopedText foreground: GDZealTheme keywordColor ]
	on: Error do: [ :e |
		statusLabel text: ('Error: ' , e messageText) asRopedText foreground: GDZealTheme specialFormColor ]
]

{ #category : 'actions' }
GDZealBrowser >> compileNode: aNode editor: editor [
	"Compile the editor content. On success, save and spawn a pager page showing
	 the GDZeal source + generated GDScript. On error (linter or compiler),
	 spawn an error pager page that highlights the offending text.
	 Structural changes (new/renamed defs) trigger a UI rebuild with state restored."
	| source linterDiags newNode gdPath gdSource sigBefore sigAfter result |
	source := editor editor text asString.
	sigBefore := self definitionSignature.
	"1. Linter pass — catches field typos before codegen."
	linterDiags := self lintSource: source.
	linterDiags isNotEmpty ifTrue: [
		self flashError: editor.
		self spawnErrorPageOn: editor source: source linterDiags: linterDiags compilerError: nil.
		^ self ].
	"2. Compile pass."
	[ newNode := GDZealCompiler compile: source.
	  newNode rawSource: source.
	  project addDefinition: newNode fromSource: source.
	  project saveDefinition: newNode.
	  gdPath := project compileDefinition: newNode.
	  project persistToImage.
	  typeSystem ifNotNil: [ typeSystem rescan ] ]
		on: Error do: [ :e |
			self flashError: editor.
			self spawnErrorPageOn: editor source: source linterDiags: #() compilerError: e.
			^ self ].
	"3. Read back generated GDScript and spawn success page."
	gdSource := [ gdPath asFileReference contents ] on: Error do: [ :e | '"" failed to read: ' , e messageText ].
	result := GDZealCompileResult new
		definitionName: newNode name;
		source: source;
		generated: gdSource;
		gdPath: gdPath;
		yourself.
	self flashSuccess: editor.
	self spawnResultPageOn: editor result: result.
	"4. Rebuild only if signature changed."
	sigAfter := self definitionSignature.
	sigBefore = sigAfter ifFalse: [
		| state |
		state := self captureUiState.
		self rebuildTree.
		self restoreUiState: state ]
]

{ #category : 'editor setup' }
GDZealBrowser >> configureZealEditor: anEditor [
	"Set up all Zeal-like features on the editor"
	self setupParinfer: anEditor.
	self setupKeyChords: anEditor.
	self setupArrowKeys: anEditor.
	self setupFormHighlight: anEditor.
	anEditor addShortcut: (BlShortcutWithAction new
		combination: (BlKeyCombination builder control shift arrowUp build);
		action: [ self swapForm: anEditor up: true ]).
	anEditor addShortcut: (BlShortcutWithAction new
		combination: (BlKeyCombination builder control shift arrowDown build);
		action: [ self swapForm: anEditor up: false ])
]

{ #category : 'commands' }
GDZealBrowser >> createFromInput: editor [
	"Create a new definition from the command bar."
	| source node |
	source := editor editor text asString.
	source isEmpty ifTrue: [ ^ self ].
	[ node := GDZealCompiler compile: source.
	  node rawSource: source.
	  project addDefinition: node fromSource: source.
	  project saveDefinition: node.
	  project compileDefinition: node.
	  project persistToImage.
	  editor editor text: '' asRopedText.
	  self rebuildTree ]
	on: Error do: [ :e | self inform: 'Error: ' , e messageText ]
]

{ #category : 'editing' }
GDZealBrowser >> cutOrRemoveLine: zealEditor [
	"If text is selected, cut it. Otherwise remove the entire line."
	| selStart selEnd hasSelection text |
	hasSelection := false.
	selStart := 0. selEnd := 0.
	zealEditor editor selection do: [:sel |
		selStart := sel from.
		selEnd := sel to.
		(selEnd > selStart) ifTrue: [ hasSelection := true ] ].
	
	hasSelection ifTrue: [
		"Cut selected text to clipboard, then delete it"
		text := zealEditor editor text asString.
		Clipboard clipboardText: (text copyFrom: selStart + 1 to: selEnd).
		zealEditor editor deleter
			from: selStart to: selEnd;
			delete ]
	ifFalse: [
		self removeLine: zealEditor ]
]

{ #category : 'accessing' }
GDZealBrowser >> definitionSignature [
	"Stable signature of the project's definitions for change detection: a sorted array
	 of (name, category) pairs. If this differs before/after a compile, structural change
	 happened (new def, removed def, renamed def, or category changed) and the UI needs
	 to rebuild. If it's the same, the save was a pure in-place edit and no rebuild needed."
	| pairs |
	project isNil ifTrue: [ ^ #() ].
	pairs := (project allDefinitions select: [ :d | d isKindOf: ZealDefinition ]) 
		collect: [ :d | { d name. self categoryFor: d } ].
	^ (pairs asSortedCollection: [ :a :b | a first <= b first ]) asArray
]

{ #category : 'accessing' }
GDZealBrowser >> definitionsForCategory: aCategory [
	"All definitions in the project belonging to the given category, sorted by name."
	| defs |
	project isNil ifTrue: [ ^ #() ].
	defs := project allDefinitions select: [ :d | 
		(d isKindOf: ZealDefinition) and: [ (self categoryFor: d) = aCategory ] ].
	^ (defs asSortedCollection: [ :a :b | a name <= b name ]) asArray
]

{ #category : 'editing' }
GDZealBrowser >> deindentLine: zealEditor [
	"Remove one level of indentation (2 spaces) from the current line"
	| text cursorPos lines lineIndex charCount line newLine |
	text := zealEditor editor text asString.
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	lines := text lines asOrderedCollection.
	charCount := 0.
	lineIndex := 1.
	lines
		doWithIndex: [ :l :i | 
			(charCount <= cursorPos and: [ cursorPos <= (charCount + l size + 1) ])
				ifTrue: [ lineIndex := i ].
			charCount := charCount + l size + 1 ].
	lineIndex > lines size ifTrue: [ ^ self ].
	line := lines at: lineIndex.
	(line beginsWith: '  ')
		ifTrue: [ newLine := line allButFirst: 2 ]
		ifFalse: [ (line beginsWith: ' ')
				ifTrue: [ newLine := line allButFirst ]
				ifFalse: [ ^ self ] ].
	lines at: lineIndex put: newLine.
	zealEditor
		text: ((ZealTheme highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (cursorPos - 2 max: 0);
		apply
]

{ #category : 'editing' }
GDZealBrowser >> duplicateLine: zealEditor [
	"Duplicate the current line below"
	| text cursorPos lines lineIndex charCount newCursorPos |
	text := zealEditor editor text asString.
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	lines := text lines asOrderedCollection.
	lines isEmpty ifTrue: [ ^ self ].
	charCount := 0.
	lineIndex := 1.
	lines
		doWithIndex: [ :l :i | 
			(charCount <= cursorPos and: [ cursorPos <= (charCount + l size + 1) ])
				ifTrue: [ lineIndex := i ].
			charCount := charCount + l size + 1 ].
	lineIndex > lines size ifTrue: [ ^ self ].
	
	"Insert duplicate after current line"
	lines add: (lines at: lineIndex) copy afterIndex: lineIndex.
	
	"Move cursor to same column on the new line"
	newCursorPos := cursorPos + (lines at: lineIndex) size + 1.
	
	zealEditor
		text: ((ZealTheme highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (newCursorPos min: zealEditor editor text size);
		apply
]

{ #category : 'editing' }
GDZealBrowser >> expandSelection: zealEditor [
	"Ctrl+W: expand selection outward through structural units"
	| text cursorPos ranges currentSelStart currentSelEnd currentSize nextRange |
	text := zealEditor editor text asString.
	text isEmpty ifTrue: [ ^ self ].
	
	"Get current selection or cursor position"
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	
	"Check if there's an existing selection"
	currentSelStart := cursorPos.
	currentSelEnd := cursorPos.
	zealEditor editor selection do: [:sel |
		currentSelStart := sel from min: currentSelEnd.
		currentSelEnd := sel to max: currentSelStart ].
	currentSize := currentSelEnd - currentSelStart.
	
	"Get all structural ranges from cursor position"
	ranges := ZealParinfer structuralRangesAt: cursorPos in: text.
	
	"Find the next range strictly larger than current selection"
	nextRange := ranges detect: [:r | (r value - r key) > currentSize ] ifNone: [ ^ self ].
	
	"Apply selection"
	zealEditor editor deselecter all deselect.
	zealEditor editor selecter
		from: nextRange key to: nextRange value;
		select.
	
	"Store expansion state for shrink"
	expandSelectionStack ifNil: [ expandSelectionStack := OrderedCollection new ].
	expandSelectionStack add: (currentSelStart -> currentSelEnd)
]

{ #category : 'private' }
GDZealBrowser >> extractDefName: source [
	"Extract the name after the first def-form in source"
	| forms |
	forms := #('defcomp ' 'defentity ' 'defsystem ' 'defobserver ' 'defn ').
	forms do: [ :form |
		| pos |
		pos := source findString: '(' , form.
		pos > 0 ifTrue: [
			| start end |
			start := pos + form size + 1.
			end := start.
			[ end <= source size and: [ (source at: end) isLetter or: [ (source at: end) isDigit or: [ '-_' includes: (source at: end) ] ] ] ] whileTrue: [ end := end + 1 ].
			end > start ifTrue: [ ^ source copyFrom: start to: end - 1 ] ] ].
	^ nil
]

{ #category : 'private' }
GDZealBrowser >> folderForSource: source [
	"Determine which folder a definition belongs in"
	(source includesSubstring: '(defcomp ') ifTrue: [ ^ 'components' ].
	(source includesSubstring: '(defentity ') ifTrue: [ ^ 'entities' ].
	(source includesSubstring: '(defsystem ') ifTrue: [ ^ 'systems' ].
	(source includesSubstring: '(defobserver ') ifTrue: [ ^ 'observers' ].
	^ 'scripts'
]

{ #category : 'private' }
GDZealBrowser >> gdScriptPathFor: name inFolder: folder [
	"Map GDZeal file name and folder to GDScript output path"
	| snakeName |
	snakeName := name copyReplaceAll: '-' with: '_'.
	folder = 'components' ifTrue: [ ^ 'components/c_' , snakeName , '.gd' ].
	folder = 'entities' ifTrue: [ ^ 'entities/' , snakeName , '.gd' ].
	folder = 'systems' ifTrue: [ ^ 'systems/' , snakeName , '.gd' ].
	folder = 'observers' ifTrue: [ ^ 'observers/' , snakeName , '.gd' ].
	^ 'scripts/' , snakeName , '.gd'
]

{ #category : 'model' }
GDZealBrowser >> gecsModules [
	"Return tree data: folders with their .zeal files (or .gd files to convert)"
	| components entities systems observers zealDir modules |
	zealDir := godotPath , '/gdzeal'.
	modules := OrderedCollection new.
	#('components' 'entities' 'systems' 'observers') do: [ :folder |
		| dir items |
		dir := zealDir , '/' , folder.
		items := OrderedCollection new.
		(dir asFileReference exists) ifTrue: [
			(dir asFileReference children
				select: [ :f | f extension = 'zeal' ]) 
				do: [ :f |
					| name |
					name := f basenameWithoutExtension.
					files at: folder , '/' , name put: f contents.
					items add: (name -> f fullName) ] ].
		modules add: (folder -> items) ].
	^ modules
]

{ #category : 'accessing' }
GDZealBrowser >> godotPath: aString [
	godotPath := aString.
	self buildUI
]

{ #category : 'editing' }
GDZealBrowser >> indentLine: zealEditor [
	"Smart indent: align to opener column + 1. If already there, add 2 more."
	| text cursorPos lines lineIndex charCount currentIndent targetIndent newIndent spacesToAdd |
	text := zealEditor editor text asString.
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	lines := text lines asOrderedCollection.
	charCount := 0.
	lineIndex := 1.
	lines
		doWithIndex: [ :l :i | 
			(charCount <= cursorPos and: [ cursorPos <= (charCount + l size + 1) ])
				ifTrue: [ lineIndex := i ].
			charCount := charCount + l size + 1 ].
	lineIndex > lines size ifTrue: [ ^ self ].
	
	"Calculate smart indent"
	currentIndent := ZealParinfer indentOf: (lines at: lineIndex).
	targetIndent := ZealParinfer smartIndentColumn: text forLine: lineIndex.
	
	"If below target, jump to target. If at or above, add 2."
	currentIndent < targetIndent
		ifTrue: [ newIndent := targetIndent ]
		ifFalse: [ newIndent := currentIndent + 2 ].
	spacesToAdd := newIndent - currentIndent.
	
	lines at: lineIndex put: (String new: spacesToAdd withAll: $ ) , (lines at: lineIndex).
	zealEditor
		text: ((ZealTheme highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (cursorPos + spacesToAdd min: zealEditor editor text size);
		apply
]

{ #category : 'initialization' }
GDZealBrowser >> initialize [
	super initialize.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].
	self background: GDZealTheme backgroundColor
]

{ #category : 'lsp' }
GDZealBrowser >> lintSource: aSource [
	"Run the GDZeal source linter against this source. Returns OC of diagnostic Dicts.
	 Empty if there's no type system or the lint succeeds."
	typeSystem ifNil: [ ^ #() ].
	^ (GDZealLinter withTypeSystem: typeSystem) lintSource: aSource
]

{ #category : 'lsp' }
GDZealBrowser >> lspModel [
	"Lazy-init the GDScript LSP model on first access. Returns nil if Godot's LSP isn't
	 reachable on localhost:6005 — diagnostics just won't show, but everything else
	 keeps working."
	lspModel ifNotNil: [ ^ lspModel ].
	project ifNil: [ ^ nil ].
	lspModel := [ GDZealLspModel onDirectory: project path asFileReference ]
		on: Error 
		do: [ :e | nil ].
	^ lspModel
]

{ #category : 'editing' }
GDZealBrowser >> moveCursorToSelectionEdge: zealEditor left: isLeft [
	"If there's a selection, move cursor to start (left) or end (right) and deselect.
	 If no selection, do nothing (let default handler run)."
	| selStart selEnd hasSelection |
	hasSelection := false.
	selStart := 0. selEnd := 0.
	zealEditor editor selection do: [:sel |
		selStart := sel from.
		selEnd := sel to.
		(selEnd > selStart) ifTrue: [ hasSelection := true ] ].
	hasSelection ifFalse: [ ^ false ]. "Signal: let default handle it"
	
	zealEditor editor deselecter all deselect.
	zealEditor editor navigator
		moveTo: (isLeft ifTrue: [ selStart ] ifFalse: [ selEnd ]);
		apply.
	^ true "Signal: we handled it"
]

{ #category : 'accessing' }
GDZealBrowser >> project [
	^ project
]

{ #category : 'accessing' }
GDZealBrowser >> project: aProject [
	project := aProject.
	self buildUI
]

{ #category : 'actions' }
GDZealBrowser >> promptNewFile [
	"Create a blank file — just focus the command bar"
	self inform: 'Type a definition in the command bar (bottom-left) and press Ctrl+S'
]

{ #category : 'refreshing' }
GDZealBrowser >> rebuildTree [
	"Refresh the entire view after project state changes (callers expect this name)."
	self buildUI
]

{ #category : 'refreshing' }
GDZealBrowser >> restoreUiState: state [
	"After a rebuildTree, re-apply the snapshot taken by captureUiState."
	| tabGroup expandedNames focusedName cursorPos targetTabIdx |
	tabGroup := nil.
	self allChildrenBreadthFirstDo: [ :c |
		(tabGroup isNil and: [ c isKindOf: BrTabGroup ]) ifTrue: [ tabGroup := c ] ].
	tabGroup ifNil: [ ^ self ].
	"Restore selected tab"
	targetTabIdx := state at: #selectedTabIndex.
	(targetTabIdx notNil and: [ targetTabIdx between: 1 and: tabGroup tabs size ])
		ifTrue: [ tabGroup viewModel selectTab: (tabGroup tabs at: targetTabIdx) ].
	"Re-expand cards. Walk after the tab content has been built."
	expandedNames := state at: #expandedNames.
	self allChildrenBreadthFirstDo: [ :c |
		(c isKindOf: BrExpander) ifTrue: [
			(c userData at: #defName ifAbsent: [ nil ]) ifNotNil: [ :n |
				(expandedNames includes: n) ifTrue: [ c expand ] ] ] ].
	"Restore cursor + focus"
	focusedName := state at: #focusedName.
	cursorPos := state at: #cursorPosition.
	focusedName ifNotNil: [
		self allChildrenBreadthFirstDo: [ :c |
			((c isKindOf: BrEditor) and: [ 
				(c userData at: #defName ifAbsent: [ nil ]) = focusedName ]) ifTrue: [
				c requestFocus.
				cursorPos ifNotNil: [
					[ c editor moveCursorTo: cursorPos ] on: Error do: [ :e | nil ] ] ] ] ]
]

{ #category : 'actions' }
GDZealBrowser >> selectFile: anAssociation [
	"Show editor for selected file"
	| name path source editor header compileBtn statusLabel |
	selectedFile := anAssociation.
	name := anAssociation key.
	path := anAssociation value.
	source := path asFileReference exists
		ifTrue: [ path asFileReference contents ]
		ifFalse: [ '' ].
	
	detailElement removeChildren.
	
	"Header with file name and compile button"
	statusLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme commentColor; fontSize: 11);
		text: '';
		margin: (BlInsets left: 12).
	
	header := BlElement new
		layout: (BlLinearLayout horizontal alignCenterLeft);
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets bottom: 8).
	header addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme definitionNameColor; fontSize: 14; bold);
		text: name).
	compileBtn := BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Compile (Ctrl+S)';
		margin: (BlInsets left: 12);
		action: [ self compileCurrentFile: editor statusLabel: statusLabel ].
	header addChild: compileBtn.
	header addChild: statusLabel.
	detailElement addChild: header.
	detailElement addChild: self buildDivider.
	
	"Editor"
	editor := self buildZealEditor: source.
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self compileCurrentFile: editor statusLabel: statusLabel ]).
	detailElement addChild: editor
]

{ #category : 'commands' }
GDZealBrowser >> selectNode: aDef [
	"In the new tab+expander layout there is no separate detail pane — each definition is
	 inline-expandable in its category tab. Selecting from outside (e.g. ClaudeMcpServer
	 after creating a definition) just rebuilds the view so the new card appears."
	self rebuildTree
]

{ #category : 'editor setup' }
GDZealBrowser >> setupArrowKeys: zealEditor [
	"Override arrow keys: with selection, jump to selection edge instead of moving one char."
	| leftShortcut rightShortcut |
	
	"Remove default ArrowLeft and ArrowRight"
	leftShortcut := zealEditor shortcuts 
		detect: [:s | s combination asString = 'ArrowLeft'] ifNone: [nil].
	leftShortcut ifNotNil: [ zealEditor removeShortcut: leftShortcut ].
	rightShortcut := zealEditor shortcuts 
		detect: [:s | s combination asString = 'ArrowRight'] ifNone: [nil].
	rightShortcut ifNotNil: [ zealEditor removeShortcut: rightShortcut ].
	
	zealEditor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination arrowLeft;
		action: [ 
			(self moveCursorToSelectionEdge: zealEditor left: true) ifFalse: [
				"No selection — move left normally"
				zealEditor editor navigator
					moveLeft;
					apply ] ]).
	zealEditor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination arrowRight;
		action: [
			(self moveCursorToSelectionEdge: zealEditor left: false) ifFalse: [
				zealEditor editor navigator
					moveRight;
					apply ] ])
]

{ #category : 'editor setup' }
GDZealBrowser >> setupFormHighlight: anEditor [
	"Listen for cursor changes and highlight the innermost form at cursor position"
	anEditor editor
		when: BrTextEditorCursorChangedEvent do: [:e |
			| text source cursorPos pairs stack inString innermost |
			text := anEditor editor text.
			source := text asString.
			cursorPos := 0.
			anEditor editor cursors do: [:c | cursorPos := c position].
			
			"Clear old highlights"
			text clearAttributes: [:a | a isKindOf: BlTextHighlightAttribute].
			
			cursorPos = 0 ifFalse: [
				"Find all paren pairs (1-based)"
				pairs := OrderedCollection new.
				stack := OrderedCollection new.
				inString := false.
				1 to: source size do: [:i |
					| ch |
					ch := source at: i.
					ch = $" ifTrue: [ inString := inString not ]
					ifFalse: [ inString ifFalse: [
						(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
						(#($) $] $}) includes: ch) ifTrue: [
							stack notEmpty ifTrue: [ pairs add: stack removeLast -> i ] ] ] ] ].
				
				"Find innermost form containing cursor (cursor is 0-based, pairs are 1-based)"
				innermost := nil.
				pairs do: [:pair |
					(pair key <= cursorPos and: [pair value > cursorPos]) ifTrue: [
						(innermost isNil or: [(pair value - pair key) < (innermost value - innermost key)])
							ifTrue: [ innermost := pair ] ] ].
				
				innermost ifNotNil: [
					(text from: innermost key to: innermost value) 
						attribute: (BlTextHighlightAttribute new paint: ((Color fromHexString: '9580FF') alpha: 0.2)) ] ] ]
]

{ #category : 'editor setup' }
GDZealBrowser >> setupKeyChords: zealEditor [
	"Install key chord handler with default chords"
	keyChord := ZealKeyChord new.
	keyChord installOn: zealEditor.
	
	"Example chords — add more with: keyChord addChord: 'xx' action: [...]"
	keyChord addChord: 'jk' action: [ self applyParinfer: zealEditor ]
]

{ #category : 'editor setup' }
GDZealBrowser >> setupParinfer: zealEditor [
	"Alt+F: format. Tab/Shift+Tab: indent/deindent + parinfer. Ctrl+X: cut/remove line. Ctrl+D: duplicate. Ctrl+W/Shift+W: expand/shrink selection. Ctrl+Alt+Right/Left: slurp/barf."
	| ctrlXShortcut ctrlWShortcut |
	
	ctrlXShortcut := zealEditor shortcuts 
		detect: [:s | s combination asString asLowercase includesSubstring: '& x'] 
		ifNone: [ nil ].
	ctrlXShortcut ifNotNil: [ zealEditor removeShortcut: ctrlXShortcut ].
	ctrlWShortcut := zealEditor shortcuts 
		detect: [:s | s combination asString asLowercase includesSubstring: '& w'] 
		ifNone: [ nil ].
	ctrlWShortcut ifNotNil: [ zealEditor removeShortcut: ctrlWShortcut ].
	
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder alt f build);
		action: [ self applyFormat: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: BlKeyCombination tab;
		action: [ self indentLine: zealEditor. self applyParinfer: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder shift tab build);
		action: [ self deindentLine: zealEditor. self applyParinfer: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder control x build);
		action: [ self cutOrRemoveLine: zealEditor. self applyParinfer: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder control d build);
		action: [ self duplicateLine: zealEditor. self applyParinfer: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder control w build);
		action: [ self expandSelection: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder control shift w build);
		action: [ self shrinkSelection: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder control alt arrowRight build);
		action: [ self slurpForward: zealEditor ]).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: (BlKeyCombination builder control alt arrowLeft build);
		action: [ self barfForward: zealEditor ])
]

{ #category : 'editing' }
GDZealBrowser >> shrinkSelection: zealEditor [
	"Ctrl+Shift+W: shrink selection back to previous level"
	| prev |
	(expandSelectionStack isNil or: [ expandSelectionStack isEmpty ]) ifTrue: [ ^ self ].
	prev := expandSelectionStack removeLast.
	zealEditor editor deselecter all deselect.
	(prev key = prev value)
		ifTrue: [
			zealEditor editor navigator moveTo: prev key; apply ]
		ifFalse: [
			zealEditor editor selecter from: prev key to: prev value; select ]
]

{ #category : 'editing' }
GDZealBrowser >> slurpForward: zealEditor [
	"Slurp: pull next expression into the current form"
	| text cursorPos result pairs containing openerPos |
	text := zealEditor editor text asString.
	text isEmpty ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	
	"Debug — store in class var for inspection"
	pairs := ZealParinfer parenPairsIn: text.
	containing := (pairs select: [:p | p key <= cursorPos and: [p value >= cursorPos]])
		sorted: [:a :b | (a value - a key) < (b value - b key)].
	containing isEmpty ifTrue: [ 
		Smalltalk globals at: #ZealDebug put: 'no form at cursor ' , cursorPos printString. ^ self ].
	openerPos := containing first key.
	Smalltalk globals at: #ZealDebug put: 
		'cursor=' , cursorPos printString ,
		' opener=' , openerPos printString ,
		' firstArgCol=' , (ZealParinfer firstArgColumnAt: openerPos in: text) printString ,
		' closer=' , containing first value printString.
	
	result := ZealParinfer slurpForward: text at: cursorPos.
	result = text ifTrue: [ ^ self ].
	zealEditor text: ((ZealTheme highlight: result)).
	zealEditor editor navigator moveTo: (cursorPos min: result size); apply
]

{ #category : 'actions' }
GDZealBrowser >> spawnErrorPageOn: editor source: aSource linterDiags: linterDiags compilerError: anError [
	"Open a pager page showing a compile/lint error with the offending text highlighted."
	| errorObj |
	errorObj := GDZealCompileError new
		source: aSource;
		linterDiags: linterDiags;
		compilerError: anError;
		yourself.
	[ editor phlow spawnTool: (GtPhlowExplicitTool new
		name: 'Compile error';
		stencil: [ self buildErrorPage: errorObj ]) ]
		on: Error do: [ :e | errorObj inspect ]
]

{ #category : 'actions' }
GDZealBrowser >> spawnResultPageOn: editor result: aResult [
	"Open a pager page on the compile result so the user can see the GDZeal source
	 and generated GDScript side-by-side."
	[ editor phlow spawnTool: (GtPhlowExplicitTool new
		name: aResult definitionName , ' compiled';
		stencil: [ self buildResultPage: aResult ]) ]
		on: Error do: [ :e | aResult inspect ]
]

{ #category : 'editing' }
GDZealBrowser >> swapForm: anEditor up: isUp [
	"Swap element at cursor with adjacent sibling. Cursor stays at same position in element."
	| text cursorPos result stack inString pairs innermost elements currentIdx current offsetInElement currentText newStart newCursorPos |
	text := anEditor editor text asString.
	text isEmpty ifTrue: [ ^ self ].
	cursorPos := 0.
	anEditor editor cursors do: [:c | cursorPos := c position].
	
	pairs := OrderedCollection new. stack := OrderedCollection new. inString := false.
	1 to: text size do: [:i | | ch | ch := text at: i.
		ch = $" ifTrue: [ inString := inString not ] ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
			(#($) $] $}) includes: ch) ifTrue: [ stack notEmpty ifTrue: [ pairs add: stack removeLast -> i ] ] ] ] ].
	innermost := nil.
	pairs do: [:pair | (pair key < cursorPos and: [pair value > cursorPos]) ifTrue: [
		(innermost isNil or: [(pair value - pair key) < (innermost value - innermost key)]) ifTrue: [ innermost := pair ] ] ].
	innermost ifNil: [ ^ self ].
	
	elements := ZealParinfer elementsInForm: text from: innermost key to: innermost value.
	elements size < 2 ifTrue: [ ^ self ].
	currentIdx := 0.
	elements doWithIndex: [:e :idx | (e key <= cursorPos and: [e value >= cursorPos]) ifTrue: [ currentIdx := idx ] ].
	currentIdx = 0 ifTrue: [ ^ self ].
	isUp ifTrue: [ currentIdx <= 1 ifTrue: [ ^ self ] ] ifFalse: [ currentIdx >= elements size ifTrue: [ ^ self ] ].
	
	current := elements at: currentIdx.
	"0-based offset: cursorPos is 0-based, current key is 1-based"
	offsetInElement := cursorPos - (current key - 1).
	currentText := text copyFrom: current key to: current value.
	
	result := isUp
		ifTrue: [ ZealParinfer swapFormUp: text at: cursorPos ]
		ifFalse: [ ZealParinfer swapFormDown: text at: cursorPos ].
	result = text ifTrue: [ ^ self ].
	
	newStart := isUp
		ifTrue: [ (elements at: currentIdx - 1) key ]
		ifFalse: [ result findString: currentText startingAt: (elements at: currentIdx) key ].
	"Convert 1-based newStart to 0-based and add offset"
	newCursorPos := (newStart - 1) + offsetInElement.
	
	suppressRehighlight := true.
	anEditor editor deleter from: 0 to: text size; delete.
	anEditor editor inserter at: 0; string: result; withoutCursorUpdate; insert.
	suppressRehighlight := false.
	anEditor editor navigator moveTo: ((newCursorPos max: 0) min: result size); apply
]

{ #category : 'hooks' }
GDZealBrowser >> themeClass [
	^ GDZealTheme
]

{ #category : 'accessing' }
GDZealBrowser >> typeSystem [
	^ typeSystem
]

{ #category : 'accessing' }
GDZealBrowser >> typeSystem: aGDZealTypeSystem [
	typeSystem := aGDZealTypeSystem
]

{ #category : 'lsp' }
GDZealBrowser >> updateDiagnosticsFor: editor with: diagnostics [
	"Find the diagnostics container belonging to the same definition as `editor` and
	 repopulate it with one row per diagnostic message. Empty if no diagnostics."
	| defName container |
	defName := editor userData at: #defName ifAbsent: [ ^ self ].
	"Walk up to the root, then down to find the matching diagnostics container."
	container := nil.
	self allChildrenBreadthFirstDo: [ :c |
		(container isNil 
			and: [ (c userData at: #role ifAbsent: [ nil ]) = #diagnostics
			and: [ (c userData at: #defName ifAbsent: [ nil ]) = defName ] ])
			ifTrue: [ container := c ] ].
	container ifNil: [ ^ self ].
	container removeChildren.
	(diagnostics isNil or: [ diagnostics isEmpty ]) ifTrue: [ ^ self ].
	diagnostics do: [ :d | 
		container addChild: (self buildDiagnosticRow: d) ]
]
