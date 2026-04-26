Class {
	#name : 'ZealPathSymbolExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'helpers' }
ZealPathSymbolExamples >> assert: actual equals: expected label: label [
	actual = expected ifTrue: [ ^ self ].
	^ self error: label , ' — expected ' , expected printString
		, ' but got ' , actual printString
]

{ #category : 'helpers' }
ZealPathSymbolExamples >> assert: aBoolean label: label [
	aBoolean ifTrue: [ ^ self ].
	^ self error: label , ' — expected true but got false'
]

{ #category : 'helpers' }
ZealPathSymbolExamples >> parseSymbol: aString [
	"Parse aString and return its first ZealSymbolNode. Fails if the input
	 doesn't tokenize as a single symbol."
	| node |
	node := (ZealParser parse: aString) expressions first.
	(node isKindOf: ZealSymbolNode) ifFalse: [
		^ self error: aString , ' did not parse as a single symbol; got '
			, node class name ].
	^ node
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathCastSegment [
	"`a/@some-cast` — cast segment retains text without the leading @."
	<gtExample>
	| sym segs |
	sym := self parseSymbol: 'a/@some-cast'.
	segs := sym pathSegments.
	self assert: segs size equals: 2 label: 'two segments'.
	self assert: (segs second at: #kind) equals: #cast label: 'second is cast'.
	self assert: (segs second at: #text) equals: 'some-cast' label: '@ stripped from text'.
	^ sym
]

{ #category : 'examples-negative' }
ZealPathSymbolExamples >> pathDivisionOperator [
	"`/` alone is the division operator, NOT a path."
	<gtExample>
	| sym |
	sym := self parseSymbol: '/'.
	self assert: sym isPathSymbol equals: false label: '/ is not a path'.
	self assert: sym pathSegments isEmpty label: 'no segments'.
	^ sym
]

{ #category : 'examples-negative' }
ZealPathSymbolExamples >> pathDoubleSlashIsNotPath [
	"`a//b` has an empty middle segment — not a well-formed path."
	<gtExample>
	| sym |
	sym := self parseSymbol: 'a//b'.
	self assert: sym isPathSymbol equals: false label: 'a//b is not a path'.
	^ sym
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathFullMix [
	"`a/:x/@some-cast/1` exercises every segment kind in one path."
	<gtExample>
	| sym segs |
	sym := self parseSymbol: 'a/:x/@some-cast/1'.
	self assert: sym value value equals: 'a/:x/@some-cast/1'
		label: 'full text round-trips through one ZealSymbolNode'.
	segs := sym pathSegments.
	self assert: segs size equals: 4 label: 'four segments'.
	self assert: ((segs collect: [ :s | s at: #kind ]) asArray)
		equals: #(#root #keyword #cast #index)
		label: 'kinds: root, keyword, cast, index'.
	self assert: ((segs collect: [ :s | s at: #text ]) asArray)
		equals: #('a' 'x' 'some-cast' '1')
		label: 'texts: a, x, some-cast, 1'.
	^ sym
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathIndexSegment [
	"`a/1` — pure-digits segment is an index."
	<gtExample>
	| sym segs |
	sym := self parseSymbol: 'a/1'.
	segs := sym pathSegments.
	self assert: (segs second at: #kind) equals: #index label: 'second is index'.
	self assert: (segs second at: #text) equals: '1' label: 'index text is 1'.
	^ sym
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathKeywordSegment [
	"`a/:x` — keyword segment retains text without the leading colon."
	<gtExample>
	| sym segs |
	sym := self parseSymbol: 'a/:x'.
	self assert: sym isPathSymbol equals: true label: 'a/:x is a path'.
	segs := sym pathSegments.
	self assert: segs size equals: 2 label: 'two segments'.
	self assert: (segs second at: #kind) equals: #keyword label: 'second is keyword'.
	self assert: (segs second at: #text) equals: 'x' label: 'colon stripped from text'.
	^ sym
]

{ #category : 'examples-negative' }
ZealPathSymbolExamples >> pathLeadingSlashIsNotPath [
	"`/a` starts with a slash — not a valid path root."
	<gtExample>
	| sym |
	sym := self parseSymbol: '/a'.
	self assert: sym isPathSymbol equals: false label: '/a is not a path'.
	^ sym
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathSinglePartIsNotPath [
	"A bare name like `a` has no slash, so it's not a path."
	<gtExample>
	| sym |
	sym := self parseSymbol: 'a'.
	self assert: sym isPathSymbol equals: false label: 'bare name is not a path'.
	self assert: sym pathSegments isEmpty label: 'no segments for non-path'.
	^ sym
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathThreeNames [
	"`a/b/c` produces root + 2 names."
	<gtExample>
	| sym segs |
	sym := self parseSymbol: 'a/b/c'.
	segs := sym pathSegments.
	self assert: segs size equals: 3 label: 'three segments'.
	self assert: ((segs collect: [ :s | s at: #kind ]) asArray)
		equals: #(#root #name #name) label: 'kinds are root, name, name'.
	self assert: ((segs collect: [ :s | s at: #text ]) asArray)
		equals: #('a' 'b' 'c') label: 'texts a b c'.
	^ sym
]

{ #category : 'examples-negative' }
ZealPathSymbolExamples >> pathTrailingSlashIsNotPath [
	"`a/` ends with a slash — empty trailing segment, not a path."
	<gtExample>
	| sym |
	sym := self parseSymbol: 'a/'.
	self assert: sym isPathSymbol equals: false label: 'a/ is not a path'.
	^ sym
]

{ #category : 'examples-positive' }
ZealPathSymbolExamples >> pathTwoNames [
	"`a/b` parses as a single symbol; pathSegments has root + name."
	<gtExample>
	| sym segs |
	sym := self parseSymbol: 'a/b'.
	self assert: sym isPathSymbol equals: true label: 'a/b is a path'.
	segs := sym pathSegments.
	self assert: segs size equals: 2 label: 'two segments'.
	self assert: (segs first at: #kind) equals: #root label: 'first kind is root'.
	self assert: (segs first at: #text) equals: 'a' label: 'first text is a'.
	self assert: (segs second at: #kind) equals: #name label: 'second kind is name'.
	self assert: (segs second at: #text) equals: 'b' label: 'second text is b'.
	^ sym
]
