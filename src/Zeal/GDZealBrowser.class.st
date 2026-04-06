Class {
	#name : 'GDZealBrowser',
	#superclass : 'ZealBrowser',
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
	space := BlSpace new.
	space title: 'GDZeal // ' , proj name.
	space extent: 1100@700.
	space root layout: BlLinearLayout vertical.
	space root background: GDZealTheme backgroundColor.
	space root addChild: browser.
	space show.
	^ browser
]

{ #category : 'building' }
GDZealBrowser >> buildCommandBar [
	| input |
	input := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		styler: GDZealTextStyler new;
		text: '';
		background: self themeClass backgroundColor;
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
GDZealBrowser >> buildFieldItem: aField [
	| label |
	label := aField name.
	aField type ifNotNil: [ :t | label := label , ' : ' , t ].
	aField defaultValue ifNotNil: [ :v |
		(v isKindOf: ZealLiteral) ifTrue: [ label := label , ' = ' , v value ] ].
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass colonChainColor; fontSize: 12);
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
				ifTrue: [ label text: (item key asRopedText foreground: self themeClass keywordColor) bold ]
				ifFalse: [ label text: (item name asRopedText foreground: self themeClass foregroundColor) ] ];
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
		background: self themeClass backgroundColor darker;
		padding: (BlInsets all: 8).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass classRefColor; fontSize: 14; bold);
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
		background: self themeClass backgroundColor lighter.
	leftPane addChild: self buildTree.
	leftPane addChild: self buildDivider.
	leftPane addChild: self buildCommandBar.
	content addChild: leftPane.

	"Detail pane"
	detailElement := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ];
		background: self themeClass backgroundColor;
		padding: (BlInsets all: 12).
	detailElement addChild: self buildWelcome.
	content addChild: detailElement.

	self addChild: topBar.
	self addChild: content
]

{ #category : 'building' }
GDZealBrowser >> buildWelcome [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass commentColor; fontSize: 13);
		text: 'Select a definition or create a new one'
]

{ #category : 'building' }
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
	  statusLabel text: ('Compiled -> ' , path) asRopedText foreground: self themeClass keywordColor ]
	on: Error do: [ :e |
		statusLabel text: ('Error: ' , e messageText) asRopedText foreground: self themeClass specialFormColor ]
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
	  "Update selected node reference"
	  selectedNode := newNode.
	  statusLabel text: ('Compiled -> ' , gdPath) asRopedText foreground: self themeClass keywordColor.
	  self rebuildTree ]
	on: Error do: [ :e |
		statusLabel text: ('Error: ' , e messageText) asRopedText foreground: self themeClass specialFormColor ]
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

{ #category : 'initialization' }
GDZealBrowser >> initialize [
	super initialize.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].
	self background: self themeClass backgroundColor
]

{ #category : 'accessing' }
GDZealBrowser >> project [
	^ project
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
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass commentColor; fontSize: 11);
		text: '';
		margin: (BlInsets left: 12).
	
	header := BlElement new
		layout: (BlLinearLayout horizontal alignCenterLeft);
		constraintsDo: [ :c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets bottom: 8).
	header addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass definitionNameColor; fontSize: 14; bold);
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

{ #category : 'actions' }
GDZealBrowser >> selectNode: aNode [
	"Show detail editor for selected definition"
	| header editor statusLabel compileBtn typeLabel |
	selectedNode := aNode.
	detailElement removeChildren.
	
	"Header"
	typeLabel := aNode isKindOf: ZealClass
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

{ #category : 'hooks' }
GDZealBrowser >> themeClass [
	^ GDZealTheme
]
