Class {
	#name : 'VZealTextStyler',
	#superclass : 'ZealTextStyler',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'styling' }
VZealTextStyler >> applyAdditionalStyles: source to: text [
	"Verse: add definition colors and expanders"
	self applyDefinitionColors: source to: text.
	project ifNotNil: [
		| resolver |
		resolver := ZealCompiler currentResolver ifNil: [ 
			ZealTypeResolver forProject: project ].
		self applyExpanders: source to: text resolver: resolver ]
]

{ #category : 'styling' }
VZealTextStyler >> applyCursorHighlight: aString to: text [
	"Add cursor highlight — single character under cursor turns white"
	1 to: aString size do: [:i |
		| ch |
		ch := aString at: i.
		ch isSeparator ifFalse: [
			(text from: i to: i) attribute: (BrTextCursorAttribute new
				enterAction: [:aTextEditor :anEvent :s :e | 
					(aTextEditor text from: s + 1 to: e + 1) foreground: Color white ];
				leaveAction: [:aTextEditor :anEvent :s :e | ]) ] ]
]

{ #category : 'styling' }
VZealTextStyler >> applyDefinitionColors: aString to: text [
	"Color definition names (after defn, defclass, etc) in pink/purple"
	| defForms i size |
	defForms := #('defn ' 'defclass ' 'definterface ' 'defstruct ' 'defenum ' 'def ' 'var ' 'set ').
	i := 1. size := aString size.
	[ i < size ] whileTrue: [
		| ch |
		ch := aString at: i.
		ch = $( ifTrue: [
			| afterParen matched |
			afterParen := i + 1.
			matched := false.
			defForms do: [:form |
				(matched not and: [afterParen + form size - 1 <= size]) ifTrue: [
					((aString copyFrom: afterParen to: afterParen + form size - 1) = form) ifTrue: [
						"Found a def form — color the name that follows"
						| nameStart nameEnd |
						nameStart := afterParen + form size.
						nameEnd := nameStart.
						[ nameEnd <= size and: [
							| c | c := aString at: nameEnd.
							c isLetter or: [c isDigit or: [c = $- or: [c = $_ or: [c = $/ or: [c = $:]]]]]
						] ] whileTrue: [ nameEnd := nameEnd + 1 ].
						nameEnd > nameStart ifTrue: [
							(text from: nameStart to: nameEnd - 1) foreground: ZealTheme definitionNameColor ].
						matched := true ] ] ].
			i := i + 1 ]
		ifFalse: [ i := i + 1 ] ]
]

{ #category : 'styling' }
VZealTextStyler >> applyExpanders: aString to: text resolver: aResolver [
	"Attach expander attributes to function/class/method references"
	| i size |
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
			(ZealTheme specialForms includes: word asLowercase) ifFalse: [
				node := ZealTheme resolveExpander: word with: aResolver.
				node ifNotNil: [
					(text from: start to: end - 1) attribute: 
						(ZealExpanderAttribute forNode: node browser: browser nested: true) ] ].
			i := end ]
		ifFalse: [
			(ch isLetter and: [i > 1 and: [(aString at: i - 1) isSeparator]]) ifTrue: [
				| start end word |
				start := i. end := start.
				[ end <= size and: [
					| c | c := aString at: end.
					c isLetter or: [c isDigit or: [c = $- or: [c = $/]]]
				] ] whileTrue: [ end := end + 1 ].
				word := aString copyFrom: start to: end - 1.
				(word includes: $/) ifTrue: [
					| node methodStart |
					node := ZealTheme resolveExpander: word with: aResolver.
					node ifNotNil: [
						methodStart := start + (word indexOf: $/).
						(text from: methodStart to: end - 1) attribute:
							(ZealExpanderAttribute forNode: node browser: browser nested: true) ] ].
				i := end ]
			ifFalse: [ i := i + 1 ] ] ]
]

{ #category : 'styling' }
VZealTextStyler >> applyFormHighlight: aString to: text [
	"No-op — form highlighting is now handled by the editor's cursor change listener"
]

{ #category : 'styling' }
VZealTextStyler >> project: aProject [
	project := aProject
]
