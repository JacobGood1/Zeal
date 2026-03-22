Class {
	#name : 'ZealCoderModel',
	#superclass : 'GtSourceCoder',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'opening' }
ZealCoderModel class >> openCyber77 [
	| coder element space |
	coder := self new.
	element := coder asCoderViewModel asExpandedOnlyElement.
	element background: ZealTheme backgroundColor.
	element allChildrenBreadthFirstDo: [:child |
		(child isKindOf: BrEditorElement) ifTrue: [ child background: ZealTheme backgroundColor ] ].
	space := BlSpace new.
	space title: 'Zeal // Cyber 77'.
	space extent: 900@700.
	space root background: ZealTheme backgroundColor.
	space root addChild: element.
	space show.
	^ coder
]

{ #category : 'converting' }
ZealCoderModel >> asCoderViewModel [
	^ ZealCoderViewModel new coder: self
]

{ #category : 'parsing' }
ZealCoderModel >> computeAst: theSourceString [
	^ ZealParser parseWithErrors: theSourceString
]

{ #category : 'initialization' }
ZealCoderModel >> initializeAddOns: addOns [
	super initializeAddOns: addOns.
	addOns addStyler: (GtCoderAstSmaCCParserStyler new smaccStyler: ZealTheme styler).
	addOns
		addMainAction: 'Compile' translated
		icon: BrGlamorousVectorIcons play
		action: [ :aCoderUIModel :anElement | 
			| source result |
			source := aCoderUIModel coderModel currentSourceString.
			result := ZealCompiler compile: source.
			result inspect ]
		id: #zealCompile.
	addOns
		addMainAction: 'Verse' translated
		icon: BrGlamorousVectorIcons playinspect
		action: [ :aCoderUIModel :anElement |
			| source result |
			source := aCoderUIModel coderModel currentSourceString.
			result := ZealCompiler compileToVerse: source.
			result inspect ]
		id: #zealVerse
]
