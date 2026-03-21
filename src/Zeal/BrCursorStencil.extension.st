Extension { #name : 'BrCursorStencil' }

{ #category : '*Zeal' }
BrCursorStencil >> create [
	^ BrCursorElement new
		constraintsDo: [ :c |
			c horizontal exact: ZealTheme cursorWidth.
			c vertical matchParent ];
		background: (ZealTheme cursorColor alpha: ZealTheme cursorAlpha);
		border: (BlBorder paint: ZealTheme cursorColor width: 1)
]
