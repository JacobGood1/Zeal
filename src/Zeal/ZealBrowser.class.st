Class {
	#name : 'ZealBrowser',
	#superclass : 'BlElement',
	#instVars : [
		'project',
		'treeElement',
		'detailElement',
		'selectedNode',
		'expandSelectionStack',
		'keyChord'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'opening' }
ZealBrowser class >> open [
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
ZealBrowser class >> openFolder: aPathString [
	| project |
	project := ZealProject new scanFolder: aPathString asFileReference.
	^ self openProject: project
]

{ #category : 'opening' }
ZealBrowser class >> openProject: aZealProject [
	| browser space |
	browser := self new.
	browser project: aZealProject.
	space := BlSpace new.
	space title: 'Zeal Browser // ' , aZealProject name.
	space extent: 1100@700.
	space root background: ZealTheme backgroundColor.
	space root layout: BlLinearLayout horizontal.
	space root addChild: browser.
	space show.
	^ browser
]

{ #category : 'opening' }
ZealBrowser class >> openSample [
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
	zealEditor text: ((ZealTheme highlight: result)).
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
	zealEditor text: ((ZealTheme highlight: result)).
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
	zealEditor text: ((ZealTheme highlight: result)).
	zealEditor editor navigator moveTo: (cursorPos min: result size); apply
]

{ #category : 'building' }
ZealBrowser >> buildDetail [
	detailElement := BlElement new.
	detailElement layout: BlLinearLayout vertical.
	detailElement constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	detailElement background: ZealTheme backgroundColor.
	detailElement padding: (BlInsets all: 12).
	self showWelcome.
	^ detailElement
]

{ #category : 'building' }
ZealBrowser >> buildTree [
	treeElement := BrSimpleTree new.
	treeElement
		nodeStencil: [ BrLabel new aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme foregroundColor) ];
		nodeDataBinder: [ :label :item | label text: (self labelFor: item) ];
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

{ #category : 'building' }
ZealBrowser >> buildUI [
	self removeChildren.
	self addChild: self buildTree.
	self addChild: self buildDetail
]

{ #category : 'building' }
ZealBrowser >> childrenOf: item [
	(item isKindOf: ZealModule) ifTrue: [ ^ item definitions ].
	(item isKindOf: ZealClass) ifTrue: [ ^ item fields , item methods ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ item fields ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ item methods ].
	^ #()
]

{ #category : 'actions' }
ZealBrowser >> compileAndSave: zealEditor forNode: aNode [
	| zealSource compiled verseSource namespace filePath genClass |
	zealSource := zealEditor editor text asString.
	
	[ compiled := ZealCompiler compile: zealSource ] on: Error do: [:e |
		self flashEditor: zealEditor color: (Color red alpha: 0.3). ^ self ].
	
	"Generate Verse with zeal comment"
	[ verseSource := compiled compileToVerseWithZealComment: zealSource ] on: Error do: [:e |
		self flashEditor: zealEditor color: (Color red alpha: 0.3). ^ self ].
	
	detailElement childWithId: #verseOutput ifFound: [:ve |
		ve text: (verseSource asRopedText foreground: ZealTheme foregroundColor) ].
	
	aNode rawSource: nil.
	
	genClass := self generatedClassFor: aNode.
	genClass ifNotNil: [
		genClass class compile: ('zealSource
	^ ' , zealSource printString) classified: 'zeal'.
		genClass class compile: ('verseSource
	^ ' , verseSource printString) classified: 'zeal' ].
	
	namespace := aNode module.
	namespace ifNotNil: [
		filePath := self verseFilePathFor: namespace.
		filePath ifNotNil: [ self writeNamespaceToFile: namespace path: filePath ] ].
	
	self flashEditor: zealEditor color: (ZealTheme cursorColor alpha: 0.2)
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
		text: ((ZealTheme highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (cursorPos - 2 max: 0);
		apply
]

{ #category : 'parinfer' }
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
		text: ((ZealTheme highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (newCursorPos min: zealEditor editor text size);
		apply
]

{ #category : 'parinfer' }
ZealBrowser >> expandSelection: zealEditor [
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

{ #category : 'actions' }
ZealBrowser >> flashEditor: anEditor color: aColor [
	"Flash the editor background briefly to indicate success/failure."
	| original |
	original := anEditor background.
	anEditor background: aColor.
	[ (Delay forMilliseconds: 300) wait.
	  anEditor enqueueTask: (BlTaskAction new action: [ anEditor background: original ]) ] fork
]

{ #category : 'detail' }
ZealBrowser >> generatedClassFor: aNode [
	"Find the generated Smalltalk class for a ZealNode by matching name"
	| name |
	(aNode respondsTo: #name) ifFalse: [ ^ nil ].
	name := aNode name ifNil: [ ^ nil ].
	^ Smalltalk allClassesAndTraits 
		detect: [:c | 
			(c name beginsWith: 'Zeal_') and: [
				c name endsWith: '_' , (ZealClassGenerator toPascalCase: name) ] ]
		ifNone: [ nil ]
]

{ #category : 'parinfer' }
ZealBrowser >> indentLine: zealEditor [
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
ZealBrowser >> initialize [
	super initialize.
	self layout: BlLinearLayout horizontal.
	self constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	self background: ZealTheme backgroundColor
]

{ #category : 'building' }
ZealBrowser >> labelFor: item [
	(item isKindOf: ZealModule) ifTrue: [ 
		item kind = #file ifTrue: [ ^ 'namespace ' , item name ].
		^ item name ].
	(item isKindOf: ZealClass) ifTrue: [ 
		^ 'class ' , item name , (item superclass ifNotNil: [:p | '(' , p , ')'] ifNil: ['']) ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ 'struct ' , item name ].
	(item isKindOf: ZealEnum) ifTrue: [ ^ 'enum ' , item name ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ 'interface ' , item name ].
	(item isKindOf: ZealFunction) ifTrue: [
		^ 'fn ' , item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealVariable) ifTrue: [ 
		^ (item isMutable ifTrue: ['var '] ifFalse: ['val ']) , item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealField) ifTrue: [ 
		^ (item isMutable ifTrue: ['var '] ifFalse: ['']) , item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealCompileError) ifTrue: [ ^ '! ' , (item message copyFrom: 1 to: (item message size min: 50)) ].
	^ item printString
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

{ #category : 'accessing' }
ZealBrowser >> project: aZealProject [
	project := aZealProject.
	self buildUI
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
		text: ((ZealTheme highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (newCursorPos min: zealEditor editor text size);
		apply
]

{ #category : 'ui' }
ZealBrowser >> selectNode: aNode [
	| verseText zealText generatedClass zealEditor |
	selectedNode := aNode.
	detailElement removeChildren.
	
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 18; bold);
		text: (self labelFor: aNode)).
	
	generatedClass := self generatedClassFor: aNode.
	
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 12);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets top: 12 left: 0 bottom: 4 right: 0)).
	
	zealText := generatedClass 
		ifNotNil: [ generatedClass zealSource ]
		ifNil: [ [ aNode compileToZeal ] on: Error do: [:e | 'Error: ' , e messageText ] ].
	
	zealEditor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: ((ZealTheme highlight: zealText));
		background: (ZealTheme backgroundColor darker);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: BlKeyCombination primaryS;
		action: [ self compileAndSave: zealEditor forNode: aNode ]).
	self setupParinfer: zealEditor.
	self setupKeyChords: zealEditor.
	self setupArrowKeys: zealEditor.
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
		id: #verseOutput).
	
	generatedClass ifNotNil: [
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
			text: 'Smalltalk class: ' , generatedClass name;
			margin: (BlInsets top: 4)) ].
	
	(aNode isKindOf: ZealModule) ifTrue: [ self showModuleDetail: aNode ].
	(aNode isKindOf: ZealFunction) ifTrue: [ self showFunctionDetail: aNode ].
	(aNode isKindOf: ZealClass) ifTrue: [ self showClassDetail: aNode ].
	(aNode isKindOf: ZealEnum) ifTrue: [ self showEnumDetail: aNode ]
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

{ #category : 'parinfer' }
ZealBrowser >> setupKeyChords: zealEditor [
	"Install key chord handler with default chords"
	keyChord := ZealKeyChord new.
	keyChord installOn: zealEditor.
	
	"Example chords — add more with: keyChord addChord: 'xx' action: [...]"
	keyChord addChord: 'jk' action: [ self applyParinfer: zealEditor ]
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

{ #category : 'detail' }
ZealBrowser >> showClassDetail: cls [
	cls superclass ifNotNil: [:p |
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme operatorColor; fontSize: 12);
			text: 'Superclass: ' , p) ].
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Fields: ' , cls fields size printString , '  Methods: ' , cls methods size printString)
]

{ #category : 'detail' }
ZealBrowser >> showEnumDetail: en [
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Values: ' , (en values joinUsing: ', '))
]

{ #category : 'detail' }
ZealBrowser >> showFunctionDetail: func [
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Parameters:').
	func parameters do: [:p |
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor);
			text: '  ' , p name , (p type ifNotNil: [':' , p type] ifNil: ['']);
			margin: (BlInsets left: 12)) ]
]

{ #category : 'detail' }
ZealBrowser >> showModuleDetail: mod [
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

{ #category : 'detail' }
ZealBrowser >> showWelcome [
	detailElement removeChildren.
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 16);
		text: 'Select a definition to view details')
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
	zealEditor text: ((ZealTheme highlight: result)).
	zealEditor editor navigator moveTo: (cursorPos min: result size); apply
]

{ #category : 'actions' }
ZealBrowser >> verseFilePathFor: aNamespace [
	"Find the .verse file path for a namespace (ZealModule kind: #file)."
	| dir files |
	((aNamespace isKindOf: ZealModule) and: [aNamespace kind = #file]) ifFalse: [ ^ nil ].
	project ifNil: [ ^ nil ].
	dir := project path asFileReference.
	files := dir allFiles select: [:f | 
		f extension = 'verse' and: [f basenameWithoutExtension = aNamespace name] ].
	files ifEmpty: [ ^ nil ] ifNotEmpty: [ ^ files first fullName ]
]

{ #category : 'actions' }
ZealBrowser >> writeNamespaceToFile: aNamespace path: filePath [
	"Write all definitions in a namespace to the .verse file."
	| stream |
	stream := String new writeStream.
	"Write usings first"
	aNamespace usings do: [:u |
		stream nextPutAll: 'using { '; nextPutAll: u path; nextPutAll: ' }'.
		stream cr ].
	aNamespace usings notEmpty ifTrue: [ stream cr ].
	"Write each definition's verse source"
	aNamespace definitions do: [:d |
		d compileToVerse: stream indent: 0.
		stream cr; cr ].
	filePath asFileReference writeStreamDo: [:ws | ws nextPutAll: stream contents ]
]
