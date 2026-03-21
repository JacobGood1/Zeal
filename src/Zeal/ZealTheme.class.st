Class {
	#name : 'ZealTheme',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'colors' }
ZealTheme class >> backgroundColor [
	^ Color fromHexString: '17171F'
]

{ #category : 'colors' }
ZealTheme class >> braceColor [
	^ Color fromHexString: '4CC9F0'
]

{ #category : 'colors' }
ZealTheme class >> bracketColor [
	^ Color fromHexString: 'FF9C75'
]

{ #category : 'colors' }
ZealTheme class >> colonChainColor [
	^ Color fromHexString: '88DCF6'
]

{ #category : 'colors' }
ZealTheme class >> commentColor [
	^ Color fromHexString: 'A1A1BA'
]

{ #category : 'dimensions' }
ZealTheme class >> cursorAlpha [
	^ 0.5
]

{ #category : 'colors' }
ZealTheme class >> cursorColor [
	^ Color fromHexString: '00FFFF'
]

{ #category : 'dimensions' }
ZealTheme class >> cursorWidth [
	^ 8
]

{ #category : 'colors' }
ZealTheme class >> foregroundColor [
	^ Color fromHexString: 'CDD7DC'
]

{ #category : 'colors' }
ZealTheme class >> keywordColor [
	^ Color fromHexString: '69F0AE'
]

{ #category : 'colors' }
ZealTheme class >> numberColor [
	^ Color fromHexString: 'ACDBFF'
]

{ #category : 'colors' }
ZealTheme class >> operatorColor [
	^ Color fromHexString: 'FFC19A'
]

{ #category : 'language' }
ZealTheme class >> operators [
	^ #('+' '-' '*' '/' '=' '<>' '<' '>' '<=' '>=')
]

{ #category : 'colors' }
ZealTheme class >> parenColor [
	^ Color fromHexString: 'FFF9B8'
]

{ #category : 'colors' }
ZealTheme class >> selectionColor [
	^ self cursorColor alpha: 0.3
]

{ #category : 'colors' }
ZealTheme class >> specialFormColor [
	^ Color fromHexString: 'FF3D7F'
]

{ #category : 'language' }
ZealTheme class >> specialForms [
	^ #('def' 'var' 'set' 'defn' 'defstruct' 'defenum' 'defclass' 'definterface' 'if' 'let' 'for' 'loop' 'block' 'defer' 'case' 'module' 'using' 'do' 'break' 'return')
]

{ #category : 'colors' }
ZealTheme class >> stringColor [
	^ Color fromHexString: '94FFCD'
]

{ #category : 'styling' }
ZealTheme class >> styler [
	| styler |
	styler := GtSmaCCParserStyler forParser: ZealParser.
	styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: '<comment>' styleBlock: [:s | s foreground: self commentColor]).
	styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: '<string>' styleBlock: [:s | s foreground: self stringColor]).
	#('<integer>' '<float>' '<hex>' '<range>') do: [:tok |
		styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: tok styleBlock: [:s | s foreground: self numberColor]) ].
	styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: '<keyword>' styleBlock: [:s | s foreground: self keywordColor]).
	styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: '<colonChain>' styleBlock: [:s | s foreground: self colonChainColor]).
	styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: '<symbol>' styleBlock: [:s :token |
		| val |
		val := token value.
		(self specialForms includes: val)
			ifTrue: [ s foreground: self specialFormColor ]
			ifFalse: [ (self operators includes: val)
				ifTrue: [ s foreground: self operatorColor ]
				ifFalse: [ s foreground: self symbolColor ] ] ]).
	#('<leftParen>' '<rightParen>') do: [:tok |
		styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: tok styleBlock: [:s | s foreground: self parenColor]) ].
	#('<leftBracket>' '<rightBracket>') do: [:tok |
		styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: tok styleBlock: [:s | s foreground: self bracketColor]) ].
	#('<leftBrace>' '<rightBrace>') do: [:tok |
		styler addStylerRule: (GtSmaCCTokenStylerRule tokenName: tok styleBlock: [:s | s foreground: self braceColor]) ].
	^ styler
]

{ #category : 'colors' }
ZealTheme class >> symbolColor [
	^ Color fromHexString: 'DCDCAA'
]
