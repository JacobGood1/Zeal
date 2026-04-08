Class {
	#name : 'GDScriptTextStyler',
	#superclass : 'BlTextStyler',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'styling' }
GDScriptTextStyler >> privateStyle: aText [
	"Apply GDScript syntax highlighting to the editor text."
	| text source styled i max |
	text := (aText respondsTo: #text) ifTrue: [ aText text ] ifFalse: [ aText ].
	source := text asString.
	source isEmpty ifTrue: [ ^ aText ].
	"Walk source and apply colors directly on the live text rope (preserving identity)."
	text foreground: GDScriptTheme foregroundColor.
	i := 1.
	max := source size.
	[ i <= max ] whileTrue: [
		i := GDScriptTheme highlightTokenAt: i in: source text: text size: max ].
	^ aText
]
