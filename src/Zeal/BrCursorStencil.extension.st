Extension { #name : 'BrCursorStencil' }

{ #category : '*Zeal' }
BrCursorStencil >> create [
	^ BrCursorElement new
		constraintsDo: [ :c |
			c horizontal exact: 1.
			c vertical matchParent ];
		background: ZealDarkMode textColor
]
