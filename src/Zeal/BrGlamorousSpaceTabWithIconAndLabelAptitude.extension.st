Extension { #name : 'BrGlamorousSpaceTabWithIconAndLabelAptitude' }

{ #category : '*Zeal' }
BrGlamorousSpaceTabWithIconAndLabelAptitude >> initialize [
	super initialize.
	
	self add: BrGlamorousSpaceTabIconAptitude new.
	self add: (BrGlamorousTextLabelAptitude new foreground: ZealDarkMode textColor).
	self add: BrGlamorousSpaceTabBasicAptitude new.
]
