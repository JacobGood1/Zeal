Extension { #name : 'GtPostMortemSessionElement' }

{ #category : '*Zeal' }
GtPostMortemSessionElement >> newSummaryView [
	^ BrEditor new
		aptitude: BrGlamorousCodeEditorAptitude new + BrShadowAptitude new;
		background: ZealDarkMode contentBackground.
]
