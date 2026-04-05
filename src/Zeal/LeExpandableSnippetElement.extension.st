Extension { #name : 'LeExpandableSnippetElement' }

{ #category : '*Zeal' }
LeExpandableSnippetElement >> onAddedToSceneGraph [
	super onAddedToSceneGraph.
	[ (Smalltalk globals at: #ZealDarkMode ifAbsent: [ nil ]) ifNotNil: [ :dm |
		(BlTheme default isKindOf: BrGlamorousDarkTheme) ifTrue: [
			[ | bg c |
			bg := self background.
			(bg notNil and: [ bg isKindOf: BlPaintBackground ]) ifTrue: [
				c := bg paint color.
				(c notNil and: [ (c respondsTo: #red) and: [ c red > 0.8 and: [ c green > 0.8 and: [ c blue > 0.8 and: [ c alpha > 0.5 ] ] ] ] ]) ifTrue: [
					self background: dm contentBackground ] ] ] on: Error do: [ :e | ] ] ] ] on: Error do: [ :e | ]
]
