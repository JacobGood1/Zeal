Class {
	#name : 'AngelZealBrowser',
	#superclass : 'ZealBrowser',
	#instVars : [
		'currentFile',
		'zealEditor',
		'angelEditor'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealBrowser class >> openFolder: aPathString [
	"Open the AngelZeal browser on a folder."
	| project browser space pager |
	project := AngelZealProject new scanFolder: aPathString asFileReference.
	browser := self new.
	browser project: project.
	pager := GtPager createWrappedOn: browser.
	pager background: ZealTheme backgroundColor.
	space := BlSpace new.
	space title: 'AngelZeal // ' , project name.
	space extent: 1200 @ 800.
	space root background: ZealTheme backgroundColor.
	space root addChild: pager.
	space show.
	^ browser
]

{ #category : 'api' }
AngelZealBrowser >> buildAngelOnlyDetailFor: aFileRef source: asSource [
	"Read-only display for pre-existing .as files that have no Zeal source."
	| text |
	text := asSource asRopedText foreground: ZealTheme foregroundColor.
	angelEditor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: text;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		beReadOnlyWithSelection;
		padding: (BlInsets all: 8).
	detailElement addChild: angelEditor
]

{ #category : 'api' }
AngelZealBrowser >> buildDetail [
	"Right pane: a vertical container that the tree's selection handler fills in.
	 Starts empty with a placeholder label."
	detailElement := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		background: ZealTheme backgroundColor;
		padding: (BlInsets all: 12).
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 13);
		text: 'Select a file to view / edit').
	^ detailElement
]

{ #category : 'api' }
AngelZealBrowser >> buildTree [
	"File-system tree: items are FileReferences (folders + .zeal/.as files).
	 Lazy children: folders are expanded on demand via project childrenOf:.
	 Selecting a file loads it into the detail pane; selecting a folder is a no-op."
	| root |
	root := project rootFolder.
	treeElement := BrSimpleTree new.
	treeElement
		nodeStencil: [
			BlElement new
				layout: BlLinearLayout horizontal alignCenterLeft;
				constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
				addChild: (BlElement new id: #iconHolder;
					constraintsDo: [:c | c horizontal exact: 18. c vertical exact: 16 ]);
				addChild: (BrLabel new
					aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme foregroundColor; fontSize: 13);
					id: #name) ];
		nodeDataBinder: [ :row :item |
			row childWithId: #iconHolder ifFound: [:holder |
				holder removeChildren.
				holder addChild: (self iconElementForFile: item) ].
			row childWithId: #name ifFound: [:lbl |
				lbl text: (item basename asRopedText foreground: ZealTheme foregroundColor) ] ];
		items: { root } lazy: [ :item |
			item isDirectory ifTrue: [ project childrenOf: item ] ifFalse: [ #() ] ];
		when: BrSelectionChanged do: [:event |
			event indices ifNotEmpty: [:indices |
				treeElement selectedNodeDo: [:treeNode |
					| f |
					f := treeNode value.
					(f notNil and: [ f isFile ]) ifTrue: [ self openFile: f ] ] ] ].
	treeElement background: ZealTheme backgroundColor lighter.
	treeElement padding: (BlInsets all: 8).
	treeElement constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	^ treeElement
]

{ #category : 'api' }
AngelZealBrowser >> buildUI [
	"Top bar (title) + horizontal split: file tree | detail pane."
	| leftPane topBar content mainLayout |
	self removeChildren.

	topBar := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		background: ZealTheme backgroundColor darker;
		padding: (BlInsets all: 6).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 14; bold);
		text: 'AngelZeal // ' , project name;
		margin: (BlInsets right: 12)).

	content := BlElement new
		layout: BlLinearLayout horizontal;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].

	leftPane := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal exact: 300. c vertical matchParent ];
		background: ZealTheme backgroundColor lighter.
	leftPane addChild: self buildTree.
	treeElement constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	content addChild: leftPane.

	content addChild: self buildDetail.

	mainLayout := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	mainLayout addChild: topBar.
	mainLayout addChild: content.
	self addChild: mainLayout
]

