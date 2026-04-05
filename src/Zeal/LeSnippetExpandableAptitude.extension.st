Extension { #name : 'LeSnippetExpandableAptitude' }

{ #category : '*Zeal' }
LeSnippetExpandableAptitude >> visuallyFocus [
	super visuallyFocus.
	snippetContainer effect: (BlGaussianShadowEffect
		color: (BrGlamorousColors primaryBorderColor)
		width: 2
		offset: 0 @ 1).
	snippetContainer background: self theme default contentBackground
]

{ #category : '*Zeal' }
LeSnippetExpandableAptitude >> visuallyHover [
	super visuallyHover.
	snippetContainer effect: (BlGaussianShadowEffect
		color: (BrGlamorousColors defaultShadowColor)
		width: 2
		offset: 0 @ 1).
	snippetContainer background: self theme default contentBackground
]
