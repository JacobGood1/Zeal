Class {
	#name : 'GDZealBrowser',
	#superclass : 'ZealBrowser',
	#instVars : [
		'typeSystem'
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
	"Open a GDZeal browser on a Godot project"
	| proj browser space |
	proj := GDZealProject new.
	proj path: aGodotPath.
	proj name: aGodotPath asFileReference basename.
	proj loadFromDirectory.
	browser := self new.
	browser project: proj.
	browser typeSystem: (GDZealTypeSystem forProject: proj).
	space := BlSpace new.
	space title: 'GDZeal // ' , proj name.
	space extent: 1100@700.
	space root layout: BlLinearLayout vertical.
	space root background: GDZealTheme backgroundColor.
	space root addChild: browser.
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
GDZealBrowser >> buildDivider [
	^ BlElement new
		constraintsDo: [ :c | c horizontal matchParent. c vertical exact: 1 ];
		background: (Color fromHexString: '444444')
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
GDZealBrowser >> buildSectionLabel: aString [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme specialFormColor; fontSize: 11);
		text: aString;
		margin: (BlInsets top: 8 bottom: 4)
]

{ #category : 'building' }
GDZealBrowser >> buildTree [
	"Tree showing modules -> definitions (ZealNode objects)"
	| items |
	items := project modules associations collect: [ :assoc |
		assoc key -> assoc value ].
	treeElement := BrSimpleTree new
		nodeStencil: [
			BrLabel new aptitude: (BrGlamorousLabelAptitude new fontSize: 12) ];
		nodeDataBinder: [ :label :item |
			(item isKindOf: Association)
				ifTrue: [ label text: (item key asRopedText foreground: GDZealTheme keywordColor) bold ]
				ifFalse: [ label text: (item name asRopedText foreground: GDZealTheme foregroundColor) ] ];
		items: items lazy: [ :item |
			(item isKindOf: Association)
				ifTrue: [ item value definitions ]
				ifFalse: [ #() ] ];
		when: BrSelectionChanged do: [ :event |
			event indices ifNotEmpty: [ :indices |
				| treeNode item |
				treeNode := treeElement viewModel itemAt: indices first.
				item := treeNode value.
				(item isKindOf: Association)
					ifFalse: [ self selectNode: item ] ] ];
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		background: Color transparent;
		padding: (BlInsets all: 4).
	"Auto-expand"
	treeElement viewModel root childrenNodes do: [ :node | node expand ].
	^ treeElement
]

{ #category : 'building' }
GDZealBrowser >> buildUI [
	| topBar content leftPane |
	self removeChildren.
	
	"Top bar"
	topBar := BlElement new
		layout: (BlLinearLayout horizontal alignCenterLeft);
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		background: GDZealTheme backgroundColor darker;
		padding: (BlInsets all: 8).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: GDZealTheme classRefColor; fontSize: 14; bold);
		text: 'GDZeal // ' , project name;
		margin: (BlInsets right: 12)).
	topBar addChild: self buildCompileAllButton.

	"Content: left tree + right detail"
	content := BlElement new
		layout: BlLinearLayout horizontal;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].

	"Left pane"
	leftPane := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal exact: 260. c vertical matchParent ];
		background: GDZealTheme backgroundColor lighter.
	leftPane addChild: self buildTree.
	leftPane addChild: self buildDivider.
	leftPane addChild: self buildCommandBar.
	content addChild: leftPane.

	"Detail pane"
	detailElement := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		background: GDZealTheme backgroundColor;
		padding: (BlInsets all: 12).
	detailElement addChild: self buildWelcome.
	content addChild: detailElement.

	self addChild: topBar.
	self addChild: content
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
GDZealBrowser >> compileNode: aNode editor: editor statusLabel: statusLabel [
	"Compile the editor content, update the object model, save, and deploy .gd"
	| source newNode gdPath |
	source := editor editor text asString.
	[ "Re-parse to update the object model"
	  newNode := GDZealCompiler compile: source.
	  newNode rawSource: source.
	  "Update in project"
	  project addDefinition: newNode fromSource: source.
	  "Save .zeal file"
	  project saveDefinition: newNode.
	  "Compile to .gd"
	  gdPath := project compileDefinition: newNode.
	  "Persist to image"
	  project persistToImage.
	  "Rescan types after compile"
	  typeSystem ifNotNil: [ typeSystem rescan ].
	  "Update selected node reference"
	  selectedNode := newNode.
	  statusLabel text: (('Compiled -> ' , gdPath) asRopedText foreground: self themeClass keywordColor).
	  self flashSuccess: editor.
	  self rebuildTree ]
	on: Error do: [ :e |
		statusLabel text: (('Error: ' , e messageText) asRopedText foreground: (Color red)).
		self flashError: editor ]
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

{ #category : 'actions' }
GDZealBrowser >> createFromInput: editor [
	"Create a new definition from the command bar"
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
	  self rebuildTree.
	  self selectNode: node ]
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

{ #category : 'actions' }
GDZealBrowser >> rebuildTree [
	"Refresh tree from project state"
	| items |
	items := project modules associations collect: [ :assoc |
		assoc key -> assoc value ].
	treeElement items: items lazy: [ :item |
		(item isKindOf: Association)
			ifTrue: [ item value definitions ]
			ifFalse: [ #() ] ].
	treeElement viewModel root childrenNodes do: [ :node | node expand ]
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

{ #category : 'navigation' }
GDZealBrowser >> selectNode: aNode [
	"Show detail editor for selected definition"
	| header editor statusLabel compileBtn typeLabel |
	selectedNode := aNode.
	detailElement removeChildren.
	
	"Header"
	typeLabel := (aNode isKindOf: ZealClass)
		ifTrue: [ aNode superclass ]
		ifFalse: [ aNode class name allButFirst: 4 "strip Zeal" ].
	statusLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass commentColor; fontSize: 11);
		text: '';
		margin: (BlInsets left: 12).
	header := BlElement new
		layout: (BlLinearLayout horizontal alignCenterLeft);
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets bottom: 8).
	header addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass operatorColor; fontSize: 11);
		text: typeLabel;
		margin: (BlInsets right: 8)).
	header addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass definitionNameColor; fontSize: 14; bold);
		text: aNode name).
	compileBtn := BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Compile (Ctrl+S)';
		margin: (BlInsets left: 12);
		action: [ self compileNode: aNode editor: editor statusLabel: statusLabel ].
	header addChild: compileBtn.
	header addChild: statusLabel.
	detailElement addChild: header.
	detailElement addChild: self buildDivider.
	
	"Detail: fields for classes"
	(aNode isKindOf: ZealClass) ifTrue: [
		aNode fields ifNotEmpty: [ :fields |
			detailElement addChild: (self buildSectionLabel: 'Fields').
			fields do: [ :f |
				detailElement addChild: (self buildFieldItem: f) ] ] ].
	
	"Source editor"
	detailElement addChild: (self buildSectionLabel: 'Source').
	editor := self buildZealEditor: (aNode rawSource ifNil: [ '' ]).
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self compileNode: aNode editor: editor statusLabel: statusLabel ]).
	detailElement addChild: editor
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
