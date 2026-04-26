Class {
	#name : 'ZealBrowser',
	#superclass : 'BlElement',
	#instVars : [
		'project',
		'treeElement',
		'detailElement',
		'selectedNode',
		'expandSelectionStack',
		'keyChord',
		'suppressRehighlight',
		'rehighlightProcess',
		'completionController',
		'currentFile',
		'zealEditor',
		'cards',
		'fileDefsEditor',
		'fileDefsBufferText',
		'fileDefsCursorPos',
		'projectTree'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'fonts' }
ZealBrowser class >> codeFontName [
	"Pick the best available monospace font for code surfaces. Returns the
	 first system-installed family from a priority list, or nil if none of
	 the candidates is installed (callers should fall back to the editor's
	 default in that case)."
	| fams candidates |
	fams := SkiaFontManager default familyNames asSet.
	candidates := #('Iosevka Nerd Font' 'Iosevka' 'Cascadia Code' 'Cascadia Mono' 'JetBrains Mono' 'Fira Code' 'Consolas' 'Source Code Pro').
	^ candidates detect: [ :f | fams includes: f ] ifNone: [ nil ]
]

{ #category : 'cards' }
ZealBrowser >> addDefinitionsFrom: anEditor toCard: cardRec [
	"Parse top-level forms from anEditor's text. Multi-binding (def x 1 y 2) is
	 expanded to multiple single bindings. Each form is routed to slots/methods,
	 replacing any existing entry with the same name. Editor text and cursor
	 position are preserved across the rebuild, and focus returns to the editor."
	| text forms slots methods newEditor cursorPos |
	text := anEditor editor text asString trimBoth.
	text isEmpty ifTrue: [ ^ self ].
	forms := self splitTopLevelForms: text.
	forms isEmpty ifTrue: [ self flashError: anEditor. ^ self ].
	forms := self expandMultiBindings: forms.

	cursorPos := 0.
	anEditor editor cursors do: [ :c | cursorPos := c position ].
	cardRec at: #defsBufferText put: anEditor editor text asString.
	cardRec at: #defsCursorPos put: cursorPos.

	slots := cardRec at: #slotSources ifAbsent: [
		| empty | empty := OrderedCollection new.
		cardRec at: #slotSources put: empty. empty ].
	methods := cardRec at: #methodSources ifAbsent: [
		| empty | empty := OrderedCollection new.
		cardRec at: #methodSources put: empty. empty ].
	(cardRec at: #subCards ifAbsent: [ #() ]) doWithIndex: [ :sub :i |
		(i <= methods size) ifTrue: [ methods at: i put: (sub at: #source) ] ].

	forms do: [ :formSrc |
		| trimmed targetList newName existingIdx |
		trimmed := formSrc trimBoth.
		targetList := nil.
		(trimmed beginsWith: '(defn') ifTrue: [ targetList := methods ]
		ifFalse: [
			((trimmed beginsWith: '(var') or: [ trimmed beginsWith: '(def ' ])
				ifTrue: [ targetList := slots ] ].
		targetList ifNotNil: [
			newName := self nameOfForm: formSrc.
			existingIdx := nil.
			(newName notNil and: [ newName isString ]) ifTrue: [
				targetList doWithIndex: [ :existing :i |
					existingIdx ifNil: [
						(self nameOfForm: existing) = newName
							ifTrue: [ existingIdx := i ] ] ] ].
			existingIdx
				ifNotNil: [ targetList at: existingIdx put: formSrc ]
				ifNil: [ targetList add: formSrc ] ] ].

	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self saveAllCards.
	newEditor := cardRec at: #defsEditor ifAbsent: [ nil ].
	newEditor ifNotNil: [ self flashSuccess: newEditor ]
]

{ #category : 'cards' }
ZealBrowser >> addFileDefinitionsFrom: anEditor inFile: aFileRef [
	"Parse top-level forms from anEditor's text, expand multi-bindings, add
	 each as a new top-level card (or replace an existing card with the same
	 name). After the file is rewritten, re-open with the LAST-added form
	 expanded so the user sees what they just compiled."
	| text forms cursorPos lastName |
	text := anEditor editor text asString trimBoth.
	text isEmpty ifTrue: [ ^ self ].
	forms := self splitTopLevelForms: text.
	forms isEmpty ifTrue: [ self flashError: anEditor. ^ self ].
	forms := self expandMultiBindings: forms.

	cursorPos := 0.
	anEditor editor cursors do: [ :c | cursorPos := c position ].
	fileDefsBufferText := anEditor editor text asString.
	fileDefsCursorPos := cursorPos.

	lastName := nil.
	forms do: [ :formSrc |
		| newName existingIdx |
		newName := self nameOfForm: formSrc.
		newName ifNotNil: [ lastName := newName ].
		existingIdx := nil.
		(newName notNil and: [ newName isString ]) ifTrue: [
			cards doWithIndex: [ :rec :i |
				existingIdx ifNil: [
					(self nameOfForm: (rec at: #source)) = newName
						ifTrue: [ existingIdx := i ] ] ] ].
		existingIdx
			ifNotNil: [
				| rec |
				rec := cards at: existingIdx.
				rec at: #source put: formSrc ]
			ifNil: [
				cards add: (Dictionary new
					at: #source put: formSrc;
					at: #editor put: nil;
					at: #file put: aFileRef;
					yourself) ] ].

	self saveAllCards.
	self openFile: aFileRef expandName: lastName.
	self flashSuccess: fileDefsEditor
]

{ #category : 'fonts' }
ZealBrowser >> applyCodeFontTo: aBrEditor [
	"Apply the preferred code font to a BrEditor's text rope. No-op if no
	 candidate font is installed — the editor falls back to whatever its
	 aptitude renders by default."
	| name |
	name := self class codeFontName.
	name ifNil: [ ^ self ].
	aBrEditor editor text fontName: name.
	aBrEditor editor text defaultFontName: name
]

{ #category : 'parinfer' }
ZealBrowser >> applyFormat: zealEditor [
	"Apply full format — normalize indentation + parinfer"
	| currentText result cursorPos |
	currentText := zealEditor editor text asString.
	currentText isEmpty ifTrue: [ ^ self ].
	result := ZealParinfer format: currentText.
	result = currentText ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	zealEditor text: ((self themeClass highlight: result)).
	zealEditor editor navigator
		moveTo: (cursorPos min: result size);
		apply
]

{ #category : 'parinfer' }
ZealBrowser >> applyParinfer: zealEditor [
	"Apply parinfer indent mode — pure Smalltalk, instant"

	| currentText result cursorPos |
	currentText := zealEditor editor text asString.
	currentText isEmpty ifTrue: [ ^ self ].
	result := ZealParinfer indentMode: currentText.
	result = currentText ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	zealEditor text: ((self themeClass highlight: result)).
	zealEditor editor navigator
		moveTo: (cursorPos min: result size);
		apply
]

{ #category : 'parinfer' }
ZealBrowser >> barfForward: zealEditor [
	"Barf: push last expression out of the current form"
	| text cursorPos result |
	text := zealEditor editor text asString.
	text isEmpty ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	result := ZealParinfer barfForward: text at: cursorPos.
	result = text ifTrue: [ ^ self ].
	zealEditor text: ((self themeClass highlight: result)).
	zealEditor editor navigator moveTo: (cursorPos min: result size); apply
]

{ #category : 'cards' }
ZealBrowser >> buildDefinitionCardFor: zealFormSource inFile: aFileRef expanded: startExpanded [
	"Build one card. Tracks both #originalName and #originalSource so a rename
	 (different name on save) can preserve the original card unchanged while
	 the user's edit becomes a new appended card."
	| card headerRow contentHolder arrow label sig isExpanded toggleBlock cardRec |
	sig := self signatureFor: zealFormSource.
	cardRec := Dictionary new
		at: #source put: zealFormSource;
		at: #editor put: nil;
		at: #file put: aFileRef;
		at: #originalName put: (self nameOfForm: zealFormSource);
		at: #originalSource put: zealFormSource;
		yourself.
	cards add: cardRec.

	card := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4 left: 0 bottom: 4 right: 0);
		background: ZealTheme backgroundColor lighter.
	contentHolder := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		visibility: (startExpanded ifTrue: [ BlVisibility visible ] ifFalse: [ BlVisibility gone ]);
		padding: (BlInsets all: 8).
	cardRec at: #contentHolder put: contentHolder.
	isExpanded := startExpanded.

	headerRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		background: ZealTheme backgroundColor darker.
	headerRow addChild: (self buildMinusButton: [ self removeCard: cardRec ]).
	arrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme parenColor; fontSize: 11);
		text: (startExpanded ifTrue: [ '▼' ] ifFalse: [ '▶' ]);
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 8).
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 13; bold);
		text: sig.
	headerRow addChild: arrow.
	headerRow addChild: label.

	toggleBlock := [
		isExpanded := isExpanded not.
		arrow text: (isExpanded
			ifTrue: [ ('▼' asRopedText foreground: ZealTheme parenColor) ]
			ifFalse: [ ('▶' asRopedText foreground: ZealTheme parenColor) ]).
		contentHolder visibility: (isExpanded ifTrue: [ BlVisibility visible ] ifFalse: [ BlVisibility gone ]).
		isExpanded ifTrue: [
			contentHolder children isEmpty ifTrue: [
				self fillCardContent: contentHolder card: cardRec forFile: aFileRef ] ] ].
	headerRow addEventHandlerOn: BlClickEvent do: [ :e | toggleBlock value ].

	card addChild: headerRow.
	card addChild: contentHolder.
	detailElement addChild: card.

	startExpanded ifTrue: [ self fillCardContent: contentHolder card: cardRec forFile: aFileRef ]
]

{ #category : 'cards' }
ZealBrowser >> buildDetail [
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

{ #category : 'ui' }
ZealBrowser >> buildDivider [
	^ BlElement new 
		background: (Color fromHexString: '444444');
		constraintsDo: [:c | c horizontal matchParent. c vertical exact: 1];
		margin: (BlInsets top: 8 bottom: 8)
]

{ #category : 'file-open' }
ZealBrowser >> buildFileDefinitionsEditor: aFileRef [
	"Free-form Zeal editor at the bottom of the file detail. Each top-level
	 form parsed from its text becomes a new card (or replaces an existing
	 card with the same name) on Ctrl+S."
	| editor styler defsText savedCursor |
	defsText := fileDefsBufferText ifNil: [ '' ].
	savedCursor := fileDefsCursorPos.

	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11; bold);
		text: 'Definitions';
		margin: (BlInsets top: 16 left: 0 bottom: 4 right: 0)).
	editor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: defsText asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0).
	self applyCodeFontTo: editor.
	styler := ZealTextStyler new browser: self.
	editor editor styler: styler.
	self configureZealEditor: editor.
	editor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self addFileDefinitionsFrom: editor inFile: aFileRef ]).
	editor editor when: BrTextEditorModifiedEvent do: [ :e |
		fileDefsBufferText := editor editor text asString ].
	(savedCursor notNil and: [ defsText notEmpty ]) ifTrue: [
		[ editor editor navigator
			moveTo: (savedCursor min: defsText size);
			apply ] on: Error do: [:e | ] ].
	editor enqueueTask: (BlTaskAction new action: [
		editor editor text: (styler style: editor editor text).
		(savedCursor notNil and: [ defsText notEmpty ]) ifTrue: [
			editor editor navigator
				moveTo: (savedCursor min: defsText size);
				apply ] ]).
	detailElement addChild: editor.
	fileDefsEditor := editor
]

{ #category : 'cards' }
ZealBrowser >> buildMethodSubCardForSource: methodSrc in: aContainer card: parentCardRec index: idx [
	"Sub-card per method with header (minus button + signature) and a lazy body
	 (Zeal editor). Toggling the arrow expands/collapses the body. Tracks
	 #originalName and #originalSource so a Ctrl+S rename forks (keeps original)
	 instead of mutating it."
	| sig subCard headerRow contentHolder arrow label isExpanded toggleBlock subRec |
	sig := self signatureFor: methodSrc.

	subRec := Dictionary new
		at: #source put: methodSrc;
		at: #editor put: nil;
		at: #index put: idx;
		at: #originalName put: (self nameOfForm: methodSrc);
		at: #originalSource put: methodSrc;
		yourself.
	(parentCardRec at: #subCards) add: subRec.

	subCard := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 2 left: 8 bottom: 2 right: 0);
		background: ZealTheme backgroundColor lighter.
	contentHolder := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		visibility: BlVisibility gone;
		padding: (BlInsets all: 8).
	isExpanded := false.

	headerRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 6);
		background: ZealTheme backgroundColor darker.
	headerRow addChild: (self buildMinusButton: [ self removeMethodAt: idx in: parentCardRec ]).
	arrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme parenColor; fontSize: 11);
		text: '▶';
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 6).
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
		text: sig.
	headerRow addChild: arrow.
	headerRow addChild: label.

	toggleBlock := [
		isExpanded := isExpanded not.
		arrow text: (isExpanded
			ifTrue: [ ('▼' asRopedText foreground: ZealTheme parenColor) ]
			ifFalse: [ ('▶' asRopedText foreground: ZealTheme parenColor) ]).
		contentHolder visibility: (isExpanded ifTrue: [ BlVisibility visible ] ifFalse: [ BlVisibility gone ]).
		isExpanded ifTrue: [
			contentHolder children isEmpty ifTrue: [
				self fillMethodSubContent: contentHolder sub: subRec parent: parentCardRec ] ] ].
	headerRow addEventHandlerOn: BlClickEvent do: [ :e | toggleBlock value ].

	subCard addChild: headerRow.
	subCard addChild: contentHolder.
	aContainer addChild: subCard.
	subRec at: #headerLabel put: label.
	subRec at: #toggleBlock put: toggleBlock
]

{ #category : 'cards' }
ZealBrowser >> buildMinusButton: aBlock [
	"Themed `−` button used to delete slots/methods inline."
	| btn label |
	label := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: (Color fromHexString: 'CCCCCC'); fontSize: 13);
		text: '−'.
	btn := BlElement new
		layout: BlFrameLayout new;
		constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ];
		padding: (BlInsets top: 0 left: 5 bottom: 0 right: 5);
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 6);
		background: (Color fromHexString: '333333');
		geometry: (BlRoundedRectangleGeometry cornerRadius: 3);
		mouseCursor: BlHandCursor new;
		addChild: label.
	btn addEventHandlerOn: BlMouseEnterEvent do: [:e | btn background: (Color fromHexString: 'FF4444') ].
	btn addEventHandlerOn: BlMouseLeaveEvent do: [:e | btn background: (Color fromHexString: '333333') ].
	btn addEventHandlerOn: BlClickEvent do: [:e | e consumed: true. aBlock value ].
	^ btn
]

{ #category : 'cards' }
ZealBrowser >> buildSectionHeader: title count: count [
	"Section header (Slots / Methods) with item count."
	| labelText |
	labelText := count > 0
		ifTrue: [ title , '  (' , count printString , ')' ]
		ifFalse: [ title ].
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11; bold);
		text: labelText;
		margin: (BlInsets top: 8 left: 0 bottom: 4 right: 0)
]

{ #category : 'building' }
ZealBrowser >> buildSectionLabel: aString [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass specialFormColor; fontSize: 11);
		text: aString;
		margin: (BlInsets top: 8 bottom: 4)
]

{ #category : 'cards' }
ZealBrowser >> buildSlotItemFor: aSlotListNode [
	"Compact display of a (var/def name:type value) slot. When the user
	 omitted the type, infer it via the dialect's type inferencer hook
	 (returns nil for dialects without one)."
	| exprs head nameNode valueNode label name typeStr inferred isConst |
	exprs := aSlotListNode expressions.
	head := exprs first value value.
	isConst := head = 'def'.
	nameNode := exprs second.
	valueNode := exprs size >= 3 ifTrue: [ exprs third ] ifFalse: [ nil ].
	typeStr := nil.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		| resolved |
		resolved := ZealColonChainResolver resolve: nameNode value value.
		name := resolved at: #name.
		typeStr := resolved at: #type ]
	ifFalse: [ name := nameNode value value ].
	(typeStr isNil and: [ valueNode notNil ]) ifTrue: [
		inferred := self dialectInferType: valueNode.
		inferred ifNotNil: [ typeStr := inferred ] ].
	label := isConst ifTrue: [ 'const ' , name ] ifFalse: [ name ].
	typeStr ifNotNil: [ label := label , ' : ' , typeStr ].
	(valueNode notNil and: [ valueNode value value isString
		and: [ valueNode value value notEmpty ] ])
		ifTrue: [ label := label , ' = ' , valueNode value value ].
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
		text: label;
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 0)
]

{ #category : 'cards' }
ZealBrowser >> buildSlotItemForSource: slotSource [
	"Compact single-line representation of a slot form's source text."
	| ast |
	ast := [ ZealParser parse: slotSource ] on: Error do: [ :e | nil ].
	(ast notNil and: [ ast expressions notEmpty
		and: [ ast expressions first isKindOf: ZealListNode ] ])
		ifTrue: [ ^ self buildSlotItemFor: ast expressions first ].
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor; fontSize: 12);
		text: (slotSource lines first ifNil: [ slotSource ]);
		margin: (BlInsets top: 1 left: 12 bottom: 1 right: 0)
]

{ #category : 'cards' }
ZealBrowser >> buildSlotRowFor: slotSource index: idx card: cardRec [
	"Slot row: minus button + label. Click minus to remove this slot."
	| row labelEl |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 1 left: 12 bottom: 1 right: 0).
	row addChild: (self buildMinusButton: [ self removeSlotAt: idx in: cardRec ]).
	labelEl := self buildSlotItemForSource: slotSource.
	labelEl margin: (BlInsets top: 0 left: 0 bottom: 0 right: 0).
	row addChild: labelEl.
	^ row
]

{ #category : 'tree' }
ZealBrowser >> buildTree [
	"File-system tree backed by the dialect's file/folder node model. Each
	 row is a folder or file node; folder children expand to their populated
	 children, file children stay leaves at this level (definitions show in
	 the right-pane detail when a file is selected)."
	treeElement := BrSimpleTree new.
	treeElement
		nodeStencil: [
			BlElement new
				layout: BlLinearLayout horizontal alignCenterLeft;
				constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
				addChild: (BlElement new id: #minusHolder;
					layout: BlLinearLayout horizontal;
					constraintsDo: [:c | c horizontal fitContent. c vertical fitContent ]);
				addChild: (BlElement new id: #iconHolder;
					constraintsDo: [:c | c horizontal exact: 18. c vertical exact: 16 ]);
				addChild: (BrLabel new
					aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme foregroundColor; fontSize: 13);
					id: #name) ];
		nodeDataBinder: [ :row :node |
			row childWithId: #minusHolder ifFound: [:holder |
				holder removeChildren.
				node ~~ projectTree ifTrue: [
					holder addChild: (self buildMinusButton: [ self deleteTreeItem: node fileRef ]) ] ].
			row childWithId: #iconHolder ifFound: [:holder |
				holder removeChildren.
				holder addChild: (self iconElementForFile: node fileRef) ].
			row childWithId: #name ifFound: [:lbl |
				lbl text: (node name asRopedText foreground: ZealTheme foregroundColor) ] ];
		items: { projectTree } lazy: [ :node |
			node isFolder ifTrue: [ node children ] ifFalse: [ #() ] ];
		when: BrSelectionChanged do: [:event |
			event indices ifNotEmpty: [:indices |
				treeElement selectedNodeDo: [:treeNode |
					| node |
					node := treeNode value.
					(node notNil and: [ node isFile ]) ifTrue: [ self openFile: node fileRef ] ] ] ].
	treeElement background: ZealTheme backgroundColor lighter.
	treeElement padding: (BlInsets all: 8).
	treeElement constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	^ treeElement
]

{ #category : 'tree' }
ZealBrowser >> buildTreeAddBar [
	"Top of the file tree: a `Files` label with a `+` button that toggles a
	 small inline form. The form is just `[path] [Add]` — file vs folder is
	 inferred from the input: extension → file, no extension → folder, slashes →
	 nested folders + final segment.
	 Input text and form visibility are preserved across Add clicks so the user
	 can keep typing entries."
	| bar plusBtn form nameField addBtn |
	bar := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 4);
		background: ZealTheme backgroundColor darker.

	form := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		visibility: BlVisibility gone;
		padding: (BlInsets top: 4 left: 0 bottom: 0 right: 0).

	nameField := BrEditor new
		aptitude: BrGlamorousRegularEditorAptitude new;
		text: '' asRopedText;
		background: ZealTheme backgroundColor lighter;
		constraintsDo: [:c | c horizontal exact: 220. c vertical fitContent ];
		padding: (BlInsets top: 2 left: 6 bottom: 2 right: 6);
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 6).

	addBtn := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude new;
		label: 'Add';
		beSmallSize;
		action: [
			| name |
			name := nameField editor text asString trimBoth.
			name isEmpty ifFalse: [ self createTreeItemAtPath: name ] ].

	form addChild: nameField.
	form addChild: addBtn.

	plusBtn := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude new;
		label: '+';
		beSmallSize;
		action: [
			form visibility: (form visibility = BlVisibility visible
				ifTrue: [ BlVisibility gone ] ifFalse: [ BlVisibility visible ]) ].

	bar addChild: (BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
			text: 'Files');
		addChild: (BlElement new
			constraintsDo: [:c | c horizontal matchParent. c vertical exact: 1 ]);
		addChild: plusBtn).
	bar addChild: form.
	^ bar
]

{ #category : 'building' }
ZealBrowser >> buildUI [
	"Top bar (title) + horizontal split: file tree (with + add bar) | detail pane."
	| leftPane topBar content mainLayout |
	self removeChildren.

	topBar := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		background: ZealTheme backgroundColor darker;
		padding: (BlInsets all: 6).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 14; bold);
		text: self dialectTitle , ' // ' , project name;
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 12)).

	content := BlElement new
		layout: BlLinearLayout horizontal;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].

	leftPane := BlElement new
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal exact: 300. c vertical matchParent ];
		background: ZealTheme backgroundColor lighter.
	leftPane addChild: self buildTreeAddBar.
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
ZealBrowser >> configureZealEditor: anEditor [
	"Set up shared features on any Zeal code editor.
	 Ctrl+Shift+Up/Down → swap the s-expression element at cursor with its
	 previous/next sibling. Cursor stays at the same offset within the moved form.
	 Default BrEditor selection-extend bindings on those keys are removed first."
	self setupParinfer: anEditor.
	self setupKeyChords: anEditor.
	self setupArrowKeys: anEditor.
	self setupFormHighlight: anEditor.
	self setupLambdaAutoReplace: anEditor.

	"Strip any default shortcut on Ctrl+Shift+ArrowUp / ArrowDown (selection-extend
	 by line/paragraph). Match by combination string regardless of token order."
	anEditor shortcuts copy do: [:s |
		| name |
		name := s combination asString asLowercase.
		((name includesSubstring: 'control') or: [ name includesSubstring: 'ctrl' ]) ifTrue: [
			(name includesSubstring: 'shift') ifTrue: [
				((name includesSubstring: 'arrowup') or: [ name includesSubstring: 'arrowdown' ])
					ifTrue: [ anEditor removeShortcut: s ] ] ] ].

	anEditor addShortcut: (BlShortcutWithAction new
		combination: (BlKeyCombination builder control shift arrowUp build);
		action: [ self swapForm: anEditor up: true ]).
	anEditor addShortcut: (BlShortcutWithAction new
		combination: (BlKeyCombination builder control shift arrowDown build);
		action: [ self swapForm: anEditor up: false ])
]

