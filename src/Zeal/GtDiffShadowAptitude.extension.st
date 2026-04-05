Extension { #name : 'GtDiffShadowAptitude' }

{ #category : '*Zeal' }
GtDiffShadowAptitude >> newShadowLook [
	^ BrStyleCommonAptitude new
		default: [ :aStyle |
			aStyle
				background: ZealDarkMode contentBackground;
				effect: BrGlamorousShadowEffect new ];
		yourself
]
