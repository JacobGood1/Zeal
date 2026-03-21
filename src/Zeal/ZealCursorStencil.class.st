Class {
	#name : 'ZealCursorStencil',
	#superclass : 'BrCursorStencil',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
ZealCursorStencil >> create [
	^ BrCursorElement new
		constraintsDo: [ :c |
			c horizontal exact: 12.
			c vertical matchParent ];
		background: (Color fromHexString: '00FFFF')
]