{ #category : 'tree' }
ZealBrowser >> createTreeItem: aName asFolder: isFolder [
	"Create a new file or folder under the currently-selected folder (or
	 project root if no folder is selected). For files, append the dialect's
	 target extension if missing. New files start as a stub with one
	 `(def name 0)` so the user has something to edit. Refreshes the tree."
	| parentDir target ext finalName |
	parentDir := self currentFolderTarget.
	finalName := aName.
	isFolder
		ifTrue: [
			target := parentDir / finalName.
			target ensureCreateDirectory ]
		ifFalse: [
			ext := (finalName indexOf: $.) > 0
				ifTrue: [ finalName ]
				ifFalse: [ finalName , self dialectTargetExtension ].
			target := parentDir / ext.
			[ target writeStreamDo: [ :ws |
				ws nextPutAll: '// @zeal'; nextPutAll: String lf;
					nextPutAll: '// (def '; nextPutAll: (finalName copyUpTo: $.); nextPutAll: ' 0)'; nextPutAll: String lf;
					nextPutAll: '// @end'; nextPutAll: String lf;
					nextPutAll: 'const auto '; nextPutAll: (finalName copyUpTo: $.); nextPutAll: ' = 0;'; nextPutAll: String lf ] ]
				on: Error do: [ :e | ] ].
	self refreshTree
]

