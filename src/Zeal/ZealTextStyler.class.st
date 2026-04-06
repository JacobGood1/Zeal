Class {
	#name : 'ZealTextStyler',
	#superclass : 'BlTextStyler',
	#instVars : [
		'project',
		'browser'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'styling' }
ZealTextStyler >> applyAdditionalStyles: source to: text [
	"Hook for dialect-specific additional styling. Default: nothing."
]

{ #category : 'styling' }
ZealTextStyler >> applySyntaxHighlighting: aString to: text [
	"Delegate to theme highlight: and copy attributes onto text"
	| highlighted |
	highlighted := self themeClass highlight: aString.
	1 to: aString size do: [ :i |
		(highlighted attributesAt: i) do: [ :a |
			(text from: i to: i) attribute: a ] ]
]

{ #category : 'accessing' }
ZealTextStyler >> browser: aBrowser [
	browser := aBrowser
]

{ #category : 'styling' }
ZealTextStyler >> privateStyle: aText [
	"Apply syntax highlighting. Subclasses add more via applyAdditionalStyles:to:"
	| text source |
	text := (aText respondsTo: #text) ifTrue: [ aText text ] ifFalse: [ aText ].
	source := text asString.
	source isEmpty ifTrue: [ ^ aText ].
	self applySyntaxHighlighting: source to: text.
	self applyAdditionalStyles: source to: text.
	^ aText
]

{ #category : 'hooks' }
ZealTextStyler >> themeClass [
	"Return the theme class. Subclasses override."
	^ browser ifNotNil: [ browser themeClass ] ifNil: [ ZealTheme ]
]
