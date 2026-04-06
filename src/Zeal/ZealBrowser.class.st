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

{ #category : 'ui' }
ZealBrowser >> buildDivider [
	^ BlElement new 
		background: (Color fromHexString: '444444');
		constraintsDo: [:c | c horizontal matchParent. c vertical exact: 1];
		margin: (BlInsets top: 8 bottom: 8)
]

{ #category : 'ui' }
ZealBrowser >> buildSectionLabel: title [
	^ BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: self themeClass specialFormColor; fontSize: 15; bold);
		text: title
]

{ #category : 'building' }
ZealBrowser >> configureZealEditor: anEditor [
	"Set up shared features on any Zeal code editor."
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
		text: ((self themeClass highlight: (String cr join: lines))).
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
		text: ((self themeClass highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (cursorPos + spacesToAdd min: zealEditor editor text size);
		apply
]

{ #category : 'initialization' }
ZealBrowser >> initialize [
	super initialize.
	self layout: BlLinearLayout horizontal.
	self constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	self background: self themeClass backgroundColor
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
		text: ((self themeClass highlight: (String cr join: lines))).
	zealEditor editor navigator
		moveTo: (newCursorPos min: zealEditor editor text size);
		apply
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
