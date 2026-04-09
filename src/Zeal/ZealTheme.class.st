Class {
	#name : 'ZealTheme',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'highlighting' }
ZealTheme class >> applyLambdaReplacement: text source: aString [
	"Replace visual appearance of standalone `fn` with λ. Uses a single
	 BrTextAdornmentDynamicAttribute spanning both chars so λ behaves as one
	 atomic unit for cursor/selection/copy. Source stays as fn underneath."
	| i size |
	i := 1.
	size := aString size.
	[ i := aString indexOfSubCollection: 'fn' startingAt: i.
	  i > 0 ] whileTrue: [
		| before after standalone |
		before := i > 1 ifTrue: [ aString at: i - 1 ] ifFalse: [ $( ].
		after := (i + 1 < size) ifTrue: [ aString at: i + 2 ] ifFalse: [ $) ].
		standalone := (before isLetter not and: [ before ~= $_ and: [ before ~= $- ] ])
			and: [ after isLetter not and: [ after ~= $_ and: [ after ~= $- ] ] ].
		standalone ifTrue: [
			(text from: i to: i + 1)
				attribute: (BrTextAdornmentDynamicAttribute new
					beReplace;
					stencil: [ BlTextElement new text: ('λ' asRopedText
						foreground: self specialFormColor;
						yourself) ]) ].
		i := i + 2 ]
]

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
ZealTheme class >> definitionNameColor [
	"Light purple for def/var names across all dialects"
	^ Color fromHexString: 'D4AAFF'
]

{ #category : 'colors' }
ZealTheme class >> foregroundColor [
	^ Color fromHexString: 'CDD7DC'
]

{ #category : 'highlighting' }
ZealTheme class >> highlight: aString [
	"Tokenize and colorize Zeal source, return a BlRopedText with attributes.
	 Template method — subclasses provide highlightTokenAt:in:text:size: and color accessors.
	 After highlighting, replaces visual fn with λ."
	| text i size |
	text := aString asRopedText.
	text foreground: self symbolColor.
	i := 1.
	size := aString size.
	[ i <= size ] whileTrue: [
		i := self highlightTokenAt: i in: aString text: text size: size ].
	self highlightDefinitionNames: aString text: text.
	self applyLambdaReplacement: text source: aString.
	^ text
]

{ #category : 'highlighting' }
ZealTheme class >> highlightDefinitionNames: aString text: text [
	"Color definition names and colon-chain name parts."
	| defForms size i |
	defForms := (self specialForms select: [ :f | f beginsWith: 'def' ]) asOrderedCollection.
	defForms addAll: #('def' 'var').
	size := aString size.
	"Pass 1: color definition names after def-forms"
	defForms do: [ :form |
		| searchFrom |
		searchFrom := 1.
		[ searchFrom <= size ] whileTrue: [
			| pos afterForm nameStart nameEnd |
			pos := aString findString: form startingAt: searchFrom.
			pos = 0 ifTrue: [ searchFrom := size + 1 ]
			ifFalse: [
				afterForm := pos + form size.
				"Verify preceded by ( or whitespace AND followed by whitespace (word boundary)"
				((pos = 1 or: [ '( ' includes: (aString at: pos - 1) ]) and: [
					afterForm > size or: [ (aString at: afterForm) isSeparator ] ]) ifTrue: [
					nameStart := afterForm.
					[ nameStart <= size and: [ (aString at: nameStart) isSeparator ] ] whileTrue: [ nameStart := nameStart + 1 ].
					nameEnd := nameStart.
					[ nameEnd <= size and: [ | c | c := aString at: nameEnd. c isLetter or: [ c isDigit or: [ '_-?!:/@' includes: c ] ] ] ] whileTrue: [ nameEnd := nameEnd + 1 ].
					nameEnd > nameStart ifTrue: [
						(text from: nameStart to: nameEnd - 1) foreground: self definitionNameColor ] ].
				searchFrom := afterForm ] ] ].
	"Pass 2: color colon chains — variable name purple, colons white"
	i := 1.
	[ i <= size ] whileTrue: [
		| ch |
		ch := aString at: i.
		(ch isLetter or: [ ch = $_ ]) ifTrue: [
			| start wordEnd |
			start := i.
			[ i <= size and: [ | c | c := aString at: i. c isLetter or: [ c isDigit or: [ '_-?!' includes: c ] ] ] ] whileTrue: [ i := i + 1 ].
			wordEnd := i - 1.
			(i <= size and: [ (aString at: i) = $: and: [ i + 1 <= size and: [ | nc | nc := aString at: i + 1. nc isLetter or: [ nc = $@ ] ] ] ]) ifTrue: [
				(text from: start to: wordEnd) foreground: self definitionNameColor.
				"Color colons white within the chain"
				[ i <= size and: [ | c | c := aString at: i. c isLetter or: [ c isDigit or: [ '_-?!/@:' includes: c ] ] ] ] whileTrue: [
					(aString at: i) = $: ifTrue: [ (text from: i to: i) foreground: Color white ].
					i := i + 1 ] ] ]
		ifFalse: [ i := i + 1 ] ]
]

{ #category : 'highlighting' }
ZealTheme class >> highlightTokenAt: i in: aString text: text size: size [
	"Default tokenizer — subclasses may override for dialect-specific tokens."
	self subclassResponsibility
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

{ #category : 'expanders' }
ZealTheme class >> resolveExpander: word with: aResolver [
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
ZealTheme class >> selectionColor [
	^ self cursorColor alpha: 0.3
]

{ #category : 'colors' }
ZealTheme class >> specialFormColor [
	"Green for all keywords/special forms across all dialects"
	^ self keywordColor
]

{ #category : 'syntax' }
ZealTheme class >> specialForms [
	^ #('def' 'var' 'set' 'defn' 'defstruct' 'defenum' 'defclass' 'definterface' 'defcomp' 'if' 'let' 'for' 'loop' 'block' 'defer' 'case' 'module' 'using' 'do' 'break' 'return')
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
