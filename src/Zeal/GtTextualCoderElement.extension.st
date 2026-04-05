Extension { #name : 'GtTextualCoderElement' }

{ #category : '*Zeal' }
GtTextualCoderElement >> onAddedToSceneGraph [
	super onAddedToSceneGraph.
	
	GtTextualCoderEditorElementAddedToSceneGraphSignal new 
		element: self;
		emit.
	
	"Immediately trigger restyling so syntax colors appear without delay"
	[ self styleText ] on: Error do: [ :e | ].
	
	"Fix dark icons in this coder element after aptitudes have applied"
	[ (Smalltalk globals at: #ZealDarkMode ifAbsent: [ nil ]) ifNotNil: [
		(BlTheme default isKindOf: BrGlamorousDarkTheme) ifTrue: [
			| iconColor |
			iconColor := Color white alpha: 0.75.
			self enqueueTask: (BlTaskAction new action: [
				self withAllChildrenBreadthFirstDo: [ :child |
					(child geometry class name = 'BlSvgPath') ifTrue: [
						| bg |
						bg := child background.
						(bg isKindOf: BlPaintBackground) ifTrue: [
							| c |
							c := bg paint color.
							((c respondsTo: #red) and: [ c red < 0.5 and: [ c green < 0.5 and: [ c blue < 0.5 and: [ c alpha > 0.3 ] ] ] ]) ifTrue: [
								child background: iconColor ] ] ] ] ]) ] ] ] on: Error do: [ :e | ]
]
