Extension { #name : 'GtCodeDefinitionViewer' }

{ #category : '*Zeal' }
GtCodeDefinitionViewer >> initialize [
	super initialize.
	
	margin := BlInsets top: 3 left: 0 bottom: 3 right: 5.
	lookStencil := [ BrGlamorousEditableLabelAptitude new
		glamorousCodeFont;
		defaultForeground: ZealDarkMode textColor;
		fontSize: 10 ] asStencil.
]
