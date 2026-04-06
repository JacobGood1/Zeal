Class {
	#name : 'VZealTheme',
	#superclass : 'ZealTheme',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'highlighting' }
VZealTheme class >> attachExpanders: text source: aString resolver: aResolver browser: aBrowser nested: isNested [
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
VZealTheme class >> backgroundColor [
	^ Color fromHexString: '17171F'
]

{ #category : 'colors' }
VZealTheme class >> braceColor [
	^ Color fromHexString: '4CC9F0'
]

{ #category : 'colors' }
VZealTheme class >> bracketColor [
	"Bright green for brackets — #50FA7B"
	^ Color fromHexString: '50FA7B'
]

{ #category : 'colors' }
VZealTheme class >> colonChainColor [
	^ Color fromHexString: '88DCF6'
]

{ #category : 'colors' }
VZealTheme class >> commentColor [
	^ Color fromHexString: 'A1A1BA'
]

{ #category : 'colors' }
VZealTheme class >> cursorAlpha [
	^ 0.5
]

{ #category : 'colors' }
VZealTheme class >> cursorColor [
	^ Color fromHexString: '00FFFF'
]

{ #category : 'colors' }
VZealTheme class >> cursorWidth [
	^ 8
]

{ #category : 'colors' }
VZealTheme class >> definitionNameColor [
	"Pink/purple for definition names"
	^ Color fromHexString: 'E876B0'
]

{ #category : 'colors' }
VZealTheme class >> foregroundColor [
	^ Color fromHexString: 'CDD7DC'
]

{ #category : 'highlighting' }
VZealTheme class >> highlightTokenAt: i in: aString text: text size: size [
	"Highlight one token starting at i, return next position."
	| ch start j word |
	ch := aString at: i.
	"Comments"
	ch = $; ifTrue: [
		start := i. j := i.
		[ j <= size and: [ (aString at: j) ~= Character cr and: [ (aString at: j) ~= Character lf ] ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self commentColor.
		^ j ].
	"Strings"
	ch = $" ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ (aString at: j) ~= $" ] ] whileTrue: [ j := j + 1 ].
		j <= size ifTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self stringColor.
		^ j ].
	"Parens"
	(ch = $( or: [ ch = $) ]) ifTrue: [
		(text from: i to: i) foreground: self parenColor. ^ i + 1 ].
	"Brackets"
	(ch = $[ or: [ ch = $] ]) ifTrue: [
		(text from: i to: i) foreground: self bracketColor. ^ i + 1 ].
	"Braces"
	(ch = ${ or: [ ch = $} ]) ifTrue: [
		(text from: i to: i) foreground: self braceColor. ^ i + 1 ].
	"Numbers"
	(ch isDigit or: [ ch = $- and: [ i + 1 <= size and: [ (aString at: i + 1) isDigit ] ] ]) ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ (aString at: j) isDigit or: [ (aString at: j) = $. or: [ (aString at: j) = $x ] ] ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self numberColor.
		^ j ].
	"Keywords :name"
	ch = $: ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ (aString at: j) isLetter or: [ (aString at: j) = $- ] ] ] whileTrue: [ j := j + 1 ].
		j > (start + 1)
			ifTrue: [ (text from: start to: j - 1) foreground: self keywordColor ]
			ifFalse: [ (text from: start to: start) foreground: self operatorColor ].
		^ j ].
	"Words: symbols, special forms, operators (@ is a word start in Verse)"
	(ch isLetter or: [ ch = $_ or: [ ch = $@ or: [ ch = $? ] ] ]) ifTrue: [
		start := i. j := i.
		[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ '_-?!/@' includes: c ] ] ] ] whileTrue: [ j := j + 1 ].
		word := aString copyFrom: start to: j - 1.
		"Colon chain name:type:spec"
		(j <= size and: [ (aString at: j) = $: ]) ifTrue: [
			[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ '_-?!/@:' includes: c ] ] ] ] whileTrue: [ j := j + 1 ].
			(text from: start to: j - 1) foreground: self colonChainColor. ^ j ].
		(self specialForms includes: word)
			ifTrue: [ (text from: start to: j - 1) foreground: self specialFormColor. ^ j ].
		(self operators includes: word)
			ifTrue: [ (text from: start to: j - 1) foreground: self operatorColor. ^ j ].
		(text from: start to: j - 1) foreground: self symbolColor. ^ j ].
	"Operator chars"
	('+-*/<>=!' includes: ch) ifTrue: [
		start := i. j := i.
		[ j <= size and: [ '+-*/<>=!' includes: (aString at: j) ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self operatorColor. ^ j ].
	"Skip"
	^ i + 1
]

{ #category : 'colors' }
VZealTheme class >> keywordColor [
	^ Color fromHexString: '69F0AE'
]

{ #category : 'colors' }
VZealTheme class >> numberColor [
	^ Color fromHexString: 'ACDBFF'
]

{ #category : 'colors' }
VZealTheme class >> operatorColor [
	"Bright cyan for operators — #8BE9FD"
	^ Color fromHexString: '8BE9FD'
]

{ #category : 'highlighting' }
VZealTheme class >> operators [
	^ #('+' '-' '*' '/' '=' '<>' '<' '>' '<=' '>=')
]

{ #category : 'colors' }
VZealTheme class >> parenColor [
	"Dimmed purple for parens — #9580FF"
	^ Color fromHexString: '9580FF'
]

{ #category : 'highlighting' }
VZealTheme class >> resolveExpander: word with: aResolver [
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
VZealTheme class >> selectionColor [
	^ self cursorColor alpha: 0.3
]

{ #category : 'colors' }
VZealTheme class >> specialFormColor [
	^ Color fromHexString: 'FF3D7F'
]

{ #category : 'highlighting' }
VZealTheme class >> specialForms [
	^ #('def' 'var' 'set' 'defn' 'defstruct' 'defenum' 'defclass' 'definterface' 'if' 'let' 'for' 'loop' 'block' 'defer' 'case' 'module' 'using' 'do' 'break' 'return')
]

{ #category : 'colors' }
VZealTheme class >> stringColor [
	^ Color fromHexString: '94FFCD'
]

{ #category : 'highlighting' }
VZealTheme class >> styler [
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
VZealTheme class >> symbolColor [
	"Light lilac purple for symbols — #D4AAFF"
	^ Color fromHexString: 'D4AAFF'
]
