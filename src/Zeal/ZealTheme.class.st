Class {
	#name : 'ZealTheme',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'highlighting' }
ZealTheme class >> attachExpanders: text source: aString resolver: aResolver browser: aBrowser nested: isNested [
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
ZealTheme class >> backgroundColor [
	^ Color fromHexString: '17171F'
]

{ #category : 'colors' }
ZealTheme class >> braceColor [
	^ Color fromHexString: '4CC9F0'
]

{ #category : 'colors' }
ZealTheme class >> bracketColor [
	"Bright green for brackets — #50FA7B"
	^ Color fromHexString: '50FA7B'
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

{ #category : 'highlighting' }
ZealTheme class >> highlight: aString [
	"Tokenize and colorize Zeal source, return a BlRopedText with attributes."
	| text i size |
	text := aString asRopedText.
	text foreground: self symbolColor. "default color"
	i := 1.
	size := aString size.
	
	[ i <= size ] whileTrue: [
		| ch |
		ch := aString at: i.
		
		"Comments: ; to end of line"
		ch = $; ifTrue: [
			| start |
			start := i.
			[ i <= size and: [ (aString at: i) ~= Character cr and: [ (aString at: i) ~= Character lf ] ] ] 
				whileTrue: [ i := i + 1 ].
			(text from: start to: i - 1) foreground: self commentColor ]
		
		"Strings"
		ifFalse: [ ch = $" ifTrue: [
			| start |
			start := i. i := i + 1.
			[ i <= size and: [ (aString at: i) ~= $" ] ] whileTrue: [ i := i + 1 ].
			i <= size ifTrue: [ i := i + 1 ]. "past closing quote"
			(text from: start to: i - 1) foreground: self stringColor ]
		
		"Parens"
		ifFalse: [ ch = $( ifTrue: [ (text from: i to: i) foreground: self parenColor. i := i + 1 ]
		ifFalse: [ ch = $) ifTrue: [ (text from: i to: i) foreground: self parenColor. i := i + 1 ]
		
		"Brackets"
		ifFalse: [ ch = $[ ifTrue: [ (text from: i to: i) foreground: self bracketColor. i := i + 1 ]
		ifFalse: [ ch = $] ifTrue: [ (text from: i to: i) foreground: self bracketColor. i := i + 1 ]
		
		"Braces"
		ifFalse: [ ch = ${ ifTrue: [ (text from: i to: i) foreground: self braceColor. i := i + 1 ]
		ifFalse: [ ch = $} ifTrue: [ (text from: i to: i) foreground: self braceColor. i := i + 1 ]
		
		"Numbers"
		ifFalse: [ (ch isDigit or: [ch = $- and: [i + 1 <= size and: [(aString at: i + 1) isDigit]]]) ifTrue: [
			| start |
			start := i. i := i + 1.
			[ i <= size and: [ (aString at: i) isDigit or: [(aString at: i) = $. or: [(aString at: i) = $x]] ] ] whileTrue: [ i := i + 1 ].
			(text from: start to: i - 1) foreground: self numberColor ]
		
		"Keywords :else, :extends etc"
		ifFalse: [ ch = $: ifTrue: [
			| start |
			start := i. i := i + 1.
			[ i <= size and: [ (aString at: i) isLetter or: [(aString at: i) = $-] ] ] whileTrue: [ i := i + 1 ].
			i > (start + 1) ifTrue: [ (text from: start to: i - 1) foreground: self keywordColor ]
			ifFalse: [ (text from: start to: start) foreground: self operatorColor ] ]
		
		"Words: symbols, special forms, operators"
		ifFalse: [ (ch isLetter or: [ch = $_ or: [ch = $@ or: [ch = $?]]]) ifTrue: [
			| start word |
			start := i.
			[ i <= size and: [ 
				| c | c := aString at: i.
				c isLetter or: [c isDigit or: ['_-?!/@' includes: c]] ] ] whileTrue: [ i := i + 1 ].
			word := aString copyFrom: start to: i - 1.
			"Check if it has colons (colon chain like name:type:spec)"
			(i <= size and: [(aString at: i) = $:]) ifTrue: [
				"Scan the whole colon chain"
				[ i <= size and: [
					| c | c := aString at: i.
					c isLetter or: [c isDigit or: ['_-?!/@:' includes: c]] ] ] whileTrue: [ i := i + 1 ].
				(text from: start to: i - 1) foreground: self colonChainColor ]
			ifFalse: [
				(self specialForms includes: word)
					ifTrue: [ (text from: start to: i - 1) foreground: self specialFormColor ]
					ifFalse: [ (self operators includes: word)
						ifTrue: [ (text from: start to: i - 1) foreground: self operatorColor ]
						ifFalse: [ (text from: start to: i - 1) foreground: self symbolColor ] ] ] ]
		
		"Operators: + - * / = < > etc"
		ifFalse: [ ('+-*/<>=!' includes: ch) ifTrue: [
			| start |
			start := i.
			[ i <= size and: [ '+-*/<>=!' includes: (aString at: i) ] ] whileTrue: [ i := i + 1 ].
			(text from: start to: i - 1) foreground: self operatorColor ]
		
		"Everything else: skip"
		ifFalse: [ i := i + 1 ] ] ] ] ] ] ] ] ] ] ] ] ].
	
	^ text
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
	"Bright cyan for operators — #8BE9FD"
	^ Color fromHexString: '8BE9FD'
]

{ #category : 'language' }
ZealTheme class >> operators [
	^ #('+' '-' '*' '/' '=' '<>' '<' '>' '<=' '>=')
]

{ #category : 'colors' }
ZealTheme class >> parenColor [
	"Dimmed purple for parens — #9580FF"
	^ Color fromHexString: '9580FF'
]

{ #category : 'highlighting' }
ZealTheme class >> resolveExpander: word with: aResolver [
	"Resolve a word to a ZealNode for expanding. Handles:
	 - function calls: find-all → FindAll
	 - class constructors: were-cat → were_cat
	 - member access: obj/method → find method in any class"
	| node kebab pascal |
	
	"Member access: obj/method"
	(word includes: $/) ifTrue: [
		| methodPart methodPascal |
		methodPart := word copyAfterLast: $/.
		methodPascal := '' join: ((methodPart substrings: '-') collect: [:s | s capitalized]).
		node := aResolver findMethodAnywhere: methodPascal.
		^ node ].
	
	"Function: kebab-case → PascalCase"
	kebab := word copyReplaceAll: '/' with: '-'.
	pascal := '' join: ((kebab substrings: '-') collect: [:s | s capitalized]).
	node := aResolver findFunction: pascal.
	node ifNotNil: [ ^ node ].
	
	"Class: kebab-case → snake_case"
	node := aResolver findClass: (word copyReplaceAll: '-' with: '_').
	^ node
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
	"Light lilac purple for symbols — #D4AAFF"
	^ Color fromHexString: 'D4AAFF'
]
