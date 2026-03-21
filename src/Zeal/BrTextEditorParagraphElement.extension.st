Extension { #name : 'BrTextEditorParagraphElement' }

{ #category : '*Zeal' }
BrTextEditorParagraphElement >> defaultSelectionColor [
	^ ZealTheme selectionColor
]

{ #category : '*Zeal' }
BrTextEditorParagraphElement >> measureCursors: aCollectionOfCursorElements paragraph: aParagraph [
	aCollectionOfCursorElements do: [ :eachCursor |
		| aTextPosition eachCursorRectangle |
		aTextPosition := eachCursor textPosition.
		eachCursorRectangle := aParagraph cursorRectangleForCharacter: aTextPosition.
		eachCursorRectangle := eachCursorRectangle expandBy: 0.5@0.
		eachCursorRectangle := eachCursorRectangle translateBy: ((eachCursorRectangle left min: 0) abs @ 0).
		eachCursorRectangle := eachCursorRectangle translateBy: ((self measuredWidth - eachCursorRectangle right) min: 0) @ 0.
		eachCursorRectangle := eachCursorRectangle origin extent: (ZealTheme cursorWidth @ eachCursorRectangle height).
		eachCursor measuredBounds
			extent: eachCursorRectangle extent;
			position: eachCursorRectangle origin + self padding topLeft ]
]