{ #category : 'api' }
AngelZealBrowser >> buildZealDetailFor: aFileRef source: zealSource [
	"Editable Zeal editor on top with syntax highlighting, read-only compiled
	 AngelScript preview below. Ctrl+S triggers compileAndSave."
	| angelSource previewText styler |
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 12);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets top: 4 bottom: 4)).

	zealEditor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: zealSource asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8).
	styler := ZealTextStyler new browser: self.
	zealEditor editor styler: styler.
	self configureZealEditor: zealEditor.
	zealEditor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self compileAndSave ]).
	detailElement addChild: zealEditor.

	"Apply the styler manually after the editor is in the scene — Bloc doesn't
	 auto-style on initial text:, only on edits."
	zealEditor enqueueTask: (BlTaskAction new action: [
		zealEditor editor text: (styler style: zealEditor editor text) ]).

	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'AngelScript output:';
		margin: (BlInsets top: 4 bottom: 4)).

	angelSource := [ AngelZealCompiler compileToAngelScript: zealSource ]
		on: Error do: [ :e | 'Compile error: ' , e messageText ].
	previewText := angelSource asRopedText foreground: ZealTheme foregroundColor.
	angelEditor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: previewText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		beReadOnlyWithSelection;
		padding: (BlInsets all: 8).
	detailElement addChild: angelEditor
]

{ #category : 'api' }
AngelZealBrowser >> compileAndSave [
	"Read current Zeal editor text, compile to AngelScript, write both files:
	 .zeal (source) next to .as (compiled output). Refresh the AngelScript preview."
	| zealSource angelSource asPath previewText |
	zealEditor ifNil: [ ^ self ].
	currentFile ifNil: [ ^ self ].
	zealSource := zealEditor editor text asString.
	angelSource := [ AngelZealCompiler compileToAngelScript: zealSource ]
		on: Error do: [ :e |
			self flashError: zealEditor.
			^ self ].

	"Write the .zeal file verbatim."
	[ currentFile writeStreamDo: [ :ws | ws nextPutAll: zealSource ] ]
		on: Error do: [ :e | self flashError: zealEditor. ^ self ].

	"Write the sibling .as file (same basename)."
	asPath := currentFile parent / (currentFile basenameWithoutExtension , '.as').
	[ asPath writeStreamDo: [ :ws | ws nextPutAll: angelSource ] ]
		on: Error do: [ :e | ].

	"Refresh the preview."
	angelEditor ifNotNil: [
		previewText := angelSource asRopedText foreground: ZealTheme foregroundColor.
		angelEditor editor text: previewText ].

	self flashSuccess: zealEditor
]

{ #category : 'api' }
AngelZealBrowser >> iconElementForFile: aFileRef [
	"Simple colored square to distinguish folder / .zeal / .as."
	| color |
	aFileRef isDirectory
		ifTrue: [ color := ZealTheme specialFormColor ]
		ifFalse: [
			aFileRef extension = 'zeal'
				ifTrue: [ color := ZealTheme cursorColor ]
				ifFalse: [ color := ZealTheme commentColor ] ].
	^ BlElement new
		background: color;
		constraintsDo: [:c | c horizontal exact: 12. c vertical exact: 12 ];
		margin: (BlInsets right: 6)
]

{ #category : 'api' }
AngelZealBrowser >> openFile: aFileRef [
	"Load file contents into the detail pane. .zeal files become an editable
	 Zeal buffer with a read-only AngelScript preview underneath; .as files
	 show read-only with no Zeal counterpart."
	| source header |
	currentFile := aFileRef.
	detailElement removeChildren.

	header := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets bottom: 8).
	header addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 16; bold);
		text: aFileRef basename).
	detailElement addChild: header.

	source := [ aFileRef contents ] on: Error do: [ :e | 'Error reading file: ' , e messageText ].

	aFileRef extension = 'zeal'
		ifTrue: [ self buildZealDetailFor: aFileRef source: source ]
		ifFalse: [ self buildAngelOnlyDetailFor: aFileRef source: source ]
]

{ #category : 'api' }
AngelZealBrowser >> project: anAngelZealProject [
	project := anAngelZealProject.
	self buildUI
]

{ #category : 'api' }
AngelZealBrowser >> themeClass [
	^ AngelZealTheme
]
