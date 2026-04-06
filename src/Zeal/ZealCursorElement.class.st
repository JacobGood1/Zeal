Class {
	#name : 'ZealCursorElement',
	#superclass : 'BrCursorElement',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'private' }
ZealCursorElement >> applyCursorHighlight [
	"Set the character at cursor position to dark foreground, saving original"
	[ | text pos |
	text := self paragraphText.
	(text notNil and: [ textPosition notNil ]) ifTrue: [
		pos := textPosition + 1.
		(pos > 0 and: [ pos <= text size ]) ifTrue: [
			| origFg |
			origFg := (text attributesAt: pos) 
				detect: [ :a | a isKindOf: BlTextForegroundAttribute ] ifNone: [ nil ].
			self userData at: #originalFg put: (origFg ifNotNil: [ origFg paint ] ifNil: [ nil ]).
			self userData at: #highlightPos put: pos.
			text 
				attributes: { BlTextForegroundAttribute paint: Color black }
				from: pos to: pos ] ] ] on: Error do: [ :e | ]
]

{ #category : 'private' }
ZealCursorElement >> clearCursorHighlight [
	"Restore original foreground at previous cursor position"
	[ | text pos origFg |
	pos := self userData at: #highlightPos ifAbsent: [ nil ].
	origFg := self userData at: #originalFg ifAbsent: [ nil ].
	text := self paragraphText.
	(text notNil and: [ pos notNil and: [ pos > 0 and: [ pos <= text size ] ] ]) ifTrue: [
		"Remove the black attribute"
		text clearAttributes: pos to: pos if: [ :attr |
			(attr isKindOf: BlTextForegroundAttribute) and: [ attr paint = Color black ] ].
		"Restore original color if we had one"
		origFg ifNotNil: [
			text attributes: { BlTextForegroundAttribute paint: origFg } from: pos to: pos ] ] ] on: Error do: [ :e | ]
]

{ #category : 'blinking' }
ZealCursorElement >> doBlink [
	"No blinking — stay solid"
]

{ #category : 'drawing' }
ZealCursorElement >> drawOnSpartaCanvas: aCanvas [
	super drawOnSpartaCanvas: aCanvas.
	[ | char |
	char := self userData at: #cursorChar ifAbsent: [ nil ].
	(char notNil and: [ char size > 0 ]) ifTrue: [
		| font textPainter metrics ascent descent textHeight y |
		font := aCanvas font
			named: 'Source Code Pro';
			size: 14;
			build.
		textPainter := aCanvas text
			string: char;
			font: font;
			paint: Color black.
		metrics := textPainter measure.
		ascent := metrics fontMetrics ascent abs.
		descent := metrics fontMetrics descent abs.
		textHeight := ascent + descent.
		y := ((self height - textHeight) / 2.0) + ascent.
		textPainter baseline: (0 @ y).
		textPainter draw ] ] on: Error do: [ :e | ]
]

{ #category : 'private' }
ZealCursorElement >> editorText [
	"Find the editor text from our parent chain"
	| p |
	p := self parent.
	[ p notNil ] whileTrue: [
		(p isKindOf: BrEditor) ifTrue: [ ^ p text ].
		p := p parent ].
	^ nil
]

{ #category : 'hooks' }
ZealCursorElement >> onAddedToSceneGraph [
	super onAddedToSceneGraph.
	self updateCharacterOverlay
]

{ #category : 'hooks' }
ZealCursorElement >> onPositionInSpaceChanged [
	super onPositionInSpaceChanged.
	self updateCharacterOverlay
]

{ #category : 'private' }
ZealCursorElement >> paragraphText [
	"Find the paragraph text from our direct parent"
	| p |
	p := self parent.
	[ p notNil ] whileTrue: [
		(p isKindOf: BrTextEditorParagraphElement) ifTrue: [ ^ p text ].
		p := p parent ].
	^ nil
]

{ #category : 'accessing' }
ZealCursorElement >> textPosition: aNumber [
	textPosition := aNumber.
	self updateCharacterOverlay.
	self requestLayout
]

{ #category : 'private' }
ZealCursorElement >> updateCharacterOverlay [
	"Store the character to draw - actual rendering happens in drawOnSpartaCanvas:"
	[ | text pos |
	text := self paragraphText.
	(text isNil or: [ textPosition isNil ]) ifTrue: [ 
		self userData at: #cursorChar put: nil. ^ self ].
	pos := textPosition + 1.
	(pos < 1 or: [ pos > text size ]) 
		ifTrue: [ self userData at: #cursorChar put: nil ]
		ifFalse: [ self userData at: #cursorChar put: (text asString at: pos) asString ].
	self invalidate
	] on: Error do: [ :e | ]
]
