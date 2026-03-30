Class {
	#name : 'ZealExtensionCompletionStrategy',
	#superclass : 'ZealCompletionStrategy',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'private' }
ZealExtensionCompletionStrategy >> buildCandidates [
	"Only classes and interfaces"
	| result |
	result := Dictionary new.
	project ifNil: [ ^ result ].
	
	project modules do: [:mod |
		mod definitions do: [:ns |
			(ns respondsTo: #definitions) ifTrue: [
				ns definitions do: [:d |
					((d isKindOf: ZealClass) or: [d isKindOf: ZealInterface]) ifTrue: [
						((d respondsTo: #name) and: [d name notNil]) ifTrue: [
							result at: (self toKebab: d name) put: (d class name copyReplaceAll: 'Zeal' with: '') ] ] ] ] ] ].
	
	project externalModules do: [:mod |
		mod definitions do: [:d |
			((d isKindOf: ZealClass) or: [d isKindOf: ZealInterface]) ifTrue: [
				((d respondsTo: #name) and: [d name notNil]) ifTrue: [
					result at: (self toKebab: d name) put: (mod name , ' ' , (d class name copyReplaceAll: 'Zeal' with: '')) ] ] ] ].
	
	^ result
]

{ #category : 'completion' }
ZealExtensionCompletionStrategy >> completionPrefixAt: anInteger in: aText [
	"Extract prefix — handle comma-separated names"
	| text i start |
	text := aText asString.
	i := anInteger.
	[ i > 0 and: [
		| c |
		c := text at: i.
		c isLetter or: [c isDigit or: [c = $- or: [c = $_]]]
	] ] whileTrue: [ i := i - 1 ].
	start := i + 1.
	start > anInteger ifTrue: [ ^ '' ].
	^ text copyFrom: start to: anInteger
]
