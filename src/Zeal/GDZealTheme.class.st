Class {
	#name : 'GDZealTheme',
	#superclass : 'ZealTheme',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'colors' }
GDZealTheme class >> backgroundColor [
	^ Color fromHexString: '17171F'
]

{ #category : 'colors' }
GDZealTheme class >> braceColor [
	^ Color fromHexString: '4CC9F0'
]

{ #category : 'colors' }
GDZealTheme class >> bracketColor [
	^ Color fromHexString: '50FA7B'
]

{ #category : 'colors' }
GDZealTheme class >> classRefColor [
	"Color for @name class references — Godot blue"
	^ Color fromHexString: '6FBBF5'
]

{ #category : 'colors' }
GDZealTheme class >> colonChainColor [
	^ Color fromHexString: '88DCF6'
]

{ #category : 'colors' }
GDZealTheme class >> commentColor [
	^ Color fromHexString: 'A1A1BA'
]

{ #category : 'colors' }
GDZealTheme class >> cursorAlpha [
	^ 0.5
]

{ #category : 'colors' }
GDZealTheme class >> cursorColor [
	^ Color cyan
]

{ #category : 'colors' }
GDZealTheme class >> cursorWidth [
	^ 8
]

{ #category : 'colors' }
GDZealTheme class >> foregroundColor [
	^ Color fromHexString: 'CDD7DC'
]

{ #category : 'highlighting' }
GDZealTheme class >> highlight: aString [
	"Tokenize and colorize GDZeal source, return a BlRopedText with attributes."
	| text i size |
	text := aString asRopedText.
	text foreground: self symbolColor.
	i := 1.
	size := aString size.
	[ i <= size ] whileTrue: [
		i := self highlightTokenAt: i in: aString text: text size: size ].
	self highlightDefinitionNames: aString text: text.
	^ text
]

{ #category : 'highlighting' }
GDZealTheme class >> highlightTokenAt: i in: aString text: text size: size [
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
		[ j <= size and: [ (aString at: j) ~= $" ] ] whileTrue: [
			(aString at: j) = $\ ifTrue: [ j := j + 1 ]. j := j + 1 ].
		j <= size ifTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self stringColor.
		^ j ].
	"Parens"
	('()' includes: ch) ifTrue: [
		(text from: i to: i) foreground: self parenColor. ^ i + 1 ].
	"Brackets"
	('[]' includes: ch) ifTrue: [
		(text from: i to: i) foreground: self bracketColor. ^ i + 1 ].
	"Braces"
	('{}' includes: ch) ifTrue: [
		(text from: i to: i) foreground: self braceColor. ^ i + 1 ].
	"Numbers"
	(ch isDigit or: [ ch = $- and: [ i + 1 <= size and: [ (aString at: i + 1) isDigit ] ] ]) ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ (aString at: j) isDigit or: [ '.xabcdefABCDEF' includes: (aString at: j) ] ] ] whileTrue: [ j := j + 1 ].
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
	"@class references"
	ch = $@ ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ '_-/@' includes: c ] ] ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self classRefColor.
		^ j ].
	"Words"
	(ch isLetter or: [ ch = $_ or: [ ch = $? ] ]) ifTrue: [
		start := i. j := i.
		[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ '_-?!/@' includes: c ] ] ] ] whileTrue: [ j := j + 1 ].
		word := aString copyFrom: start to: j - 1.
		(j <= size and: [ (aString at: j) = $: ]) ifTrue: [
			[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ '_-?!/@:' includes: c ] ] ] ] whileTrue: [ j := j + 1 ].
			(text from: start to: j - 1) foreground: self colonChainColor. ^ j ].
		(self specialForms includes: word) ifTrue: [
			(text from: start to: j - 1) foreground: self specialFormColor. ^ j ].
		(self operators includes: word) ifTrue: [
			(text from: start to: j - 1) foreground: self operatorColor. ^ j ].
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
GDZealTheme class >> keywordColor [
	^ Color fromHexString: '69F0AE'
]

{ #category : 'colors' }
GDZealTheme class >> numberColor [
	^ Color fromHexString: 'ACDBFF'
]

{ #category : 'colors' }
GDZealTheme class >> operatorColor [
	^ Color fromHexString: '8BE9FD'
]

{ #category : 'tokens' }
GDZealTheme class >> operators [
	^ #('+' '-' '*' '/' '=' '<>' '<' '>' '<=' '>=' '+=' '-=' '*=' '/=' '%' 'and' 'or' 'not')
]

{ #category : 'colors' }
GDZealTheme class >> parenColor [
	^ Color fromHexString: '9580FF'
]

{ #category : 'colors' }
GDZealTheme class >> selectionColor [
	^ self cursorColor alpha: 0.3
]

{ #category : 'tokens' }
GDZealTheme class >> specialForms [
	^ #('def' 'var' 'set' 'defn' 'defcomp' 'defcosystem' 'defco' 'defentity' 'defsystem' 'defobserver' 'if' 'when' 'let' 'for' 'match' 'do' 'return' 'as' 'export' 'init' 'query' 'process' 'components' 'watch' 'deps' 'setup' 'on-ready' 'on-destroy' 'on-enable' 'on-disable' 'on-added' 'on-removed' 'on-changed' 'with-all' 'with-any' 'with-none' 'iterate' 'enabled' 'disabled' 'wait' 'loop' 'sync' 'race')
]

{ #category : 'colors' }
GDZealTheme class >> stringColor [
	^ Color fromHexString: '94FFCD'
]

{ #category : 'colors' }
GDZealTheme class >> symbolColor [
	^ Color fromHexString: 'D4AAFF'
]
