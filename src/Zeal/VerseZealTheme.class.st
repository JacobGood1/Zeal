Class {
	#name : 'VerseZealTheme',
	#superclass : 'ZealTheme',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'highlighting' }
VerseZealTheme class >> attachExpanders: text source: aString resolver: aResolver browser: aBrowser nested: isNested [
	"Find function/class/method references and attach inline expanders."
	| i size |
	aResolver ifNil: [ ^ self ].
	
	i := 1. size := aString size.
	[ i < size ] whileTrue: [
		| ch |
		ch := aString at: i.
		(ch = $( and: [i + 1 <= size and: [(aString at: i + 1) isLetter]]) ifTrue: [
			| start end word node |
			start := i + 1. end := start.
			[ end <= size and: [
				| c | c := aString at: end.
				c isLetter or: [c isDigit or: [c = $- or: [c = $/]]]
			] ] whileTrue: [ end := end + 1 ].
			word := aString copyFrom: start to: end - 1.
			(self specialForms includes: word asLowercase) ifFalse: [
				node := self resolveExpander: word with: aResolver.
				node ifNotNil: [
					(text from: start to: end - 1) attribute: 
						(ZealExpanderAttribute forNode: node browser: aBrowser nested: isNested) ] ].
			i := end ]
		ifFalse: [
			"Also check bare member access: symbol/method (not after paren)"
			(ch isLetter and: [i > 1 and: [(aString at: i - 1) isSeparator]]) ifTrue: [
				| start end word |
				start := i. end := start.
				[ end <= size and: [
					| c | c := aString at: end.
					c isLetter or: [c isDigit or: [c = $- or: [c = $/]]]
				] ] whileTrue: [ end := end + 1 ].
				word := aString copyFrom: start to: end - 1.
				(word includes: $/) ifTrue: [
					| node |
					node := self resolveExpander: word with: aResolver.
					node ifNotNil: [
						| methodStart |
						methodStart := start + (word indexOf: $/).
						(text from: methodStart to: end - 1) attribute:
							(ZealExpanderAttribute forNode: node browser: aBrowser nested: isNested) ] ].
				i := end ]
			ifFalse: [ i := i + 1 ] ] ]
]

{ #category : 'colors' }
VerseZealTheme class >> backgroundColor [
	^ Color fromHexString: '17171F'
]

{ #category : 'colors' }
VerseZealTheme class >> braceColor [
	^ Color fromHexString: '4CC9F0'
]

{ #category : 'colors' }
VerseZealTheme class >> bracketColor [
	"Bright green for brackets — #50FA7B"
	^ Color fromHexString: '50FA7B'
]

{ #category : 'colors' }
VerseZealTheme class >> colonChainColor [
	^ Color fromHexString: '88DCF6'
]

{ #category : 'colors' }
VerseZealTheme class >> commentColor [
	^ Color fromHexString: 'A1A1BA'
]

{ #category : 'colors' }
VerseZealTheme class >> cursorAlpha [
	^ 0.5
]

{ #category : 'colors' }
VerseZealTheme class >> cursorColor [
	^ Color fromHexString: '00FFFF'
]

{ #category : 'colors' }
VerseZealTheme class >> cursorWidth [
	^ 8
]

{ #category : 'api' }
VerseZealTheme class >> dialectTokenColorFor: aWord [
	"Verse effect modifiers get the special-form color."
	^ (#('transacts' 'decides' 'suspends' 'varies' 'converges' 'computes') includes: aWord)
		ifTrue: [ self specialFormColor ]
		ifFalse: [ nil ]
]

{ #category : 'colors' }
VerseZealTheme class >> foregroundColor [
	^ Color fromHexString: 'CDD7DC'
]

{ #category : 'colors' }
VerseZealTheme class >> keywordColor [
	^ Color fromHexString: '69F0AE'
]

{ #category : 'colors' }
VerseZealTheme class >> numberColor [
	^ Color fromHexString: 'ACDBFF'
]

{ #category : 'colors' }
VerseZealTheme class >> operatorColor [
	"Bright cyan for operators — #8BE9FD"
	^ Color fromHexString: '8BE9FD'
]

{ #category : 'highlighting' }
VerseZealTheme class >> operators [
	^ #('+' '-' '*' '/' '=' '<>' '<' '>' '<=' '>=')
]

{ #category : 'colors' }
VerseZealTheme class >> parenColor [
	"Dimmed purple for parens — #9580FF"
	^ Color fromHexString: '9580FF'
]

{ #category : 'highlighting' }
VerseZealTheme class >> resolveExpander: word with: aResolver [
	"Resolve a word to a ZealNode for expanding. Returns nil if not found."
	| node kebab pascal |
	aResolver ifNil: [ ^ nil ].
	
	"Member access: obj/method"
	(word includes: $/) ifTrue: [
		| methodPart methodPascal |
		methodPart := word copyAfterLast: $/.
		methodPascal := '' join: ((methodPart substrings: '-') collect: [:s | s capitalized]).
		node := [aResolver findMethodAnywhere: methodPascal] on: Error do: [nil].
		^ node ].
	
	"Function: kebab-case → PascalCase"
	kebab := word copyReplaceAll: '/' with: '-'.
	pascal := '' join: ((kebab substrings: '-') collect: [:s | s capitalized]).
	node := [aResolver findFunction: pascal] on: Error do: [nil].
	node ifNotNil: [ ^ node ].
	
	"Class: kebab-case → snake_case"
	node := [aResolver findClass: (word copyReplaceAll: '-' with: '_')] on: Error do: [nil].
	^ node
]

{ #category : 'colors' }
VerseZealTheme class >> selectionColor [
	^ self cursorColor alpha: 0.3
]

{ #category : 'highlighting' }
VerseZealTheme class >> specialForms [
	^ #('def' 'var' 'set' 'defn' 'defstruct' 'defenum' 'defclass' 'definterface' 'if' 'let' 'for' 'loop' 'block' 'defer' 'case' 'module' 'using' 'do' 'break' 'return')
]

{ #category : 'colors' }
VerseZealTheme class >> stringColor [
	^ Color fromHexString: '94FFCD'
]

{ #category : 'highlighting' }
VerseZealTheme class >> styler [
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
VerseZealTheme class >> symbolColor [
	"Light lilac purple for symbols — #D4AAFF"
	^ Color fromHexString: 'D4AAFF'
]

{ #category : 'api' }
VerseZealTheme class >> typeInferencer [
	^ VerseZealTypeInferencer default
]
