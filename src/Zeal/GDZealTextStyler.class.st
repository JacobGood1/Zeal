Class {
	#name : 'GDZealTextStyler',
	#superclass : 'ZealTextStyler',
	#instVars : [
		'editorElement'
	],
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

{ #category : 'accessing' }
GDZealTextStyler >> editorElement [
	^ editorElement
]

{ #category : 'accessing' }
GDZealTextStyler >> editorElement: aBrEditor [
	editorElement := aBrEditor
]

{ #category : 'styling' }
GDZealTextStyler >> privateStyle: aText [
	"Apply syntax highlighting. If the source contains standalone fn, schedule
	 a deferred replacement (fn→λ) on the editor after styling completes."
	| text source |
	text := (aText respondsTo: #text) ifTrue: [ aText text ] ifFalse: [ aText ].
	source := text asString.
	source isEmpty ifTrue: [ ^ aText ].
	self applySyntaxHighlighting: source to: text.
	"Check if source has a standalone fn that needs replacing"
	(self sourceHasStandaloneFn: source) ifTrue: [
		self scheduleFnReplacement ].
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

{ #category : 'lambda' }
GDZealTextStyler >> scheduleFnReplacement [
	"Schedule a deferred task to replace fn→λ in the editor text."
	| lambda el |
	lambda := (Character value: 16r03BB) asString.
	el := editorElement.
	el ifNil: [ ^ self ].
	el enqueueTask: (BlTaskAction new action: [
		| ed src i |
		ed := el editor.
		src := ed text asString.
		i := 1.
		[ i := src indexOfSubCollection: 'fn' startingAt: i.
		  i > 0 ] whileTrue: [
			| before after standalone |
			before := i > 1 ifTrue: [ src at: i - 1 ] ifFalse: [ $( ].
			after := (i + 1 < src size) ifTrue: [ src at: i + 2 ] ifFalse: [ $) ].
			standalone := (before isLetter not and: [ before ~= $_ and: [ before ~= $- ] ])
				and: [ after isLetter not and: [ after ~= $_ and: [ after ~= $- ] ] ].
			standalone ifTrue: [
				ed deleter from: i - 1 to: i + 1; delete.
				ed inserter string: lambda; at: i - 1; withoutCursorUpdate; insert.
				src := ed text asString ]
			ifFalse: [ i := i + 2 ] ] ])
]

{ #category : 'lambda' }
GDZealTextStyler >> sourceHasStandaloneFn: src [
	"True if src contains at least one standalone fn token."
	| i size |
	i := 1.
	size := src size.
	[ i := src indexOfSubCollection: 'fn' startingAt: i.
	  i > 0 ] whileTrue: [
		| before after |
		before := i > 1 ifTrue: [ src at: i - 1 ] ifFalse: [ $( ].
		after := (i + 1 < size) ifTrue: [ src at: i + 2 ] ifFalse: [ $) ].
		((before isLetter not and: [ before ~= $_ and: [ before ~= $- ] ])
			and: [ after isLetter not and: [ after ~= $_ and: [ after ~= $- ] ] ])
				ifTrue: [ ^ true ].
		i := i + 2 ].
	^ false
]
