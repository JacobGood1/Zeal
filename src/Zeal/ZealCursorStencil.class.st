Class {
	#name : 'ZealCursorStencil',
	#superclass : 'BrCursorStencil',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'building' }
ZealCursorStencil >> create [
	^ ZealCursorElement new
		constraintsDo: [ :c |
			c horizontal exact: 12.
			c vertical matchParent ];
		background: (Color fromHexString: '00FFFF');
		opacity: 1.0
]
