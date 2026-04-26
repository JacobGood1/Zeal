Class {
	#name : 'ZealSymbolNode',
	#superclass : 'ZealProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealSymbolNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitSymbol: self
]

{ #category : 'paths' }
ZealSymbolNode >> isPathSymbol [
	"True iff this symbol's text is a slash-separated path with non-empty,
	 well-formed segments. The first segment must be a name (letter-led, not
	 all-digits) so the division operator and numeric expressions stay regular
	 symbols. Returns false for: `/`, `/a`, `a/`, `a//b`, `1/x`."
	| s parts firstSeg |
	s := self value value.
	(s isKindOf: String) ifFalse: [ ^ false ].
	(s includes: $/) ifFalse: [ ^ false ].
	parts := $/ split: s.
	parts size < 2 ifTrue: [ ^ false ].
	(parts anySatisfy: [ :seg | seg isEmpty ]) ifTrue: [ ^ false ].
	firstSeg := parts first.
	(firstSeg allSatisfy: [ :c | c isDigit ]) ifTrue: [ ^ false ].
	"First segment can't begin with : or @ either — only subsequent segments
	 can be keyword/cast forms."
	(#($: $@) includes: firstSeg first) ifTrue: [ ^ false ].
	^ true
]

{ #category : 'paths' }
ZealSymbolNode >> pathSegments [
	"Return an OrderedCollection of segment dictionaries, one per `/`-separated
	 piece of this symbol's text. Each dict has #kind and #text:
	   - first segment: kind=#root, text=raw
	   - leading `:` → kind=#keyword, text=stripped of `:`
	   - leading `@` → kind=#cast, text=stripped of `@` (cast applies to the
	                                     prev result)
	   - all-digits → kind=#index, text=raw
	   - else → kind=#name, text=raw
	 Returns empty for non-path symbols."
	| s parts result |
	self isPathSymbol ifFalse: [ ^ OrderedCollection new ].
	s := self value value.
	parts := $/ split: s.
	result := OrderedCollection new.
	parts doWithIndex: [ :seg :i |
		| kind text |
		i = 1 ifTrue: [
			kind := #root.
			text := seg ]
		ifFalse: [
			seg first = $:
				ifTrue: [ kind := #keyword. text := seg allButFirst ]
			ifFalse: [ seg first = $@
				ifTrue: [ kind := #cast. text := seg allButFirst ]
			ifFalse: [ (seg allSatisfy: [ :c | c isDigit ])
				ifTrue: [ kind := #index. text := seg ]
				ifFalse: [ kind := #name. text := seg ] ] ] ].
		result add: (Dictionary new
			at: #kind put: kind;
			at: #text put: text;
			yourself) ].
	^ result
]

{ #category : 'generated' }
ZealSymbolNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
ZealSymbolNode >> value [
	^ value
]

{ #category : 'generated' }
ZealSymbolNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
