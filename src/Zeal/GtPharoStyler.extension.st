Extension { #name : 'GtPharoStyler' }

{ #category : '*Zeal' }
GtPharoStyler >> parenthesesColors [
	"Light green parentheses for dark mode"
	^ { Color fromHexString: '#81C784' } "Material Green 300"
]

{ #category : '*Zeal' }
GtPharoStyler >> visitBinaryMessage: aBinaryMessage [
	aBinaryMessage selectorParts do: [:each |
		self
			attributes: { BlTextForegroundAttribute color: (Color fromHexString: '#E1BEE7') }
			from: each startPosition
			to: each stopPosition].
	^ super visitBinaryMessage: aBinaryMessage
]

{ #category : '*Zeal' }
GtPharoStyler >> visitKeywordMessage: aKeywordMessage [
	aKeywordMessage selectorParts do: [:each |
		self
			attributes: { BlTextForegroundAttribute color: (Color fromHexString: '#E1BEE7') }
			from: each startPosition
			to: each stopPosition].
	^ super visitKeywordMessage: aKeywordMessage
]

{ #category : '*Zeal' }
GtPharoStyler >> visitUnaryMessage: anUnaryMessage [
	anUnaryMessage selectorParts do: [:each |
		self
			attributes: { BlTextForegroundAttribute color: (Color fromHexString: '#E1BEE7') }
			from: each startPosition
			to: each stopPosition].
	^ super visitUnaryMessage: anUnaryMessage
]
