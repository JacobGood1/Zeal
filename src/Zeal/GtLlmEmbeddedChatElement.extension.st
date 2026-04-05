Extension { #name : 'GtLlmEmbeddedChatElement' }

{ #category : '*Zeal' }
GtLlmEmbeddedChatElement >> initialize [
	super initialize.
	self fitContent.
	self background: ZealDarkMode contentBackground.
	self layout: BlLinearLayout vertical.
	self addChildFirst: self toolbar
]
