Extension { #name : 'LeSnippetElement' }

{ #category : '*Zeal' }
LeSnippetElement >> onAddedToSceneGraph [
	super onAddedToSceneGraph.
	[ (Smalltalk globals at: #ZealDarkMode ifAbsent: [ nil ]) ifNotNil: [ :dm |
		(BlTheme default isKindOf: BrGlamorousDarkTheme) ifTrue: [
			"Fix white backgrounds immediately"
			self withAllChildrenBreadthFirstDo: [ :el |
				[ | bg c |
				bg := el background.
				(bg notNil and: [ bg isKindOf: BlPaintBackground ]) ifTrue: [
					c := bg paint color.
					(c notNil and: [ (c respondsTo: #red) and: [ c red > 0.8 and: [ c green > 0.8 and: [ c blue > 0.8 and: [ c alpha > 0.5 ] ] ] ] ]) ifTrue: [
						el background: dm contentBackground ] ]
				] on: Error do: [ :e | ] ].
			"Fix dark icons after aptitudes settle"
			self enqueueTask: (BlTaskAction new action: [
				[ | iconColor |
				iconColor := Color white alpha: 0.75.
				self withAllChildrenBreadthFirstDo: [ :el |
					(el geometry class name = 'BlSvgPath') ifTrue: [
						| bg |
						bg := el background.
						(bg isKindOf: BlPaintBackground) ifTrue: [
							| c |
							c := bg paint color.
							((c respondsTo: #red) and: [ c red < 0.5 and: [ c green < 0.5 and: [ c blue < 0.5 and: [ c alpha > 0.3 ] ] ] ]) ifTrue: [
								el background: iconColor ] ] ] ] ] on: Error do: [ :e | ] ]) ] ] ] on: Error do: [ :e | ]
]
