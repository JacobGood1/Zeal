Class {
	#name : 'GDZealTextStyler',
	#superclass : 'BlTextStyler',
	#instVars : [
		'browser'
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

{ #category : 'styling' }
GDZealTextStyler >> privateStyle: aText [
	"Apply syntax highlighting and definition name coloring"
	| text source |
	text := (aText respondsTo: #text) ifTrue: [ aText text ] ifFalse: [ aText ].
	source := text asString.
	source isEmpty ifTrue: [ ^ aText ].
	self applySyntaxHighlighting: source to: text.
	^ aText
]