{ #category : 'tree' }
ZealBrowser >> createTreeItemAtPath: aPathString [
	"Create a file or nested folder hierarchy from a `/`-separated path,
	 ALWAYS rooted at the project's root folder so repeated clicks are
	 idempotent. `kek/lawl/poo.zeal` → mkdir kek/, kek/lawl/, then create
	 kek/lawl/poo.<targetExt>. `.zeal` is a marker meaning 'file' — translated
	 to the dialect's target extension on disk. If the final target already
	 exists, this is a no-op."
	| segments parent lastIdx lastSeg target targetExt |
	segments := ($/ split: aPathString) reject: [ :s | s isEmpty ].
	segments isEmpty ifTrue: [ ^ self ].
	parent := project rootFolder.
	lastIdx := segments size.
	1 to: lastIdx - 1 do: [ :i |
		parent := parent / (segments at: i).
		parent exists ifFalse: [ parent ensureCreateDirectory ] ].
	lastSeg := segments last.
	(self pathSegmentLooksLikeFile: lastSeg) ifTrue: [
		(lastSeg asLowercase endsWith: '.zeal') ifTrue: [
			targetExt := self dialectTargetExtension.
			lastSeg := (lastSeg copyFrom: 1 to: lastSeg size - 5) , targetExt ].
		target := parent / lastSeg.
		target exists ifFalse: [ self ensureFileAt: target ] ]
	ifFalse: [
		target := parent / lastSeg.
		target exists ifFalse: [ target ensureCreateDirectory ] ].
	self refreshTreeOnly
]

{ #category : 'tree' }
ZealBrowser >> currentFolderTarget [
	"Return the folder where new files/folders should land. Reads selection
	 from the tree (a folder or file node from any dialect); falls back to
	 project rootFolder."
	| selected |
	selected := nil.
	(treeElement notNil and: [
		treeElement selectedNodeDo: [ :n | selected := n value ] ]).
	selected isNil ifTrue: [ ^ project rootFolder ].
	((selected respondsTo: #isFolder) and: [ selected isFolder ]) ifTrue: [ ^ selected fileRef ].
	((selected respondsTo: #isFile) and: [ selected isFile ]) ifTrue: [ ^ selected fileRef parent ].
	(selected isKindOf: FileReference) ifTrue: [
		selected isDirectory ifTrue: [ ^ selected ].
		^ selected parent ].
	^ project rootFolder
]

{ #category : 'parinfer' }
ZealBrowser >> cutOrRemoveLine: zealEditor [
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

{ #category : 'parinfer' }
ZealBrowser >> deindentLine: zealEditor [
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
		text: ((self themeClass highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (cursorPos - 2 max: 0);
		apply
]

{ #category : 'tree' }
ZealBrowser >> deleteTreeItem: aFileRef [
	"Delete a file or folder (recursively for folders). Detail pane is cleared
	 if the open file is being deleted. Refreshes only the tree element so
	 expansion state and the add-form state are preserved."
	(currentFile notNil and: [
		currentFile = aFileRef
			or: [ aFileRef isDirectory and: [ currentFile fullName beginsWith: aFileRef fullName ] ] ])
		ifTrue: [ currentFile := nil. detailElement removeChildren ].
	[ aFileRef isDirectory
		ifTrue: [ aFileRef deleteAll ]
		ifFalse: [ aFileRef delete ] ]
		on: Error do: [ :e | ].
	self refreshTreeOnly
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectCompiler [
	"Returns the compiler class for this dialect (e.g. AngelZealCompiler).
	 Subclasses must override."
	self subclassResponsibility
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectDefinitionNodeClass [
	"Returns the definition-node class for compiled-definition pager pages
	 (e.g. AngelZealDefinitionNode). Subclasses must override."
	self subclassResponsibility
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectFileNodeClass [
	"Returns the file-node class used in the project tree (e.g.
	 AngelZealFileNode). Subclasses must override."
	self subclassResponsibility
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectInferType: aNode [
	"Returns an inferred type string for an AST node, or nil if the dialect
	 has no inferencer. Default: nil. Subclasses with inferencers override."
	^ nil
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectProjectClass [
	"Returns the project class for this dialect (e.g. AngelZealProject).
	 Subclasses must override."
	self subclassResponsibility
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectTargetExtension [
	"Returns the on-disk file extension for this dialect's target language
	 (e.g. '.as' for Angel, '.gd' for GDScript). Subclasses must override."
	self subclassResponsibility
]

{ #category : 'dialect-hooks' }
ZealBrowser >> dialectTargetLabel [
	"Returns the human-readable name for this dialect's target language
	 (e.g. 'AngelScript', 'GDScript'). Subclasses must override."
	self subclassResponsibility
]

{ #category : 'building' }
ZealBrowser >> dialectTitle [
	"Default UI title prefix derived from the class name (e.g.
	 AngelZealBrowser → 'AngelZeal'). Subclasses may override for a different
	 display."
	| n |
	n := self class name asString.
	^ (n endsWith: 'Browser')
		ifTrue: [ n copyFrom: 1 to: n size - 'Browser' size ]
		ifFalse: [ n ]
]

{ #category : 'api' }
ZealBrowser >> displayNameForFile: aFileRef [
	"Tree-row label for a file reference. Folders use their basename; files
	 hide their extension so a *.as / *.zeal file shows as just `Plain`.
	 Shared across every Zeal dialect's file-tree browser."
	aFileRef isDirectory ifTrue: [ ^ aFileRef basename ].
	^ aFileRef basenameWithoutExtension
]

{ #category : 'editor' }
ZealBrowser >> duplicateLine: zealEditor [
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
		text: (self themeClass highlight: (String lf join: lines)).
	zealEditor editor navigator
		moveTo: (newCursorPos min: zealEditor editor text size);
		apply
]

{ #category : 'pager' }
ZealBrowser >> enclosingPager [
	"Walk up parent chain from detailElement looking for a BrPager (GtPager
	 inherits). Returns nil if not embedded in a pager."
	detailElement ifNil: [ ^ nil ].
	^ detailElement
		allParentsDetect: [ :p | p isKindOf: BrPager ]
		ifFound: [ :p | p ]
		ifNone: [ nil ]
]

{ #category : 'pager' }
ZealBrowser >> enclosingPagerPage [
	"Return the GtPagerWrapperElement whose viewModel is the browser's page in
	 the enclosing pager. Used to spawn replacement pages relative to the
	 current page (instead of always appending to the end)."
	detailElement ifNil: [ ^ nil ].
	^ detailElement
		allParentsDetect: [ :p | p class name = #GtPagerWrapperElement ]
		ifFound: [ :p | p ]
		ifNone: [ nil ]
]

{ #category : 'tree' }
ZealBrowser >> ensureFileAt: aFileRef [
	"Create aFileRef on disk if it doesn't exist. The file is empty — the
	 user adds definitions through the file's Definitions box."
	aFileRef exists ifTrue: [ ^ self ].
	[ aFileRef writeStreamDo: [ :ws | ] ] on: Error do: [ :e | ]
]

{ #category : 'cards' }
ZealBrowser >> expandMultiBindings: forms [
	"Pre-process forms — `(def n1 v1 n2 v2 …)` → multiple `(def n v)`, same for var.
	 Forms with one or zero bindings pass through unchanged.
	 (def n1 v1 … nK vK) parses to [head, n1, v1, …, nK, vK] which has size 1+2K.
	 So multi-binding ⇔ size is odd AND ≥ 5."
	| out |
	out := OrderedCollection new.
	forms do: [ :formSrc |
		| ast top exprs head bindings |
		ast := [ ZealParser parse: formSrc ] on: Error do: [ :e | nil ].
		bindings := nil.
		(ast notNil and: [ ast expressions notEmpty ]) ifTrue: [
			top := ast expressions first.
			(top isKindOf: ZealListNode) ifTrue: [
				exprs := top expressions.
				(exprs notEmpty and: [ exprs first isKindOf: ZealSymbolNode ]) ifTrue: [
					head := exprs first value value.
					((head = 'var' or: [ head = 'def' ])
						and: [ exprs size >= 5 and: [ exprs size odd ] ])
						ifTrue: [
							bindings := OrderedCollection new.
							2 to: exprs size by: 2 do: [ :i |
								| nameSrc valSrc |
								nameSrc := (exprs at: i) value value.
								valSrc := i + 1 <= exprs size
									ifTrue: [ (exprs at: i + 1) value value ]
									ifFalse: [ '' ].
								bindings add: '(' , head , ' ' , nameSrc , ' ' , valSrc , ')' ] ] ] ] ].
		bindings isNil
			ifTrue: [ out add: formSrc ]
			ifFalse: [ out addAll: bindings ] ].
	^ out
]

{ #category : 'editor' }
ZealBrowser >> expandSelection: zealEditor [
	"Ctrl+W: expand selection outward through structural units.
	 - Cursor outside a form (before opener or after closer): select full form WITH parens
	 - Cursor inside near delimiter (after opener or before closer): select inner content
	 - Cursor on a word: select that word, then expand outward on subsequent presses"
	| text cursorPos ranges currentSelStart currentSelEnd currentSize nextRange outsideForm |
	text := zealEditor editor text asString.
	text isEmpty ifTrue: [ ^ self ].
	cursorPos := 0.
	zealEditor editor cursors do: [ :c | cursorPos := c position ].
	currentSelStart := cursorPos.
	currentSelEnd := cursorPos.
	zealEditor editor selection do: [ :sel |
		currentSelStart := sel from min: currentSelEnd.
		currentSelEnd := sel to max: currentSelStart ].
	currentSize := currentSelEnd - currentSelStart.
	ranges := ZealParinfer structuralRangesAt: cursorPos in: text.
	"Detect: is the cursor OUTSIDE a form (before an opener or after a closer)?
	 In that case, first Ctrl+W should select the entire form including parens."
	outsideForm := false.
	(cursorPos >= 1 and: [ cursorPos <= text size ]) ifTrue: [
		| ch | ch := text at: cursorPos.
		"Char before cursor is a closer → cursor is after ), outside"
		(ch = $) or: [ ch = $] or: [ ch = $} ] ]) ifTrue: [ outsideForm := true ] ].
	(cursorPos + 1 <= text size) ifTrue: [
		| ch | ch := text at: cursorPos + 1.
		"Char after cursor is an opener → cursor is before (, outside"
		(ch = $( or: [ ch = $[ or: [ ch = ${ ] ]) ifTrue: [ outsideForm := true ] ].
	nextRange := nil.
	(outsideForm and: [ currentSize = 0 ])
		ifTrue: [
			"Select the full form (range that starts with opener and ends with closer)"
			nextRange := ranges detect: [ :r |
				| startCh endCh isForm |
				startCh := (r key + 1 between: 1 and: text size) ifTrue: [ text at: r key + 1 ] ifFalse: [ nil ].
				endCh := (r value between: 1 and: text size) ifTrue: [ text at: r value ] ifFalse: [ nil ].
				isForm := (startCh = $( and: [ endCh = $) ])
					or: [ (startCh = $[ and: [ endCh = $] ])
					or: [ startCh = ${ and: [ endCh = $} ] ] ].
				isForm and: [ (r value - r key) > currentSize ] ] ifNone: [ nil ] ]
		ifFalse: [
			"Default: select next larger range (word → inner content → full form)"
			nextRange := ranges
				detect: [ :r | (r value - r key) > currentSize ]
				ifNone: [ nil ] ].
	nextRange ifNil: [ ^ self ].
	zealEditor editor deselecter all deselect.
	zealEditor editor selecter
		from: nextRange key to: nextRange value;
		select.
	expandSelectionStack ifNil: [ expandSelectionStack := OrderedCollection new ].
	expandSelectionStack add: (currentSelStart -> currentSelEnd)
]

{ #category : 'cards' }
ZealBrowser >> fillCardContent: contentHolder card: cardRec forFile: aFileRef [
	"Populate a card body. Defclass forms get a class-browser-style detail
	 view (slots + per-method sub-cards). Everything else gets the simple
	 Zeal editor + pager-page-on-save flow."
	(self isDefclassSource: (cardRec at: #source))
		ifTrue: [ ^ self fillClassCardContent: contentHolder card: cardRec forFile: aFileRef ].
	^ self fillSimpleCardContent: contentHolder card: cardRec forFile: aFileRef
]

{ #category : 'cards' }
ZealBrowser >> fillClassCardContent: contentHolder card: cardRec forFile: aFileRef [
	"Class-browser-style detail. Bottom 'Definitions' editor preserves both
	 its text (cardRec[#defsBufferText]) and cursor position
	 (cardRec[#defsCursorPos]) across rebuilds."
	| classSource className parent slots methods bodyForms innerStart innerEnd ast classExprs nameNode defsEditor styler defsText savedCursor |
	contentHolder removeChildren.
	cardRec at: #contentHolder put: contentHolder.
	classSource := cardRec at: #source.

	className := nil. parent := nil.
	ast := [ ZealParser parse: classSource ] on: Error do: [ :e | nil ].
	(ast notNil and: [ ast expressions notEmpty ]) ifTrue: [
		classExprs := ast expressions first expressions.
		classExprs size >= 2 ifTrue: [
			nameNode := classExprs second.
			(nameNode isKindOf: ZealColonChainNode)
				ifTrue: [
					| resolved |
					resolved := ZealColonChainResolver resolve: nameNode value value.
					className := resolved at: #name.
					parent := resolved at: #type ]
				ifFalse: [ className := nameNode value value ] ] ].
	className ifNil: [ className := '?' ].
	cardRec at: #className put: className.
	cardRec at: #classParent put: parent.

	contentHolder addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme classRefColor; fontSize: 16; bold);
		text: 'class ' , className , (parent ifNotNil: [ ' : ' , parent ] ifNil: [ '' ]);
		margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0)).

	slots := cardRec at: #slotSources ifAbsent: [ nil ].
	slots ifNil: [
		innerStart := (classSource indexOf: $() + 1.
		innerEnd := classSource size - 1.
		bodyForms := self splitTopLevelForms: (classSource copyFrom: innerStart to: innerEnd).
		slots := OrderedCollection new.
		methods := OrderedCollection new.
		bodyForms do: [ :formSrc |
			| trimmed |
			trimmed := formSrc trimBoth.
			(trimmed beginsWith: '(defn') ifTrue: [ methods add: formSrc ]
			ifFalse: [
				((trimmed beginsWith: '(var') or: [ trimmed beginsWith: '(def ' ])
					ifTrue: [ slots add: formSrc ] ] ].
		cardRec at: #slotSources put: slots.
		cardRec at: #methodSources put: methods ]
	ifNotNil: [ methods := cardRec at: #methodSources ifAbsent: [ OrderedCollection new ] ].

	cardRec at: #subCards put: OrderedCollection new.

	contentHolder addChild: (self buildSectionHeader: 'Slots' count: slots size).
	slots doWithIndex: [ :slot :idx |
		contentHolder addChild: (self buildSlotRowFor: slot index: idx card: cardRec) ].

	contentHolder addChild: (self buildSectionHeader: 'Methods' count: methods size).
	methods doWithIndex: [ :methodSrc :idx |
		self buildMethodSubCardForSource: methodSrc in: contentHolder card: cardRec index: idx ].

	contentHolder addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11; bold);
		text: 'Definitions';
		margin: (BlInsets top: 16 left: 0 bottom: 4 right: 0)).
	defsText := cardRec at: #defsBufferText ifAbsent: [ '' ].
	savedCursor := cardRec at: #defsCursorPos ifAbsent: [ nil ].
	defsEditor := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: defsText asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0).
	self applyCodeFontTo: defsEditor.
	styler := ZealTextStyler new browser: self.
	defsEditor editor styler: styler.
	self configureZealEditor: defsEditor.
	defsEditor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self addDefinitionsFrom: defsEditor toCard: cardRec ]).
	defsEditor editor when: BrTextEditorModifiedEvent do: [ :e |
		cardRec at: #defsBufferText put: defsEditor editor text asString ].
	(savedCursor notNil and: [ defsText notEmpty ]) ifTrue: [
		[ defsEditor editor navigator
			moveTo: (savedCursor min: defsText size);
			apply ] on: Error do: [:e | ] ].
	defsEditor enqueueTask: (BlTaskAction new action: [
		defsEditor editor text: (styler style: defsEditor editor text).
		(savedCursor notNil and: [ defsText notEmpty ]) ifTrue: [
			defsEditor editor navigator
				moveTo: (savedCursor min: defsText size);
				apply ] ]).
	contentHolder addChild: defsEditor.
	cardRec at: #defsEditor put: defsEditor
]

{ #category : 'cards' }
ZealBrowser >> fillMethodSubContent: contentHolder sub: subRec parent: parentCardRec [
	"Editable Zeal editor for one method inside a class card. Ctrl+S syncs the
	 method back into the parent class source, saves the file, and pushes a
	 compiled-method definition node into the enclosing pager — matching the
	 top-level card flow. No live target preview; target appears in the pager page."
	| ed styler methodSrc |
	methodSrc := subRec at: #source.

	contentHolder addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets bottom: 4)).
	ed := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: methodSrc asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8).
	self applyCodeFontTo: ed.
	styler := ZealTextStyler new browser: self.
	ed editor styler: styler.
	self configureZealEditor: ed.
	ed addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self saveAndRefreshMethodSub: subRec parent: parentCardRec ]).
	contentHolder addChild: ed.
	subRec at: #editor put: ed.
	ed enqueueTask: (BlTaskAction new action: [
		ed editor text: (styler style: ed editor text) ])
]

{ #category : 'cards' }
ZealBrowser >> fillSimpleCardContent: contentHolder card: cardRec forFile: aFileRef [
	"Card body: editable Zeal source. Ctrl+S compiles, saves the file, and
	 pushes the resulting definition node into the enclosing pager as a new
	 page (its gtViews provide Zeal/target tabs)."
	| ed styler zealSource |
	zealSource := cardRec at: #source.
	contentHolder removeChildren.

	contentHolder addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets top: 0 left: 0 bottom: 4 right: 0)).
	ed := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: zealSource asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0).
	self applyCodeFontTo: ed.
	styler := ZealTextStyler new browser: self.
	ed editor styler: styler.
	self configureZealEditor: ed.
	ed addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self saveAndRefreshCard: cardRec ]).
	contentHolder addChild: ed.
	cardRec at: #editor put: ed.
	ed enqueueTask: (BlTaskAction new action: [
		ed editor text: (styler style: ed editor text) ])
]

{ #category : 'pager' }
ZealBrowser >> findDefinitionNodeNamed: aName inFile: aFileRef [
	"Look up the dialect's definition node for the just-saved form. Falls
	 back to a freshly-built node if the project tree doesn't yet contain it."
	| fileNode source sections sect |
	aName ifNil: [ ^ nil ].
	fileNode := self findFileNodeFor: aFileRef.
	fileNode ifNotNil: [
		fileNode children do: [ :defNode |
			defNode name = aName ifTrue: [ ^ defNode ] ] ].
	source := [ aFileRef contents ] on: Error do: [ :e | ^ nil ].
	sections := self dialectCompiler parseSections: source.
	sect := sections detect: [ :s |
		(self nameOfForm: (s at: #zealSource)) = aName ] ifNone: [ nil ].
	sect ifNil: [ ^ nil ].
	^ self dialectDefinitionNodeClass fromSection: sect
]

{ #category : 'tree' }
ZealBrowser >> findFileNodeFor: aFileRef [
	"DFS the projectTree for a file node whose fileRef matches aFileRef.
	 Returns nil if none."
	| stack |
	projectTree ifNil: [ ^ nil ].
	stack := OrderedCollection new.
	stack add: projectTree.
	[ stack notEmpty ] whileTrue: [
		| n |
		n := stack removeLast.
		(n isFile and: [ n fileRef fullName = aFileRef fullName ]) ifTrue: [ ^ n ].
		n isFolder ifTrue: [ stack addAll: n children ] ].
	^ nil
]

{ #category : 'ui' }
ZealBrowser >> flashEditor: anEditor color: aColor [
	"Flash the editor border and background briefly"
	| originalBorder originalBg |
	originalBorder := anEditor border copy.
	originalBg := anEditor background copy.
	anEditor border: (BlBorder paint: aColor width: 2).
	anEditor background: aColor.
	[ (Delay forMilliseconds: 400) wait.
	  [ anEditor border: originalBorder. anEditor background: originalBg ] on: Error do: [] ] fork
]

{ #category : 'actions' }
ZealBrowser >> flashError: anEditor [
	"Flash editor with error color (red glow)"
	self flashEditor: anEditor color: (Color red alpha: 0.3)
]

{ #category : 'actions' }
ZealBrowser >> flashSuccess: anEditor [
	"Flash editor with success color (cyan glow)"
	self flashEditor: anEditor color: (self themeClass cursorColor alpha: 0.2)
]

{ #category : 'pager' }
ZealBrowser >> flashSuccessOnCardNamed: aName [
	"After a rebuild, find the card whose name matches aName and flash its
	 (newly-built) editor. The card may not have an editor yet if it isn't
	 expanded — in that case there's nothing visible to flash, so we no-op."
	| match ed |
	aName ifNil: [ ^ self ].
	match := cards detect: [ :rec | (self nameOfForm: (rec at: #source)) = aName ]
		ifNone: [ nil ].
	match ifNil: [ ^ self ].
	ed := match at: #editor ifAbsent: [ nil ].
	ed ifNotNil: [ self flashSuccess: ed ]
]

{ #category : 'tree' }
ZealBrowser >> iconElementForFile: aFileRef [
	"Simple colored square to distinguish folder / .zeal-marker / target file."
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

{ #category : 'editor' }
ZealBrowser >> indentLine: zealEditor [
	"Tab: cycle through valid indentation levels for the current line.
	 Levels include: flush left, line-above indent, opener+1 (Lisp-1),
	 and first-arg alignment. Each press advances to the next level."
	| text cursorPos lines lineIndex charCount currentIndent levels nextIndent delta colInLine |
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
	currentIndent := ZealParinfer indentOf: (lines at: lineIndex).
	levels := ZealParinfer indentLevels: text forLine: lineIndex.
	"Find the next level strictly greater than current. If none, wrap to first."
	nextIndent := levels detect: [ :lv | lv > currentIndent ] ifNone: [ levels first ].
	nextIndent = currentIndent ifTrue: [ ^ self ].
	"Apply the new indent"
	delta := nextIndent - currentIndent.
	delta > 0
		ifTrue: [
			lines at: lineIndex put: (String new: delta withAll: $ ) , (lines at: lineIndex) ]
		ifFalse: [
			| line trimCount |
			line := lines at: lineIndex.
			trimCount := delta abs min: (ZealParinfer indentOf: line).
			lines at: lineIndex put: (line allButFirst: trimCount) ].
	zealEditor
		text: (self themeClass highlight: (String lf join: lines)).
	zealEditor editor navigator
		moveTo: (cursorPos + delta min: zealEditor editor text size max: 0);
		apply
]

{ #category : 'initialization' }
ZealBrowser >> initialize [
	super initialize.
	self layout: BlLinearLayout vertical.
	self constraintsDo: [ :c | c horizontal matchParent. c vertical matchParent ].
	self background: self themeClass backgroundColor
]

{ #category : 'cards' }
ZealBrowser >> isDefclassSource: aString [
	"True if aString starts (after whitespace) with `(defclass`."
	| trimmed |
	trimmed := aString trimBoth.
	^ (trimmed beginsWith: '(defclass')
		and: [ trimmed size > 9 and: [ '( ' includes: (trimmed at: 10) ] ]
]

{ #category : 'parinfer' }
ZealBrowser >> moveCursorToSelectionEdge: zealEditor left: isLeft [
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

{ #category : 'cards' }
ZealBrowser >> nameOfForm: aFormSource [
	"Return the bare name (kebab-case, no type/specifiers) of a top-level form
	 like (var x:int 5), (def Pi 3.14), or (defn foo:int [...]). Returns nil
	 if the form has no second-element name."
	| ast top exprs nameNode |
	ast := [ ZealParser parse: aFormSource ] on: Error do: [ :e | ^ nil ].
	(ast notNil and: [ ast expressions notEmpty ]) ifFalse: [ ^ nil ].
	top := ast expressions first.
	(top isKindOf: ZealListNode) ifFalse: [ ^ nil ].
	exprs := top expressions.
	exprs size < 2 ifTrue: [ ^ nil ].
	nameNode := exprs second.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		^ (ZealColonChainResolver resolve: nameNode value value) at: #name ].
	(nameNode isKindOf: ZealSymbolNode) ifTrue: [ ^ nameNode value value ].
	^ nil
]

{ #category : 'file-open' }
ZealBrowser >> openFile: aFileRef [
	"Convenience entry point that doesn't request a specific card to expand."
	^ self openFile: aFileRef expandName: nil
]

{ #category : 'file-open' }
ZealBrowser >> openFile: aFileRef expandName: aNameOrNil [
	"Load a file into the detail pane. Looks up the corresponding file node
	 in projectTree and uses its pre-built definition nodes (carrying
	 metadata) when available. Falls back to fresh parsing for just-created
	 files not yet in the tree, then to dialect auto-conversion of the raw
	 target source when no @zeal headers are present."
	| header zealSources fileNode source sections expandIdx |
	currentFile := aFileRef.
	detailElement removeChildren.

	header := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0).
	header addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 16; bold);
		text: (self displayNameForFile: aFileRef)).
	detailElement addChild: header.

	fileNode := self findFileNodeFor: aFileRef.
	(fileNode notNil and: [ fileNode children notEmpty ])
		ifTrue: [
			zealSources := fileNode children collect: [ :defNode | defNode zealSource ] ]
		ifFalse: [
			source := [ aFileRef contents ] on: Error do: [ :e | 'Error reading file: ' , e messageText ].
			sections := self dialectCompiler parseSections: source.
			zealSources := sections notEmpty
				ifTrue: [ sections collect: [ :s | s at: #zealSource ] ]
				ifFalse: [
					(source trimBoth notEmpty) ifTrue: [
						detailElement addChild: (BrLabel new
							aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
							text: 'No @zeal headers found — auto-converting ' , self dialectTargetLabel , ' to Zeal. Save (Ctrl+S) to commit headers.';
							margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0)).
						self dialectCompiler convertFile: source ]
					ifFalse: [ #() ] ] ].

	expandIdx := nil.
	aNameOrNil ifNotNil: [
		zealSources doWithIndex: [ :zealSrc :i |
			expandIdx ifNil: [
				(self nameOfForm: zealSrc) = aNameOrNil
					ifTrue: [ expandIdx := i ] ] ] ].
	(expandIdx isNil and: [ zealSources notEmpty ]) ifTrue: [ expandIdx := 1 ].

	cards := OrderedCollection new.
	zealSources doWithIndex: [ :zealSrc :idx |
		self buildDefinitionCardFor: zealSrc inFile: aFileRef expanded: (idx = expandIdx) ].

	self buildFileDefinitionsEditor: aFileRef
]

{ #category : 'cards' }
ZealBrowser >> paramsLabelFor: aDefnList [
	"Return a curry chain of the function's signature using the real Unicode
	 arrow `→` (U+2192): `p1:T1 → p2:T2 → ... → retType`. The leading λ and
	 the function name are added by signatureFor: — this only emits the chain."
	| exprs paramVec params nameNode retType segments arrow |
	exprs := aDefnList expressions.
	paramVec := exprs detect: [ :e | e isKindOf: ZealVectorNode ] ifNone: [ nil ].
	params := paramVec
		ifNotNil: [ paramVec expressions collect: [ :p | p value value ] ]
		ifNil: [ #() ].

	nameNode := exprs size >= 2 ifTrue: [ exprs second ] ifFalse: [ nil ].
	retType := nil.
	(nameNode notNil and: [ nameNode isKindOf: ZealColonChainNode ]) ifTrue: [
		retType := (ZealColonChainResolver resolve: nameNode value value) at: #type ].
	retType ifNil: [ retType := 'void' ].

	segments := OrderedCollection new.
	params do: [ :p | segments add: p ].
	segments add: retType.
	arrow := String with: (Character value: 16r2192).
	^ (' ' , arrow , ' ') join: segments
]

{ #category : 'tree' }
ZealBrowser >> pathSegmentLooksLikeFile: aSegment [
	"True iff aSegment contains a `.` not at position 1 — i.e., has an extension."
	^ (aSegment includes: $.) and: [ (aSegment indexOf: $.) > 1 ]
]

{ #category : 'project' }
ZealBrowser >> project: aProject [
	"Snapshot the project's tree (for filesystem-style projects rooted at a
	 folder) and build the UI. Module-style projects without a buildTree
	 just leave projectTree nil; their browsers override buildUI to render
	 something else."
	project := aProject.
	projectTree := (aProject respondsTo: #buildTree)
		ifTrue: [ aProject buildTree ]
		ifFalse: [ nil ].
	self buildUI
]

{ #category : 'pager' }
ZealBrowser >> pushCompiledMethodPageFor: methodSrc named: aName [
	"Push a one-off definition node for a method into the enclosing pager
	 (replacing any pages to the right). Methods don't live in projectTree as
	 their own nodes, so we build the node ad-hoc via the dialect's hook."
	| pager currentPage defNode targetCode inspector |
	pager := self enclosingPager.
	pager ifNil: [ ^ self ].
	targetCode := [ self dialectCompiler compileToTarget: methodSrc ]
		on: Error do: [ :e | 'Compile error: ' , e messageText ].
	defNode := self dialectDefinitionNodeClass new.
	defNode name: aName.
	defNode zealSource: methodSrc.
	defNode targetCode: targetCode.
	inspector := GtInspector forObject: defNode.
	currentPage := self enclosingPagerPage.
	currentPage ifNotNil: [ pager removePagesAfter: currentPage ].
	pager addWrapped: inspector.
	pager smoothScrollToLast
]

{ #category : 'pager' }
ZealBrowser >> pushDefinitionPageNamed: aName [
	"After a save, replace any pages to the right of this browser's page with
	 a single new inspector page on the just-compiled definition node — the
	 same flow GT's spawn: uses, so re-compiling on the left page reuses the
	 right slot instead of stacking pages forever."
	| pager currentPage defNode inspector |
	aName ifNil: [ ^ self ].
	pager := self enclosingPager.
	pager ifNil: [ ^ self ].
	defNode := self findDefinitionNodeNamed: aName inFile: currentFile.
	defNode ifNil: [ ^ self ].
	inspector := GtInspector forObject: defNode.
	currentPage := self enclosingPagerPage.
	currentPage ifNotNil: [ pager removePagesAfter: currentPage ].
	pager addWrapped: inspector.
	pager smoothScrollToLast
]

{ #category : 'cards' }
ZealBrowser >> rebuildClassSourceFor: parentCardRec [
	"Re-emit a defclass form from cardRec's tracked metadata. Pulls method
	 sources from #methodSources but prefers any sub-card editor's live text
	 (so unsaved keystrokes survive structural changes)."
	| className parent slotSources methodSources subCards methodTexts stream |
	className := parentCardRec at: #className ifAbsent: [ ^ parentCardRec at: #source ].
	parent := parentCardRec at: #classParent ifAbsent: [ nil ].
	slotSources := parentCardRec at: #slotSources ifAbsent: [ #() ].
	methodSources := parentCardRec at: #methodSources ifAbsent: [ #() ].
	subCards := parentCardRec at: #subCards ifAbsent: [ #() ].

	methodTexts := methodSources copy asOrderedCollection.
	subCards doWithIndex: [ :sub :i |
		(i <= methodTexts size) ifTrue: [ methodTexts at: i put: (sub at: #source) ] ].

	stream := WriteStream on: String new.
	stream nextPutAll: '(defclass '.
	stream nextPutAll: className.
	parent ifNotNil: [ stream nextPut: $:; nextPutAll: parent ].
	slotSources do: [ :s |
		stream nextPut: Character lf; nextPutAll: '    '; nextPutAll: s trimBoth ].
	methodTexts do: [ :s |
		stream nextPut: Character lf; nextPutAll: '    '; nextPutAll: s trimBoth ].
	stream nextPut: $).
	^ stream contents
]

{ #category : 'tree' }
ZealBrowser >> refreshFileNodeFor: aFileRef [
	"Surgical: re-parse only aFileRef's section of the tree, splicing the new
	 file node into projectTree at the same position the old one held. Falls
	 back to a full rebuild only when the folder structure required to host
	 the file doesn't exist in the tree yet (e.g. file just created in a new
	 directory)."
	projectTree ifNil: [ projectTree := project buildTree. ^ self ].
	aFileRef exists ifFalse: [
		projectTree := project buildTree.
		^ self ].
	(self spliceFileNodeFor: aFileRef into: projectTree)
		ifFalse: [ projectTree := project buildTree ]
]

{ #category : 'tree' }
ZealBrowser >> refreshTree [
	"Full UI rebuild — used as a fallback when in-place refresh isn't possible."
	| openFileRef |
	project ifNil: [ ^ self ].
	projectTree := project buildTree.
	openFileRef := currentFile.
	self buildUI.
	openFileRef ifNotNil: [ openFileRef exists ifTrue: [ self openFile: openFileRef ] ]
]

{ #category : 'tree' }
ZealBrowser >> refreshTreeOnly [
	"Replace just the tree element in-place. Rebuilds projectTree from disk
	 so the new file-system state is reflected, then re-renders the tree."
	| leftPane oldTree newTree |
	(treeElement isNil or: [ treeElement parent isNil ]) ifTrue: [ ^ self refreshTree ].
	leftPane := treeElement parent.
	projectTree := project buildTree.
	oldTree := treeElement.
	newTree := self buildTree.
	newTree constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	leftPane replaceChild: oldTree with: newTree.
	newTree enqueueTask: (BlTaskAction new action: [
		[ newTree expandAll ] on: Error do: [ :e | ] ])
]

{ #category : 'cards' }
ZealBrowser >> removeCard: cardRec [
	"Drop a card from the file: remove it from `cards`, write the file without
	 that section, and re-render. The detail pane re-renders with the next
	 card (if any) collapsed."
	| idx |
	idx := cards indexOf: cardRec ifAbsent: [ 0 ].
	idx > 0 ifTrue: [ cards removeIndex: idx ].
	self saveAllCards.
	self openFile: currentFile
]

{ #category : 'parinfer' }
ZealBrowser >> removeLine: zealEditor [
	"Remove the current line and rebalance parens"
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
	
	"Calculate cursor position: start of removed line, clamped"
	newCursorPos := 0.
	1 to: lineIndex - 1 do: [:i | newCursorPos := newCursorPos + (lines at: i) size + 1].
	
	lines removeAt: lineIndex.
	lines isEmpty ifTrue: [ 
		zealEditor text: ('' asRopedText). ^ self ].
	
	zealEditor
		text: ((self themeClass highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (newCursorPos min: zealEditor editor text size);
		apply
]

{ #category : 'cards' }
ZealBrowser >> removeMethodAt: idx in: cardRec [
	"Drop a method from a class card, re-emit the parent class source, then
	 persist to disk via saveAllCards so the @zeal block + target code for
	 that method are gone from the file."
	| methods |
	methods := cardRec at: #methodSources ifAbsent: [ ^ self ].
	(cardRec at: #subCards ifAbsent: [ #() ]) doWithIndex: [ :sub :i |
		(i <= methods size) ifTrue: [ methods at: i put: (sub at: #source) ] ].
	(idx >= 1 and: [ idx <= methods size ]) ifFalse: [ ^ self ].
	methods removeAt: idx.
	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self saveAllCards.
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file)
]

{ #category : 'cards' }
ZealBrowser >> removeSlotAt: idx in: cardRec [
	"Drop a slot from a class card, re-emit the parent class source, then
	 persist to disk."
	| slots |
	slots := cardRec at: #slotSources ifAbsent: [ ^ self ].
	(idx >= 1 and: [ idx <= slots size ]) ifFalse: [ ^ self ].
	slots removeAt: idx.
	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self saveAllCards.
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file)
]

{ #category : 'navigation' }
ZealBrowser >> resolveWord: word [
	"Resolve a word to a ZealNode — type-aware member access, then generic lookup"
	| resolver node kebab pascal snake objName methodName typeName cls methodPascal |
	resolver := ZealCompiler currentResolver ifNil: [
		project ifNotNil: [ ZealTypeResolver forProject: project ] ].
	resolver ifNil: [ ^ nil ].
	
	"Member access: obj/method"
	(word includes: $/) ifTrue: [
		objName := word copyUpToLast: $/.
		methodName := word copyAfterLast: $/.
		methodPascal := '' join: ((methodName substrings: '-') collect: [:s | s capitalized]).
		"Try type-aware: find type of obj, find method on that class"
		typeName := (ZealCompletionStrategy new project: project) findTypeOf: objName in: ''.
		typeName ifNotNil: [
			cls := resolver findClass: (typeName copyReplaceAll: '-' with: '_').
			cls ifNotNil: [
				node := resolver findMethod: methodPascal inClass: cls name.
				node ifNotNil: [ ^ node ] ] ].
		"Fallback: search project classes first, then all"
		project modules do: [:mod |
			mod definitions do: [:d |
				((d respondsTo: #methods) and: [d methods notNil]) ifTrue: [
					d methods do: [:m |
						(m name asLowercase = methodPascal asLowercase) ifTrue: [ ^ m ] ] ] ] ].
		^ resolver findMethodAnywhere: methodPascal ].
	
	"Function"
	kebab := word copyReplaceAll: '/' with: '-'.
	pascal := '' join: ((kebab substrings: '-') collect: [:s | s capitalized]).
	node := resolver findFunction: pascal.
	node ifNotNil: [ ^ node ].
	
	"Class"
	snake := word copyReplaceAll: '-' with: '_'.
	node := resolver findClass: snake.
	node ifNotNil: [ ^ node ].
	
	"Method"
	^ resolver findMethodAnywhere: pascal
]

{ #category : 'save' }
ZealBrowser >> saveAllCards [
	"Re-emit the file from cards' current Zeal sources via the dialect's
	 compileFileFromSources:file:, then surgically refresh just this file's
	 node in projectTree. When `cards` is empty the file is rewritten as
	 empty so deleting the last card actually clears it from disk."
	| sources fileContent |
	currentFile ifNil: [ ^ self ].
	sources := cards isNil
		ifTrue: [ #() ]
		ifFalse: [ cards collect: [ :rec |
			| ed |
			ed := rec at: #editor ifAbsent: [ nil ].
			ed isNil
				ifTrue: [ rec at: #source ]
				ifFalse: [ ed editor text asString ] ] ].

	fileContent := sources isEmpty
		ifTrue: [ '' ]
		ifFalse: [ self dialectCompiler compileFileFromSources: sources file: currentFile fullName ].

	[ currentFile writeStreamDo: [ :ws | ws nextPutAll: fileContent ] ]
		on: Error do: [ :e |
			cards ifNotNil: [
				cards do: [ :rec | (rec at: #editor ifAbsent: [ nil ]) ifNotNil: [ :ed | self flashError: ed ] ] ].
			^ self ].

	self refreshFileNodeFor: currentFile
]

{ #category : 'save' }
ZealBrowser >> saveAndRefreshCard: cardRec [
	"Save current state to disk, then re-render with the just-edited card
	 expanded. Rename forks: original card's #source is restored from
	 #originalSource so its editor's typed-over text doesn't bleed into the
	 saved file. Multi-binding edits split into separate cards. After saving,
	 the just-compiled definition is pushed into the enclosing GtPager as a
	 new inspector page (Zeal + target tabs come from the node's gtViews)."
	| ed currentName edText expanded originalName flashTargetName originalSource |
	currentFile ifNil: [ ^ self saveAllCards ].
	ed := cardRec at: #editor ifAbsent: [ nil ].
	edText := ed ifNotNil: [ ed editor text asString ] ifNil: [ cardRec at: #source ].
	originalName := cardRec at: #originalName ifAbsent: [ nil ].
	originalSource := cardRec at: #originalSource ifAbsent: [ cardRec at: #source ].

	expanded := self expandMultiBindings: { edText }.
	(expanded size > 1) ifTrue: [
		| cardIdx |
		cardIdx := cards indexOf: cardRec.
		cardIdx > 0 ifTrue: [ cards removeIndex: cardIdx ].
		expanded do: [ :formSrc |
			| newName existingIdx |
			newName := self nameOfForm: formSrc.
			existingIdx := nil.
			newName ifNotNil: [
				cards doWithIndex: [ :rec :i |
					existingIdx ifNil: [
						(self nameOfForm: (rec at: #source)) = newName
							ifTrue: [ existingIdx := i ] ] ] ].
			existingIdx
				ifNotNil: [ (cards at: existingIdx) at: #source put: formSrc ]
				ifNil: [
					cards add: (Dictionary new
						at: #source put: formSrc;
						at: #editor put: nil;
						at: #file put: currentFile;
						at: #originalName put: newName;
						at: #originalSource put: formSrc;
						yourself) ] ].
		flashTargetName := self nameOfForm: expanded last.
		self saveAllCards.
		self openFile: currentFile expandName: flashTargetName.
		self pushDefinitionPageNamed: flashTargetName.
		self flashSuccessOnCardNamed: flashTargetName.
		^ self ].

	currentName := self nameOfForm: edText.
	(currentName notNil and: [ originalName notNil and: [ currentName ~= originalName ] ])
		ifTrue: [
			"FORK — restore original source on the existing card; append a new card."
			cardRec at: #editor put: nil.
			cardRec at: #source put: originalSource.
			cards add: (Dictionary new
				at: #source put: edText;
				at: #editor put: nil;
				at: #file put: currentFile;
				at: #originalName put: currentName;
				at: #originalSource put: edText;
				yourself).
			flashTargetName := currentName ]
		ifFalse: [
			"MODIFY — same name, just sync editor text into #source."
			cardRec at: #source put: edText.
			cardRec at: #originalSource put: edText.
			flashTargetName := currentName ifNil: [ originalName ] ].

	self saveAllCards.
	self openFile: currentFile expandName: flashTargetName.
	self pushDefinitionPageNamed: flashTargetName.
	self flashSuccessOnCardNamed: flashTargetName
]

{ #category : 'save' }
ZealBrowser >> saveAndRefreshMethodSub: subRec parent: parentCardRec [
	"Ctrl+S on a method sub-card. MODIFY (same name): sync sub source, save,
	 flash, push to pager. FORK (renamed): restore original on the existing
	 sub, append the new method to the parent, rebuild the class UI, save,
	 expand+flash the new sub, push."
	| ed methodSrc methodName originalName originalSource isFork newSub |
	currentFile ifNil: [ ^ self saveAllCards ].
	ed := subRec at: #editor ifAbsent: [ nil ].
	ed ifNotNil: [ methodSrc := ed editor text asString ]
	  ifNil: [ methodSrc := subRec at: #source ].
	originalName := subRec at: #originalName ifAbsent: [ nil ].
	originalSource := subRec at: #originalSource ifAbsent: [ subRec at: #source ].
	methodName := self nameOfForm: methodSrc.
	isFork := methodName notNil
		and: [ originalName notNil
		and: [ methodName ~= originalName ] ].

	isFork
		ifTrue: [
			| holder methodSources subs |
			subRec at: #source put: originalSource.
			subRec at: #editor put: nil.
			methodSources := parentCardRec at: #methodSources ifAbsent: [
				| oc | oc := OrderedCollection new.
				parentCardRec at: #methodSources put: oc. oc ].
			methodSources add: methodSrc.
			parentCardRec at: #source put: (self rebuildClassSourceFor: parentCardRec).
			holder := parentCardRec at: #contentHolder ifAbsent: [ nil ].
			holder ifNotNil: [
				self fillClassCardContent: holder card: parentCardRec forFile: currentFile ].
			self saveAllCards.
			subs := parentCardRec at: #subCards ifAbsent: [ #() ].
			newSub := subs detect: [ :s | (self nameOfForm: (s at: #source)) = methodName ]
				ifNone: [ nil ].
			newSub ifNotNil: [
				(newSub at: #toggleBlock ifAbsent: [ nil ])
					ifNotNil: [ :tb | tb value ].
				(newSub at: #editor ifAbsent: [ nil ])
					ifNotNil: [ :nEd | self flashSuccess: nEd ] ] ]
		ifFalse: [
			subRec at: #source put: methodSrc.
			subRec at: #originalSource put: methodSrc.
			parentCardRec at: #source put: (self rebuildClassSourceFor: parentCardRec).
			self saveAllCards.
			ed ifNotNil: [ self flashSuccess: ed ] ].

	self pushCompiledMethodPageFor: methodSrc named: methodName
]

{ #category : 'highlighting' }
ZealBrowser >> scheduleRehighlight: anEditor [
	"Debounced rehighlight — syntax colors only, no expanders (expanders break on text replace)"
	suppressRehighlight == true ifTrue: [ ^ self ].
	rehighlightProcess ifNotNil: [ rehighlightProcess terminate ].
	rehighlightProcess := [
		(Delay forMilliseconds: 500) wait.
		anEditor enqueueTask: (BlTaskAction new action: [
			| skip text cursorPos highlighted |
			skip := false.
			(completionController notNil and: [completionController isShowingPopup]) ifTrue: [ skip := true ].
			skip ifFalse: [
				anEditor editor text attributeRunsDo: [:start :end :attrs |
					attrs do: [:a |
						(a isKindOf: ZealExpanderAttribute) ifTrue: [
							a isExpanded ifTrue: [ skip := true ] ] ] ] ].
			skip ifFalse: [
				text := anEditor editor text asString.
				text isEmpty ifFalse: [
					cursorPos := 0.
					anEditor editor cursors do: [:c | cursorPos := c position].
					highlighted := self themeClass highlight: text.
					anEditor text: highlighted.
					anEditor editor navigator
						moveTo: (cursorPos min: highlighted size);
						apply ] ].
			rehighlightProcess := nil ]) ] fork
]

{ #category : 'parinfer' }
ZealBrowser >> setupArrowKeys: zealEditor [
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

{ #category : 'editor' }
ZealBrowser >> setupFormHighlight: anEditor [
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

{ #category : 'parinfer' }
ZealBrowser >> setupKeyChords: zealEditor [
	"Install key chord handler with default chords"
	keyChord := ZealKeyChord new.
	keyChord installOn: zealEditor.
	
	"Example chords — add more with: keyChord addChord: 'xx' action: [...]"
	keyChord addChord: 'jk' action: [ self applyParinfer: zealEditor ]
]

{ #category : 'editor' }
ZealBrowser >> setupLambdaAutoReplace: anEditor [
	"No-op — lambda replacement is now triggered from the text styler via a
	 deferred task after each restyle."
]

{ #category : 'editor' }
ZealBrowser >> setupLambdaBackspace: anEditor [
	"Lambda backspace is now handled by ZealTextEditorDeleter (installed globally
	 via BrTextEditorModel>>#deleter extension). No per-editor setup needed."
]

{ #category : 'parinfer' }
ZealBrowser >> setupParinfer: zealEditor [
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

{ #category : 'parinfer' }
ZealBrowser >> shrinkSelection: zealEditor [
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

{ #category : 'cards' }
ZealBrowser >> signatureFor: zealFormSource [
	"Build a one-line header for a top-level definition. Functions render as
	 `λ name   p1:T1 → p2:T2 → ... → retType` (lambda first, then name,
	 then the curry chain). Data forms keep the prefix-keyword style."
	| trimmed firstLine ast top head exprs name lambda |
	trimmed := zealFormSource trimBoth.
	firstLine := (trimmed lines ifEmpty: [ #('') ]) first.
	ast := [ ZealParser parse: trimmed ] on: Error do: [ :e | nil ].
	(ast notNil and: [ ast respondsTo: #expressions ]) ifFalse: [ ^ firstLine ].
	ast expressions isEmpty ifTrue: [ ^ firstLine ].
	top := ast expressions first.
	(top isKindOf: ZealListNode) ifFalse: [ ^ firstLine ].
	exprs := top expressions.
	exprs isEmpty ifTrue: [ ^ firstLine ].
	(exprs first isKindOf: ZealSymbolNode) ifFalse: [ ^ firstLine ].
	head := exprs first value value.
	name := exprs size >= 2
		ifTrue: [
			((exprs second isKindOf: ZealSymbolNode) or: [ exprs second isKindOf: ZealColonChainNode ])
				ifTrue: [
					(exprs second isKindOf: ZealColonChainNode)
						ifTrue: [ (ZealColonChainResolver resolve: exprs second value value) at: #name ]
						ifFalse: [ exprs second value value ] ]
				ifFalse: [ '' ] ]
		ifFalse: [ '' ].
	lambda := String with: (Character value: 16r03BB).
	head = 'defn' ifTrue: [ ^ lambda , ' ' , name , '   ' , (self paramsLabelFor: top) ].
	head = 'defclass' ifTrue: [ ^ 'class  ' , name ].
	head = 'defstruct' ifTrue: [ ^ 'struct  ' , name ].
	head = 'defenum' ifTrue: [ ^ 'enum  ' , name ].
	head = 'definterface' ifTrue: [ ^ 'interface  ' , name ].
	head = 'def' ifTrue: [ ^ 'const  ' , name ].
	head = 'var' ifTrue: [ ^ 'var  ' , name ].
	^ firstLine
]

{ #category : 'parinfer' }
ZealBrowser >> slurpForward: zealEditor [
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
	zealEditor text: ((self themeClass highlight: result)).
	zealEditor editor navigator moveTo: (cursorPos min: result size); apply
]

{ #category : 'tree' }
ZealBrowser >> spliceFileNodeFor: aFileRef into: rootNode [
	"Find aFileRef's parent folder node by walking down rootNode following
	 the file's path components. If found, replace any existing file node at
	 that location with a freshly-parsed one (or append a new node when the
	 file wasn't in the tree). Returns true on success, false if the parent
	 folder isn't represented in the tree (caller should rebuild fully)."
	| rootRef relative segments folderNode fileNode oldIdx oldNode |
	rootRef := rootNode fileRef.
	relative := aFileRef fullName allButFirst: rootRef fullName size.
	(relative beginsWith: '/') ifTrue: [ relative := relative allButFirst ].
	(relative beginsWith: '\') ifTrue: [ relative := relative allButFirst ].
	segments := ((relative copyReplaceAll: '\' with: '/') substrings: '/')
		reject: [ :s | s isEmpty ].
	segments size < 1 ifTrue: [ ^ false ].

	folderNode := rootNode.
	1 to: segments size - 1 do: [ :i |
		| seg child |
		seg := segments at: i.
		child := folderNode children
			detect: [ :c | c isFolder and: [ c name = seg ] ]
			ifNone: [ nil ].
		child ifNil: [ ^ false ].
		folderNode := child ].

	fileNode := self dialectFileNodeClass new fileRef: aFileRef.
	project populateFileNode: fileNode.
	oldNode := folderNode children
		detect: [ :c | c isFile and: [ c fileRef fullName = aFileRef fullName ] ]
		ifNone: [ nil ].
	oldNode
		ifNotNil: [
			oldIdx := folderNode children indexOf: oldNode.
			folderNode children at: oldIdx put: fileNode.
			fileNode parent: folderNode ]
		ifNil: [ folderNode addChild: fileNode ].
	^ true
]

{ #category : 'cards' }
ZealBrowser >> splitTopLevelForms: zealSource [
	"Split a Zeal source string into top-level forms by paren-depth. Comments and
	 leading whitespace between forms are absorbed into the next form so they
	 stay visually attached when re-saved."
	| forms i size depth start inString chunk |
	forms := OrderedCollection new.
	i := 1. size := zealSource size. depth := 0. start := nil. inString := false.
	[ i <= size ] whileTrue: [
		| ch |
		ch := zealSource at: i.
		ch = $" ifTrue: [ inString := inString not ].
		inString ifFalse: [
			(ch = $; and: [ depth = 0 ]) ifTrue: [
				[ i <= size and: [ (zealSource at: i) ~= Character cr and: [ (zealSource at: i) ~= Character lf ] ] ] whileTrue: [ i := i + 1 ] ].
			(#($( $[ ${) includes: ch) ifTrue: [
				depth = 0 ifTrue: [ start := i ].
				depth := depth + 1 ].
			(#($) $] $}) includes: ch) ifTrue: [
				depth := depth - 1.
				(depth = 0 and: [ start notNil ]) ifTrue: [
					chunk := (zealSource copyFrom: start to: i) trimBoth.
					chunk isEmpty ifFalse: [ forms add: chunk ].
					start := nil ] ] ].
		i := i + 1 ].
	^ forms
]

{ #category : 'actions' }
ZealBrowser >> swapForm: anEditor up: isUp [
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
ZealBrowser >> themeClass [
	"Return the theme class for this dialect. Subclasses must override."
	self subclassResponsibility
]
