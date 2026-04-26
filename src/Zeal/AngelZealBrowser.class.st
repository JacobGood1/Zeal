Class {
	#name : 'AngelZealBrowser',
	#superclass : 'ZealBrowser',
	#instVars : [
		'currentFile',
		'zealEditor',
		'angelEditor',
		'cards',
		'fileDefsEditor',
		'fileDefsBufferText',
		'fileDefsCursorPos',
		'projectTree'
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
AngelZealBrowser >> addDefinitionsFrom: anEditor toCard: cardRec [
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
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file).
	self saveAllCards.
	newEditor := cardRec at: #defsEditor ifAbsent: [ anEditor ].
	"Return focus to the new editor so the user can keep typing."
	newEditor enqueueTask: (BlTaskAction new action: [
		newEditor requestFocus ]).
	self flashSuccess: newEditor
]

{ #category : 'api' }
AngelZealBrowser >> addFileDefinitionsFrom: anEditor inFile: aFileRef [
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

{ #category : 'api' }
AngelZealBrowser >> addMethodTo: cardRec [
	"Append a placeholder method to the class card and re-render."
	| methods placeholder |
	methods := cardRec at: #methodSources ifAbsent: [
		| empty |
		empty := OrderedCollection new.
		cardRec at: #methodSources put: empty.
		empty ].
	"Sync from current subCards before adding (their text may be ahead of cached methodSources)."
	(cardRec at: #subCards ifAbsent: [ #() ]) doWithIndex: [ :sub :i |
		(i <= methods size) ifTrue: [ methods at: i put: (sub at: #source) ] ].
	placeholder := '(defn new-method:void [])'.
	methods add: placeholder.
	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file)
]

{ #category : 'api' }
AngelZealBrowser >> addSlotTo: cardRec [
	"Append a placeholder slot to the class card and re-render."
	| slots |
	slots := cardRec at: #slotSources ifAbsent: [
		| empty |
		empty := OrderedCollection new.
		cardRec at: #slotSources put: empty.
		empty ].
	slots add: '(var new-slot:int 0)'.
	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file)
]

{ #category : 'api' }
AngelZealBrowser >> buildAddMethodForm: cardRec [
	"Inline form: [Name] [Return type] [Params] [Add].
	 Submitting appends a `(defn name:retType [params])` skeleton method."
	| form nameField retField paramsField addBtn |
	form := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4 left: 12 bottom: 8 right: 0);
		padding: (BlInsets all: 4);
		background: ZealTheme backgroundColor darker.

	nameField := self buildInlineField: 'name' width: 130.
	retField := self buildInlineField: 'returnType' width: 80.
	paramsField := self buildInlineField: 'params' width: 200.
	addBtn := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude new;
		label: 'Add';
		beSmallSize;
		margin: (BlInsets top: 0 left: 8 bottom: 0 right: 0);
		action: [
			| name ret params src methods |
			name := nameField editor text asString trimBoth.
			ret := retField editor text asString trimBoth.
			params := paramsField editor text asString trimBoth.
			name isEmpty ifFalse: [
				src := '(defn ' , name.
				ret isEmpty ifFalse: [ src := src , ':' , ret ].
				src := src , ' [' , params , '])'.
				methods := cardRec at: #methodSources ifAbsent: [
					| empty | empty := OrderedCollection new.
					cardRec at: #methodSources put: empty. empty ].
				"Sync subCards into methodSources first"
				(cardRec at: #subCards ifAbsent: [ #() ]) doWithIndex: [ :sub :i |
					(i <= methods size) ifTrue: [ methods at: i put: (sub at: #source) ] ].
				methods add: src.
				cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
				self fillClassCardContent: (cardRec at: #contentHolder)
					card: cardRec
					forFile: (cardRec at: #file) ] ].

	form addChild: nameField.
	form addChild: retField.
	form addChild: paramsField.
	form addChild: addBtn.
	^ form
]

{ #category : 'api' }
AngelZealBrowser >> buildAddSlotForm: cardRec [
	"Inline form: [Name] [Type] [Value] [☐ immutable] [Add].
	 Submitting appends a `(var name:type value)` (or `(def …)` when immutable
	 is checked) to slotSources, then re-renders the card."
	| form nameField typeField valueField immutableChk addBtn |
	form := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 4 left: 12 bottom: 8 right: 0);
		padding: (BlInsets all: 4);
		background: ZealTheme backgroundColor darker.

	nameField := self buildInlineField: 'name' width: 110.
	typeField := self buildInlineField: 'type' width: 80.
	valueField := self buildInlineField: 'value' width: 80.
	immutableChk := BrCheckbox new
		beSmallSize;
		uncheck;
		margin: (BlInsets top: 0 left: 8 bottom: 0 right: 4).
	addBtn := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude new;
		label: 'Add';
		beSmallSize;
		margin: (BlInsets top: 0 left: 8 bottom: 0 right: 0);
		action: [
			| name type value isImmutable head src slots |
			name := nameField editor text asString trimBoth.
			type := typeField editor text asString trimBoth.
			value := valueField editor text asString trimBoth.
			isImmutable := immutableChk isChecked.
			name isEmpty ifFalse: [
				head := isImmutable ifTrue: [ 'def' ] ifFalse: [ 'var' ].
				src := '(' , head , ' ' , name.
				type isEmpty ifFalse: [ src := src , ':' , type ].
				value isEmpty ifFalse: [ src := src , ' ' , value ].
				src := src , ')'.
				slots := cardRec at: #slotSources ifAbsent: [
					| empty | empty := OrderedCollection new.
					cardRec at: #slotSources put: empty. empty ].
				slots add: src.
				cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
				self fillClassCardContent: (cardRec at: #contentHolder)
					card: cardRec
					forFile: (cardRec at: #file) ] ].

	form addChild: nameField.
	form addChild: typeField.
	form addChild: valueField.
	form addChild: immutableChk.
	form addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
		text: 'immutable').
	form addChild: addBtn.
	^ form
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
AngelZealBrowser >> buildDefinitionCardFor: zealFormSource inFile: aFileRef expanded: startExpanded [
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

{ #category : 'api' }
AngelZealBrowser >> buildDefinitionCardForSection: aSection inFile: aFileRef expanded: startExpanded [
	"Build one card from a parsed section dict. Reuses buildDefinitionCardFor:
	 by feeding the embedded Zeal source as the card's #source."
	self buildDefinitionCardFor: (aSection at: #zealSource)
		inFile: aFileRef
		expanded: startExpanded
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
AngelZealBrowser >> buildFileDefinitionsEditor: aFileRef [
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

{ #category : 'api' }
AngelZealBrowser >> buildInlineField: placeholder width: w [
	"Single-line input field used by the add-slot/add-method forms.
	 The placeholder argument is stored as element id for reference but no hint
	 text is shown — BrEditor doesn't natively support placeholders."
	^ BrEditor new
		aptitude: BrGlamorousRegularEditorAptitude new;
		text: '' asRopedText;
		id: placeholder asSymbol;
		background: ZealTheme backgroundColor lighter;
		constraintsDo: [:c | c horizontal exact: w. c vertical fitContent ];
		padding: (BlInsets top: 2 left: 6 bottom: 2 right: 6);
		margin: (BlInsets top: 0 left: 0 bottom: 0 right: 4)
]

{ #category : 'api' }
AngelZealBrowser >> buildMethodSubCardFor: aDefnNode in: aContainer card: parentCardRec [
	"Build a collapsible sub-card for one class method."
	| sig methodSrc subCard headerRow contentHolder arrow label isExpanded toggleBlock subRec |
	methodSrc := ((aDefnNode respondsTo: #rawSource) and: [ aDefnNode rawSource notNil ])
		ifTrue: [ aDefnNode rawSource ]
		ifFalse: [ String streamContents: [ :s | aDefnNode compileToZeal: s indent: 0 ] ].
	sig := self signatureFor: methodSrc.

	subRec := Dictionary new
		at: #source put: methodSrc;
		at: #editor put: nil;
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
	arrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme parenColor; fontSize: 11);
		text: '▶';
		margin: (BlInsets right: 6).
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
	aContainer addChild: subCard
]

{ #category : 'cards' }
AngelZealBrowser >> buildMethodSubCardForSource: methodSrc in: aContainer card: parentCardRec [
	"Sub-card whose source is a raw text slice (not parsed) of a method form.
	 Tracks #originalName / #originalSource for fork-on-rename."
	| sig subCard headerRow contentHolder arrow label isExpanded toggleBlock subRec |
	sig := self signatureFor: methodSrc.

	subRec := Dictionary new
		at: #source put: methodSrc;
		at: #editor put: nil;
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
	arrow := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme parenColor; fontSize: 11);
		text: '▶';
		margin: (BlInsets right: 6).
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
AngelZealBrowser >> buildMethodSubCardForSource: methodSrc in: aContainer card: parentCardRec index: idx [
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

{ #category : 'api' }
AngelZealBrowser >> buildMinusButton: aBlock [
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

{ #category : 'api' }
AngelZealBrowser >> buildSectionHeader: title count: count [
	"Section header (Slots / Methods) with item count. No add button — new
	 members are entered via the bottom Definitions editor."
	| labelText |
	labelText := count > 0
		ifTrue: [ title , '  (' , count printString , ')' ]
		ifFalse: [ title ].
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11; bold);
		text: labelText;
		margin: (BlInsets top: 8 left: 0 bottom: 4 right: 0)
]

{ #category : 'api' }
AngelZealBrowser >> buildSectionHeader: title count: count addAction: aBlock [
	"Section header (Slots / Methods) with item count and a `+` button.
	 The `+` button's action is provided by the caller (typically toggles a form)."
	| row labelText |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 8 left: 0 bottom: 4 right: 0).
	labelText := count > 0
		ifTrue: [ title , '  (' , count printString , ')' ]
		ifFalse: [ title ].
	row addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11; bold);
		text: labelText).
	row addChild: (BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude new;
		label: '+';
		beSmallSize;
		margin: (BlInsets top: 0 left: 8 bottom: 0 right: 0);
		action: aBlock).
	^ row
]

{ #category : 'api' }
AngelZealBrowser >> buildSingleZealEditorIn: aContainer source: zealSource [
	"Fallback: the file is empty / unparseable. Show a single editor."
	| ed styler |
	aContainer addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 12);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets top: 4 bottom: 4)).
	ed := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: zealSource asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		padding: (BlInsets all: 8).
	styler := ZealTextStyler new browser: self.
	ed editor styler: styler.
	self configureZealEditor: ed.
	ed addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [
			[ currentFile writeStreamDo: [ :ws | ws nextPutAll: ed editor text asString ] ]
				on: Error do: [ :e | self flashError: ed ].
			self flashSuccess: ed ]).
	aContainer addChild: ed
]

{ #category : 'api' }
AngelZealBrowser >> buildSlotItemFor: aSlotListNode [
	"Compact display of a (var/def name:type value) slot. When the user
	 omitted the type, infer it from the value via the AngelZeal inferencer.
	 (def …) is shown with `const` prefix to make immutability obvious."
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
		inferred := AngelZealTypeInferencer default inferTypeFor: valueNode.
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

{ #category : 'api' }
AngelZealBrowser >> buildSlotItemForSource: slotSource [
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

{ #category : 'api' }
AngelZealBrowser >> buildSlotRowFor: slotSource index: idx card: cardRec [
	"Slot row: minus button + label. Click minus to remove this slot."
	| row labelEl |
	row := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 1 left: 12 bottom: 1 right: 0).
	row addChild: (self buildMinusButton: [ self removeSlotAt: idx in: cardRec ]).
	labelEl := self buildSlotItemForSource: slotSource.
	"buildSlotItemForSource: returns a label with margin — strip its margin so layout stays tight"
	labelEl margin: (BlInsets top: 0 left: 0 bottom: 0 right: 0).
	row addChild: labelEl.
	^ row
]

{ #category : 'api' }
AngelZealBrowser >> buildTree [
	"File-system tree backed by the AngelZealNode model. Each row is an
	 AngelZealFolderNode or AngelZealFileNode; folder children expand to
	 their populated children, file children stay leaves at this level
	 (definitions show in the right-pane detail when a file is selected)."
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

{ #category : 'api' }
AngelZealBrowser >> buildTreeAddBar [
	"Top of the file tree: a `Files` label with a `+` button that toggles a
	 small inline form. The form is just `[path] [Add]` — file vs folder is
	 inferred from the input: `name.zeal`/`name.as` → file, no extension →
	 folder, slashes → nested folders + final segment.
	 Input text and form visibility are preserved across Add clicks so the
	 user can keep typing entries."
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

{ #category : 'api' }
AngelZealBrowser >> buildUI [
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
		text: 'AngelZeal // ' , project name;
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
AngelZealBrowser >> buildZealDetailFor: aFileRef source: zealSource [
	"Render the file as a list of per-definition cards. Each card is a header
	 (kind + name + signature) that expands to reveal an editable Zeal source
	 and a read-only AngelScript preview. Each card's source is tracked
	 independently so the whole file round-trips correctly even when only
	 some cards have ever been expanded."
	| topLevelForms |
	cards := OrderedCollection new.
	topLevelForms := self splitTopLevelForms: zealSource.
	topLevelForms isEmpty ifTrue: [
		^ self buildSingleZealEditorIn: detailElement source: '' ].
	topLevelForms size = 1 ifTrue: [
		self buildDefinitionCardFor: topLevelForms first inFile: aFileRef expanded: true.
		^ self ].
	topLevelForms do: [ :form |
		self buildDefinitionCardFor: form inFile: aFileRef expanded: false ]
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
AngelZealBrowser >> createTreeItem: aName asFolder: isFolder [
	"Create a new file or folder under the currently-selected folder (or project
	 root if no folder is selected). For files, append `.as` if missing.
	 New files start as a stub with one `(def name 0)` so the user has something
	 to edit. Refreshes the tree afterwards."
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
				ifFalse: [ finalName , '.as' ].
			target := parentDir / ext.
			[ target writeStreamDo: [ :ws |
				ws nextPutAll: '// @zeal'; nextPutAll: String lf;
					nextPutAll: '// (def '; nextPutAll: (finalName copyUpTo: $.); nextPutAll: ' 0)'; nextPutAll: String lf;
					nextPutAll: '// @end'; nextPutAll: String lf;
					nextPutAll: 'const auto '; nextPutAll: (finalName copyUpTo: $.); nextPutAll: ' = 0;'; nextPutAll: String lf ] ]
				on: Error do: [ :e | ] ].
	self refreshTree
]

{ #category : 'api' }
AngelZealBrowser >> createTreeItemAtPath: aPathString [
	"Create a file or nested folder hierarchy from a `/`-separated path,
	 ALWAYS rooted at the project's root folder so repeated clicks are
	 idempotent (selection drift can't compound the path).
	 `kek/lawl/poo.zeal` → mkdir kek/, kek/lawl/, then create kek/lawl/poo.as.
	 `.zeal` is a marker meaning 'file' — translated to `.as` on disk.
	 If the final target already exists, this is a no-op."
	| segments parent lastIdx lastSeg target |
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
			lastSeg := (lastSeg copyFrom: 1 to: lastSeg size - 5) , '.as' ].
		target := parent / lastSeg.
		target exists ifFalse: [ self ensureFileAt: target ] ]
	ifFalse: [
		target := parent / lastSeg.
		target exists ifFalse: [ target ensureCreateDirectory ] ].
	self refreshTreeOnly
]

{ #category : 'api' }
AngelZealBrowser >> currentFolderTarget [
	"Return the folder where new files/folders should land. Reads selection
	 as an AngelZealNode; falls back to project rootFolder."
	| selected |
	selected := nil.
	(treeElement notNil and: [
		treeElement selectedNodeDo: [ :n | selected := n value ] ]).
	selected isNil ifTrue: [ ^ project rootFolder ].
	(selected isKindOf: AngelZealNode) ifTrue: [
		selected isFolder ifTrue: [ ^ selected fileRef ].
		selected isFile ifTrue: [ ^ selected fileRef parent ] ].
	"Fallback for any non-AngelZealNode (legacy FileReference)."
	(selected isKindOf: FileReference) ifTrue: [
		selected isDirectory ifTrue: [ ^ selected ].
		^ selected parent ].
	^ project rootFolder
]

{ #category : 'api' }
AngelZealBrowser >> deleteTreeItem: aFileRef [
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

{ #category : 'pager' }
AngelZealBrowser >> enclosingPager [
	"Walk up parent chain from detailElement looking for a BrPager (GtPager
	 inherits). Returns nil if not embedded in a pager."
	detailElement ifNil: [ ^ nil ].
	^ detailElement
		allParentsDetect: [ :p | p isKindOf: BrPager ]
		ifFound: [ :p | p ]
		ifNone: [ nil ]
]

{ #category : 'pager' }
AngelZealBrowser >> enclosingPagerPage [
	"Return the GtPagerWrapperElement whose viewModel is the browser's page in
	 the enclosing pager. Used to spawn replacement pages relative to the
	 current page (instead of always appending to the end)."
	| d |
	d := self instVarNamed: #detailElement.
	d ifNil: [ ^ nil ].
	^ d
		allParentsDetect: [ :p | p class name = #GtPagerWrapperElement ]
		ifFound: [ :p | p ]
		ifNone: [ nil ]
]

{ #category : 'api' }
AngelZealBrowser >> ensureFileAt: aFileRef [
	"Create aFileRef on disk if it doesn't exist. The file is empty — the user
	 adds definitions through the file's Definitions box."
	aFileRef exists ifTrue: [ ^ self ].
	[ aFileRef writeStreamDo: [ :ws | ] ] on: Error do: [ :e | ]
]

{ #category : 'api' }
AngelZealBrowser >> expandMultiBindings: forms [
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

{ #category : 'api' }
AngelZealBrowser >> fillCardContent: contentHolder card: cardRec forFile: aFileRef [
	"Populate a card body. Defclass forms get a class-browser-style detail
	 view (slots + per-method sub-cards). Everything else gets the simple
	 Zeal editor + AngelScript preview pair."
	(self isDefclassSource: (cardRec at: #source))
		ifTrue: [ ^ self fillClassCardContent: contentHolder card: cardRec forFile: aFileRef ].
	^ self fillSimpleCardContent: contentHolder card: cardRec forFile: aFileRef
]

{ #category : 'api' }
AngelZealBrowser >> fillCardContent: contentHolder source: zealFormSource forFile: aFileRef [
	"Populate a card's body with: editable Zeal source + read-only AngelScript output.
	 Ctrl+S compiles the entire file (all cards' current text) and saves."
	| ed angelOutEd styler highlighted angelSource updateAngel |
	contentHolder removeChildren.

	contentHolder addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 11);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets bottom: 4)).

	ed := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: zealFormSource asRopedText;
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8).
	styler := ZealTextStyler new browser: self.
	ed editor styler: styler.
	self configureZealEditor: ed.
	ed addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self saveAllCards ]).
	contentHolder addChild: ed.

	"Highlight on next tick (Bloc strips attrs on initial paint)."
	ed enqueueTask: (BlTaskAction new action: [
		ed editor text: (styler style: ed editor text) ]).

	contentHolder addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
		text: 'AngelScript:';
		margin: (BlInsets top: 4 bottom: 4)).

	angelSource := [ AngelZealCompiler compileToAngelScript: zealFormSource ]
		on: Error do: [ :e | 'Compile error: ' , e messageText ].
	angelOutEd := BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new;
		text: (angelSource asRopedText foreground: ZealTheme foregroundColor);
		background: ZealTheme backgroundColor darker;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		beReadOnlyWithSelection;
		padding: (BlInsets all: 8).
	contentHolder addChild: angelOutEd.

	"Re-compile + refresh the AS preview as the user edits this card."
	updateAngel := [
		| newAngel |
		newAngel := [ AngelZealCompiler compileToAngelScript: ed editor text asString ]
			on: Error do: [ :e | 'Compile error: ' , e messageText ].
		angelOutEd editor text: (newAngel asRopedText foreground: ZealTheme foregroundColor) ].
	ed editor when: BrTextEditorModifiedEvent do: [ :e | updateAngel value ]
]

{ #category : 'cards' }
AngelZealBrowser >> fillClassCardContent: contentHolder card: cardRec forFile: aFileRef [
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
	styler := ZealTextStyler new browser: self.
	defsEditor editor styler: styler.
	self configureZealEditor: defsEditor.
	defsEditor addShortcut: (BlShortcutWithAction new
		combination: BlKeyCombination primaryS;
		action: [ self addDefinitionsFrom: defsEditor toCard: cardRec ]).
	defsEditor editor when: BrTextEditorModifiedEvent do: [ :e |
		cardRec at: #defsBufferText put: defsEditor editor text asString ].
	"Restore cursor immediately — works for the in-scene editor."
	(savedCursor notNil and: [ defsText notEmpty ]) ifTrue: [
		[ defsEditor editor navigator
			moveTo: (savedCursor min: defsText size);
			apply ] on: Error do: [:e | ] ].
	"Re-apply styling on the next UI tick (Bloc strips colors on first paint)."
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
AngelZealBrowser >> fillMethodSubContent: contentHolder sub: subRec parent: parentCardRec [
	"Editable Zeal editor for one method inside a class card. Ctrl+S syncs the
	 method back into the parent class source, saves the file, and pushes a
	 compiled-method definition node into the enclosing pager — matching the
	 top-level card flow. No live AS preview; AS appears in the pager page."
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
AngelZealBrowser >> fillSimpleCardContent: contentHolder card: cardRec forFile: aFileRef [
	"Card body: editable Zeal source. Ctrl+S compiles, saves the file, and
	 pushes the resulting AngelZealDefinitionNode into the enclosing pager as
	 a new page (its gtViews provide Zeal/AngelScript/Metadata tabs)."
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
AngelZealBrowser >> findDefinitionNodeNamed: aName inFile: aFileRef [
	"Look up the AngelZealDefinitionNode for the just-saved form. Falls back
	 to a freshly-built node if the project tree doesn't yet contain it."
	| fileNode source sections sect node |
	aName ifNil: [ ^ nil ].
	fileNode := self findFileNodeFor: aFileRef.
	fileNode ifNotNil: [
		fileNode children do: [ :defNode |
			defNode name = aName ifTrue: [ ^ defNode ] ] ].
	"Fallback: parse fresh."
	source := [ aFileRef contents ] on: Error do: [ :e | ^ nil ].
	sections := AngelZealCompiler parseSections: source.
	sect := sections detect: [ :s |
		(self nameOfForm: (s at: #zealSource)) = aName ] ifNone: [ nil ].
	sect ifNil: [ ^ nil ].
	node := AngelZealDefinitionNode new.
	node zealSource: (sect at: #zealSource).
	node targetCode: (sect at: #targetCode).
	node metadata: ((sect at: #metadata ifAbsent: [ Dictionary new ]) copy).
	node name: aName.
	^ node
]

{ #category : 'api' }
AngelZealBrowser >> findFileNodeFor: aFileRef [
	"DFS the projectTree for an AngelZealFileNode whose fileRef matches aFileRef.
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

{ #category : 'api' }
AngelZealBrowser >> flashSuccessOnCardNamed: aName [
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
AngelZealBrowser >> isDefclassSource: aString [
	"True if aString starts (after whitespace) with `(defclass`."
	| trimmed |
	trimmed := aString trimBoth.
	^ (trimmed beginsWith: '(defclass')
		and: [ trimmed size > 9 and: [ '( ' includes: (trimmed at: 10) ] ]
]

{ #category : 'api' }
AngelZealBrowser >> nameOfForm: aFormSource [
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

{ #category : 'api' }
AngelZealBrowser >> openFile: aFileRef [
	"Convenience entry point that doesn't request a specific card to expand."
	^ self openFile: aFileRef expandName: nil
]

{ #category : 'api' }
AngelZealBrowser >> openFile: aFileRef expandName: aNameOrNil [
	"Load a file into the detail pane. Looks up the corresponding
	 AngelZealFileNode in projectTree and uses its pre-built definition nodes
	 (carrying metadata) when available. Falls back to fresh parsing for
	 just-created files not yet in the tree."
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

	"Find the corresponding AngelZealFileNode in the project tree."
	fileNode := self findFileNodeFor: aFileRef.
	(fileNode notNil and: [ fileNode children notEmpty ])
		ifTrue: [
			zealSources := fileNode children collect: [ :defNode | defNode zealSource ] ]
		ifFalse: [
			"Not in the tree (just-created or first-time-open) — parse the file."
			source := [ aFileRef contents ] on: Error do: [ :e | 'Error reading file: ' , e messageText ].
			sections := AngelZealCompiler parseSections: source.
			zealSources := sections notEmpty
				ifTrue: [ sections collect: [ :s | s at: #zealSource ] ]
				ifFalse: [
					(source trimBoth notEmpty) ifTrue: [
						detailElement addChild: (BrLabel new
							aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
							text: 'No @zeal headers found — auto-converting AngelScript to Zeal. Save (Ctrl+S) to commit headers.';
							margin: (BlInsets top: 0 left: 0 bottom: 8 right: 0)).
						AngelZealCompiler convertFile: source ]
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

{ #category : 'api' }
AngelZealBrowser >> paramsLabelFor: aDefnList [
	"Return a parenthesized parameter list as a string for the header label."
	| exprs paramVec |
	exprs := aDefnList expressions.
	paramVec := exprs detect: [ :e | e isKindOf: ZealVectorNode ] ifNone: [ nil ].
	paramVec ifNil: [ ^ '()' ].
	^ '(' ,
		(', ' join: (paramVec expressions collect: [ :p | p value value ])) ,
		')'
]

{ #category : 'api' }
AngelZealBrowser >> pathSegmentLooksLikeFile: aSegment [
	"True iff aSegment contains a `.` not at position 1 — i.e., has an extension."
	^ (aSegment includes: $.) and: [ (aSegment indexOf: $.) > 1 ]
]

{ #category : 'api' }
AngelZealBrowser >> project: anAngelZealProject [
	"Snapshot the project's tree (rooted at the project folder, populated with
	 file + definition nodes from existing @zeal headers) and build the UI."
	project := anAngelZealProject.
	projectTree := project buildTree.
	self buildUI
]

{ #category : 'pager' }
AngelZealBrowser >> pushCompiledMethodPageFor: methodSrc named: aName [
	"Push a one-off AngelZealDefinitionNode for a method into the enclosing
	 pager (replacing any pages to the right). Methods don't live in
	 projectTree as their own nodes, so we build the node ad-hoc."
	| pager currentPage defNode methodAS inspector |
	pager := self enclosingPager.
	pager ifNil: [ ^ self ].
	methodAS := [ AngelZealCompiler compileToAngelScript: methodSrc ]
		on: Error do: [ :e | 'Compile error: ' , e messageText ].
	defNode := AngelZealDefinitionNode new.
	defNode name: aName.
	defNode zealSource: methodSrc.
	defNode targetCode: methodAS.
	inspector := GtInspector forObject: defNode.
	currentPage := self enclosingPagerPage.
	currentPage ifNotNil: [ pager removePagesAfter: currentPage ].
	pager addWrapped: inspector.
	pager smoothScrollToLast
]

{ #category : 'pager' }
AngelZealBrowser >> pushDefinitionPageNamed: aName [
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

{ #category : 'api' }
AngelZealBrowser >> rebuildClassSourceFor: parentCardRec [
	"Re-emit a defclass form from cardRec's tracked metadata. Pulls method
	 sources from #methodSources but prefers any sub-card editor's live text
	 (so unsaved keystrokes survive structural changes)."
	| className parent slotSources methodSources subCards methodTexts stream |
	className := parentCardRec at: #className ifAbsent: [ ^ parentCardRec at: #source ].
	parent := parentCardRec at: #classParent ifAbsent: [ nil ].
	slotSources := parentCardRec at: #slotSources ifAbsent: [ #() ].
	methodSources := parentCardRec at: #methodSources ifAbsent: [ #() ].
	subCards := parentCardRec at: #subCards ifAbsent: [ #() ].

	"Live text from subCards overrides cached methodSources where present."
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

{ #category : 'api' }
AngelZealBrowser >> refreshFileNodeFor: aFileRef [
	"Surgical: re-parse only aFileRef's section of the tree, splicing the new
	 AngelZealFileNode into projectTree at the same position the old one held.
	 Falls back to a full rebuild only when the folder structure required to
	 host the file doesn't exist in the tree yet (e.g. file just created in
	 a new directory)."
	projectTree ifNil: [ projectTree := project buildTree. ^ self ].
	aFileRef exists ifFalse: [
		"File was deleted — rebuild fully (cheap) since structure may have changed."
		projectTree := project buildTree.
		^ self ].
	(self spliceFileNodeFor: aFileRef into: projectTree)
		ifFalse: [ projectTree := project buildTree ]
]

{ #category : 'api' }
AngelZealBrowser >> refreshTree [
	"Full UI rebuild — used as a fallback when in-place refresh isn't possible."
	| openFileRef |
	project ifNil: [ ^ self ].
	projectTree := project buildTree.
	openFileRef := currentFile.
	self buildUI.
	openFileRef ifNotNil: [ openFileRef exists ifTrue: [ self openFile: openFileRef ] ]
]

{ #category : 'api' }
AngelZealBrowser >> refreshTreeOnly [
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

{ #category : 'api' }
AngelZealBrowser >> removeCard: cardRec [
	"Drop a card from the file: remove it from `cards`, write the file without
	 that section, and re-render. The detail pane re-renders with the next
	 card (if any) collapsed."
	| idx |
	idx := cards indexOf: cardRec ifAbsent: [ 0 ].
	idx > 0 ifTrue: [ cards removeIndex: idx ].
	self saveAllCards.
	self openFile: currentFile
]

{ #category : 'api' }
AngelZealBrowser >> removeMethodAt: idx in: cardRec [
	| methods |
	methods := cardRec at: #methodSources ifAbsent: [ ^ self ].
	"Sync any pending edits from subCards into methodSources before deleting."
	(cardRec at: #subCards ifAbsent: [ #() ]) doWithIndex: [ :sub :i |
		(i <= methods size) ifTrue: [ methods at: i put: (sub at: #source) ] ].
	(idx >= 1 and: [ idx <= methods size ]) ifFalse: [ ^ self ].
	methods removeAt: idx.
	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file)
]

{ #category : 'api' }
AngelZealBrowser >> removeSlotAt: idx in: cardRec [
	| slots |
	slots := cardRec at: #slotSources ifAbsent: [ ^ self ].
	(idx >= 1 and: [ idx <= slots size ]) ifFalse: [ ^ self ].
	slots removeAt: idx.
	cardRec at: #source put: (self rebuildClassSourceFor: cardRec).
	self fillClassCardContent: (cardRec at: #contentHolder)
		card: cardRec
		forFile: (cardRec at: #file)
]

{ #category : 'api' }
AngelZealBrowser >> saveAllCards [
	"Re-emit the .as file from cards' current Zeal sources, then surgically
	 refresh just this file's node in projectTree (full rebuild only when the
	 surgical splice can't find the file's parent folder in the tree)."
	| sources fileContent |
	currentFile ifNil: [ ^ self ].
	(cards isNil or: [ cards isEmpty ]) ifTrue: [ ^ self ].

	sources := cards collect: [ :rec |
		| ed |
		ed := rec at: #editor ifAbsent: [ nil ].
		ed isNil
			ifTrue: [ rec at: #source ]
			ifFalse: [ ed editor text asString ] ].

	fileContent := AngelZealCompiler compileFileFromSources: sources file: currentFile fullName.

	[ currentFile writeStreamDo: [ :ws | ws nextPutAll: fileContent ] ]
		on: Error do: [ :e |
			cards do: [ :rec | (rec at: #editor ifAbsent: [ nil ]) ifNotNil: [ :ed | self flashError: ed ] ].
			^ self ].

	self refreshFileNodeFor: currentFile
]

{ #category : 'cards' }
AngelZealBrowser >> saveAndRefreshCard: cardRec [
	"Save current state to disk, then re-render with the just-edited card expanded.
	 Rename forks: original card's #source is restored from #originalSource so its
	 editor's typed-over text doesn't bleed into the saved file. Multi-binding
	 edits split into separate cards. After saving, the just-compiled definition
	 is pushed into the enclosing GtPager as a new inspector page (Zeal +
	 AngelScript tabs come from the node's gtView methods)."
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

{ #category : 'cards' }
AngelZealBrowser >> saveAndRefreshMethodSub: subRec parent: parentCardRec [
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
			"Restore original on the existing sub so its slot in #methodSources
			 (referenced by index) keeps the original method body."
			subRec at: #source put: originalSource.
			subRec at: #editor put: nil.
			"Append the new method to the parent's tracked sources."
			methodSources := parentCardRec at: #methodSources ifAbsent: [
				| oc | oc := OrderedCollection new.
				parentCardRec at: #methodSources put: oc. oc ].
			methodSources add: methodSrc.
			parentCardRec at: #source put: (self rebuildClassSourceFor: parentCardRec).
			holder := parentCardRec at: #contentHolder ifAbsent: [ nil ].
			holder ifNotNil: [
				self fillClassCardContent: holder card: parentCardRec forFile: currentFile ].
			self saveAllCards.
			"Find the freshly-built sub matching the new name, expand + flash it."
			subs := parentCardRec at: #subCards ifAbsent: [ #() ].
			newSub := subs detect: [ :s | (self nameOfForm: (s at: #source)) = methodName ]
				ifNone: [ nil ].
			newSub ifNotNil: [
				(newSub at: #toggleBlock ifAbsent: [ nil ])
					ifNotNil: [ :tb | tb value ].
				(newSub at: #editor ifAbsent: [ nil ])
					ifNotNil: [ :nEd | self flashSuccess: nEd ] ] ]
		ifFalse: [
			"MODIFY — sync editor text into sub, rebuild class source, save, flash."
			subRec at: #source put: methodSrc.
			subRec at: #originalSource put: methodSrc.
			parentCardRec at: #source put: (self rebuildClassSourceFor: parentCardRec).
			self saveAllCards.
			ed ifNotNil: [ self flashSuccess: ed ] ].

	self pushCompiledMethodPageFor: methodSrc named: methodName
]

{ #category : 'api' }
AngelZealBrowser >> signatureFor: zealFormSource [
	"Build a one-line header for a top-level definition. Recognizes def/var/defn/
	 defclass/defstruct/etc. Returns the raw first line for unknown forms."
	| trimmed firstLine ast top head exprs name |
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
				ifTrue: [ exprs second value value ]
				ifFalse: [ '' ] ]
		ifFalse: [ '' ].
	head = 'defn' ifTrue: [ ^ 'fn  ' , name , (self paramsLabelFor: top) ].
	head = 'defclass' ifTrue: [ ^ 'class  ' , name ].
	head = 'defstruct' ifTrue: [ ^ 'struct  ' , name ].
	head = 'defenum' ifTrue: [ ^ 'enum  ' , name ].
	head = 'definterface' ifTrue: [ ^ 'interface  ' , name ].
	head = 'def' ifTrue: [ ^ 'const  ' , name ].
	head = 'var' ifTrue: [ ^ 'var  ' , name ].
	^ firstLine
]

{ #category : 'api' }
AngelZealBrowser >> spliceFileNodeFor: aFileRef into: rootNode [
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

	"Build the fresh file node and splice it in."
	fileNode := AngelZealFileNode new fileRef: aFileRef.
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

{ #category : 'api' }
AngelZealBrowser >> splitTopLevelForms: zealSource [
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
				"Skip a comment line"
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

{ #category : 'api' }
AngelZealBrowser >> themeClass [
	^ AngelZealTheme
]
