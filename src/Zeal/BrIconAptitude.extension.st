Extension { #name : 'BrIconAptitude' }

{ #category : '*Zeal' }
BrIconAptitude >> icon: aStencilOrElement [
	self
		assert: [ aStencilOrElement isNotNil ]
		description: [ 'Icon must not be nil' ].
	iconElement := aStencilOrElement asElement.
	"Recolor dark icons for dark mode"
	(iconElement background isKindOf: BlPaintBackground) ifTrue: [
		| c |
		c := iconElement background paint color.
		((c respondsTo: #red) and: [c red < 0.5 and: [c green < 0.5 and: [c blue < 0.5 and: [c alpha > 0.5]]]]) ifTrue: [
			iconElement background: ZealDarkMode textColor]].
	self updateIcon
]

{ #category : '*Zeal' }
BrIconAptitude >> updateIcon [
	self widgetDo: [ 
		"Recolor dark icons for dark theme before inserting"
		((Smalltalk globals at: #ZealDarkMode ifAbsent: [ nil ]) notNil and: [
			BlTheme default isKindOf: BrGlamorousDarkTheme ]) ifTrue: [
				iconElement withAllChildrenBreadthFirstDo: [ :child |
					(child geometry class name = 'BlSvgPath') ifTrue: [
						| bg |
						bg := child background.
						(bg isKindOf: BlPaintBackground) ifTrue: [
							| c |
							c := bg paint color.
							((c respondsTo: #red) and: [ c red < 0.5 and: [ c green < 0.5 and: [ c blue < 0.5 and: [ c alpha > 0.3 ] ] ] ]) ifTrue: [
								child background: (Color white alpha: 0.75) ] ] ] ].
				(iconElement geometry class name = 'BlSvgPath') ifTrue: [
					| bg |
					bg := iconElement background.
					(bg isKindOf: BlPaintBackground) ifTrue: [
						| c |
						c := bg paint color.
						((c respondsTo: #red) and: [ c red < 0.5 and: [ c green < 0.5 and: [ c blue < 0.5 and: [ c alpha > 0.3 ] ] ] ]) ifTrue: [
							iconElement background: (Color white alpha: 0.75) ] ] ] ].
		self widgetContent
			childNamed: #icon
			ifFound: [ :anIconElement |
				| aParent anIndex |
				aParent := anIconElement parent.
				anIndex := aParent childIndexOf: anIconElement.
				anIconElement removeFromParent.
				iconElement removeFromParent.
				aParent addChild: iconElement at: anIndex as: #icon ]
			ifNone: [ self widgetContent addChild: iconElement as: #icon ] ]
]
