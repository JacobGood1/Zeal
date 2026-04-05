Extension { #name : 'GtNotificationBorderElement' }

{ #category : '*Zeal' }
GtNotificationBorderElement >> initializeElement [
	self 
		background: ZealDarkMode contentBackground;
		padding: (BlInsets top: 5 right: 5 bottom: 0 left: 5)
]
