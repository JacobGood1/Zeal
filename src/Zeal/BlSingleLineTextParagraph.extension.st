Extension { #name : 'BlSingleLineTextParagraph' }

{ #category : '*Zeal' }
BlSingleLineTextParagraph >> drawSelectionOnSpartaCanvas: aCanvas padding: aBlInsets [

	(self selection isNil or: [ self selection isEmpty ])
		ifTrue: [ ^ self ].
	self selection do: [ :aSelection |
		| aStart anEnd aSelectionStartSpan aSelectionEndSpan aSelectionStartPosition aSelectionEndPosition aSelectionBounds |
		aStart := aSelection from min: self text size.
		anEnd := aSelection to min: self text size.
		aSelectionStartSpan := self spanAtIndex: aStart.
		aSelectionEndSpan := self spanAtIndex: anEnd.
		aSelectionStartPosition := aStart isZero
			ifTrue: [ 0@0 ]
			ifFalse: [ (aSelectionStartSpan positionAt: aStart) + (aBlInsets left @ 0) ].
		aSelectionEndPosition := anEnd = self text size
			ifTrue: [ (aSelectionEndSpan positionAt: anEnd) + (aBlInsets width @ 0) ]
			ifFalse: [ (aSelectionEndSpan positionAt: anEnd) + (aBlInsets left @ 0) ].
		aSelectionBounds := (aSelection to > self text size)
			ifTrue: [ (aSelectionStartPosition x @ 0) corner: self containerExtent ]
			ifFalse: [ (aSelectionStartPosition x @ 0) corner: (aSelectionEndPosition x @ self containerExtent y) ].
		aCanvas fill
			paint: ((Color fromHexString: '00FFFF') alpha: 0.3);
			path: aSelectionBounds;
			draw ]
]
