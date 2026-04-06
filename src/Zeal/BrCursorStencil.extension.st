Extension { #name : 'BrCursorStencil' }

{ #category : '*Zeal' }
BrCursorStencil >> create [
	^ ZealCursorElement new
		constraintsDo: [ :c |
			c horizontal exact: 9.
			c vertical matchParent ];
		background: ZealTheme cursorColor
]
