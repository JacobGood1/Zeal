Extension { #name : 'BrCursorStencil' }

{ #category : '*Zeal' }
BrCursorStencil >> create [
	^ ZealCursorElement new
		constraintsDo: [ :c |
			c horizontal exact: 12.
			c vertical matchParent ];
		background: ((Color fromHexString: '00FFFF') alpha: 0.4);
		opacity: 1.0
]
