Class {
	#name : 'GDZealTextStyler',
	#superclass : 'ZealTextStyler',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
GDZealTextStyler class >> new [
	^ super new
]

{ #category : 'styling' }
GDZealTextStyler >> applySyntaxHighlighting: aString to: text [
	"Delegate to GDZealTheme highlight: and copy attributes onto text"
	| highlighted |
	highlighted := GDZealTheme highlight: aString.
	1 to: aString size do: [ :i |
		(highlighted attributesAt: i) do: [ :a |
			(text from: i to: i) attribute: a ] ]
]

{ #category : 'accessing' }
GDZealTextStyler >> browser: aBrowser [
	browser := aBrowser
]

{ #category : 'styling' }
GDZealTextStyler >> privateStyle: aText [
	"Apply syntax highlighting. Also replaces standalone fn with λ in the actual
	 text so the source contains the real lambda character."
	| text source |
	text := (aText respondsTo: #text) ifTrue: [ aText text ] ifFalse: [ aText ].
	source := text asString.
	source isEmpty ifTrue: [ ^ aText ].
	self replaceFnWithLambda: text.
	source := text asString.
	self applySyntaxHighlighting: source to: text.
	^ aText
]

{ #category : 'styling' }
GDZealTextStyler >> replaceFnWithLambda: text [
	"Scan text for standalone fn tokens and replace with λ in-place."
	| src i size lambda |
	lambda := (Character value: 16r03BB) asString.
	src := text asString.
	i := 1.
	size := src size.
	[ i := src indexOfSubCollection: 'fn' startingAt: i.
	  i > 0 ] whileTrue: [
		| before after standalone |
		before := i > 1 ifTrue: [ src at: i - 1 ] ifFalse: [ $( ].
		after := (i + 1 < size) ifTrue: [ src at: i + 2 ] ifFalse: [ $) ].
		standalone := (before isLetter not and: [ before ~= $_ and: [ before ~= $- ] ])
			and: [ after isLetter not and: [ after ~= $_ and: [ after ~= $- ] ] ].
		standalone ifTrue: [
			text delete: i to: i + 1.
			text insertString: lambda at: i - 1.
			"Recalculate since text changed (one char shorter now)"
			src := text asString.
			size := src size ]
		ifFalse: [ i := i + 2 ] ]
]
