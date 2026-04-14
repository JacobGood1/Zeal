Class {
	#name : 'ZealExpanderAptitude',
	#superclass : 'BrGlamorousExpanderAptitude',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'initialization' }
ZealExpanderAptitude >> initialize [
	| aShadowLook btnBg borderColor |
	super initialize.
	btnBg := BrGlamorousColors defaultButtonBackgroundColor.
	borderColor := Color fromHexString: '444444'.
	"Patch the sidebar (the bar with the triangle) to use dark theme colors"
	sidebar background: btnBg.
	"Override the collapsed/expanded styles that use light colors"
	self add: (BrStyleCommonAptitude new
		collapsed: [ :aStyle |
			aStyle border: (BlBorder paint: borderColor width: 1) ];
		expanded: [ :aStyle |
			aStyle background: btnBg darker.
			aStyle border: (BlBorder paint: borderColor width: 1) ])
]
