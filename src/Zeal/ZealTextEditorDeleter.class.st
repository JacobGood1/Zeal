Class {
	#name : 'ZealTextEditorDeleter',
	#superclass : 'BrTextEditorDeleter',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'deleting' }
ZealTextEditorDeleter >> oneBeforeCursor: aCursor [
	"Delete one symbol before cursor. If the cursor is at or after a standalone fn
	 token (which renders as lambda), delete both f and n in one keystroke."
	| pos src |
	pos := aCursor position.
	src := editor text asString.
	"Check fn at [pos-1, pos] — cursor right after n"
	(pos >= 2 and: [ pos <= src size and: [
		(src at: pos - 1) = $f and: [ (src at: pos) = $n ] ] ]) ifTrue: [
			| before after standalone |
			before := pos > 2 ifTrue: [ src at: pos - 2 ] ifFalse: [ $( ].
			after := (pos + 1 <= src size) ifTrue: [ src at: pos + 1 ] ifFalse: [ $) ].
			standalone := (before isLetter not and: [ before ~= $_ and: [ before ~= $- ] ])
				and: [ after isLetter not and: [ after ~= $_ and: [ after ~= $- ] ] ].
			standalone ifTrue: [
				self from: pos - 2 to: pos.
				^ self ] ].
	"Check fn at [pos, pos+1] — cursor between f and n"
	(pos >= 1 and: [ (pos + 1) <= src size and: [
		(src at: pos) = $f and: [ (src at: pos + 1) = $n ] ] ]) ifTrue: [
			| before after standalone |
			before := pos > 1 ifTrue: [ src at: pos - 1 ] ifFalse: [ $( ].
			after := (pos + 2 <= src size) ifTrue: [ src at: pos + 2 ] ifFalse: [ $) ].
			standalone := (before isLetter not and: [ before ~= $_ and: [ before ~= $- ] ])
				and: [ after isLetter not and: [ after ~= $_ and: [ after ~= $- ] ] ].
			standalone ifTrue: [
				self from: pos - 1 to: pos + 1.
				^ self ] ].
	"Default behavior"
	super oneBeforeCursor: aCursor
]
