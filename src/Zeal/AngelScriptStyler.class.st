Class {
	#name : 'AngelScriptStyler',
	#superclass : 'BlTextStyler',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'styling' }
AngelScriptStyler >> color: aText from: start to: stop with: aColor [
	"Paint a slice of aText with foreground aColor. Bounds-checked."
	| safeStop |
	safeStop := stop min: aText size.
	start <= safeStop ifTrue: [
		(aText from: start to: safeStop) foreground: aColor ]
]

{ #category : 'styling' }
AngelScriptStyler >> colorizeIn: text source: source [
	"Single-pass tokenizer. Handles line + block comments, strings, numbers,
	 primitive types, declaration keywords, control keywords, PascalCase
	 class refs, and falls through to plain text."
	| i size types decls ctrls start word ch |
	types := self primitiveTypes.
	decls := self declarationKeywords.
	ctrls := self controlKeywords.
	i := 1. size := source size.
	[ i <= size ] whileTrue: [
		ch := source at: i.
		"--- // line comment ---"
		(ch = $/ and: [ i < size and: [ (source at: i + 1) = $/ ] ]) ifTrue: [
			start := i.
			[ i <= size and: [ (source at: i) ~= Character lf and: [ (source at: i) ~= Character cr ] ] ]
				whileTrue: [ i := i + 1 ].
			self color: text from: start to: i - 1 with: ZealTheme commentColor ] ifFalse: [
		"--- /* block comment */ ---"
		(ch = $/ and: [ i < size and: [ (source at: i + 1) = $* ] ]) ifTrue: [
			start := i. i := i + 2.
			[ i + 1 <= size and: [ ((source at: i) = $* and: [ (source at: i + 1) = $/ ]) not ] ]
				whileTrue: [ i := i + 1 ].
			i := i + 2.
			self color: text from: start to: (i - 1 min: size) with: ZealTheme commentColor ] ifFalse: [
		"--- string ---"
		ch = $" ifTrue: [
			start := i. i := i + 1.
			[ i <= size and: [ (source at: i) ~= $" ] ] whileTrue: [
				((source at: i) = $\ and: [ i < size ]) ifTrue: [ i := i + 1 ].
				i := i + 1 ].
			i := i + 1.
			self color: text from: start to: (i - 1 min: size) with: ZealTheme stringColor ] ifFalse: [
		"--- number ---"
		ch isDigit ifTrue: [
			start := i.
			[ i <= size and: [ (source at: i) isDigit or: [ (source at: i) = $. or: [ (source at: i) = $f ] ] ] ]
				whileTrue: [ i := i + 1 ].
			self color: text from: start to: i - 1 with: ZealTheme numberColor ] ifFalse: [
		"--- identifier / keyword ---"
		(ch isLetter or: [ ch = $_ ]) ifTrue: [
			start := i.
			[ i <= size and: [ ((source at: i) isLetter or: [ (source at: i) isDigit or: [ (source at: i) = $_ ] ]) ] ]
				whileTrue: [ i := i + 1 ].
			word := source copyFrom: start to: i - 1.
			(types includes: word) ifTrue: [
				self color: text from: start to: i - 1 with: ZealTheme typeColor ] ifFalse: [
			(decls includes: word) ifTrue: [
				self color: text from: start to: i - 1 with: ZealTheme keywordColor ] ifFalse: [
			(ctrls includes: word) ifTrue: [
				self color: text from: start to: i - 1 with: ZealTheme specialFormColor ] ifFalse: [
			(word notEmpty and: [ word first isUppercase ]) ifTrue: [
				self color: text from: start to: i - 1 with: ZealTheme classRefColor ] ] ] ] ] ifFalse: [
		"--- whitespace / punctuation: just advance ---"
		i := i + 1 ] ] ] ] ] ]
]

{ #category : 'styling' }
AngelScriptStyler >> controlKeywords [
	"Control flow + literal-like keywords."
	^ #('if' 'else' 'while' 'for' 'do' 'switch' 'case' 'break'
		'continue' 'return' 'true' 'false' 'null' 'this' 'super'
		'in' 'is' 'cast') asSet
]

{ #category : 'styling' }
AngelScriptStyler >> declarationKeywords [
	"Things that introduce a definition / scope or are modifiers on one."
	^ #('class' 'struct' 'enum' 'namespace' 'interface' 'const'
		'final' 'override' 'abstract' 'private' 'protected' 'public'
		'mixin' 'shared' 'import' 'funcdef' 'typedef' 'external') asSet
]

{ #category : 'styling' }
AngelScriptStyler >> primitiveTypes [
	^ #('int' 'float' 'bool' 'void' 'string' 'auto' 'double'
		'int8' 'int16' 'int32' 'int64'
		'uint' 'uint8' 'uint16' 'uint32' 'uint64'
		'array' 'dictionary') asSet
]

{ #category : 'styling' }
AngelScriptStyler >> privateStyle: aText [
	"Apply AngelScript syntax highlighting using ZealTheme colors so the
	 output language theming matches the Zeal source theming."
	| text source |
	text := (aText respondsTo: #text) ifTrue: [ aText text ] ifFalse: [ aText ].
	source := text asString.
	source isEmpty ifTrue: [ ^ aText ].
	self colorizeIn: text source: source.
	^ aText
]
