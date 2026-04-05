Extension { #name : 'BrGlamorousSpaceTabWithLabelAptitude' }

{ #category : '*Zeal' }
BrGlamorousSpaceTabWithLabelAptitude >> initialize [
	super initialize.
	
	self add: (BrGlamorousTextLabelAptitude new foreground: ZealDarkMode textColor).
	self add: BrGlamorousSpaceTabBasicAptitude new.
]
