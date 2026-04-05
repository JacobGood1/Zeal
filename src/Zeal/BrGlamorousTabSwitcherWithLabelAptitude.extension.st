Extension { #name : 'BrGlamorousTabSwitcherWithLabelAptitude' }

{ #category : '*Zeal' }
BrGlamorousTabSwitcherWithLabelAptitude >> initialize [
	super initialize.
	self add: (BrGlamorousTextLabelAptitude new 
		foreground: ZealDarkMode textColor).
			
	self addChangeProperty: #(widget geometry) with: [ 
		BlStadiumGeometry new ].
]
