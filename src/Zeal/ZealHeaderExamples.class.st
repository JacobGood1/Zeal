Class {
	#name : 'ZealHeaderExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'examples-dialects' }
ZealHeaderExamples >> angelInheritsSlashSlashStyle [
	"AngelZealCompiler removed its overrides — should inherit `// `-style hooks."
	<gtExample>
	self assert: AngelZealCompiler zealHeaderMarker equals: '// @zeal' label: 'angel marker'.
	self assert: AngelZealCompiler zealHeaderEnd equals: '// @end' label: 'angel end'.
	self assert: AngelZealCompiler zealCommentPrefix equals: '// ' label: 'angel comment prefix'.
	self assert: AngelZealCompiler zealMetaPrefix equals: '// @meta ' label: 'angel meta prefix'.
	^ #ok
]

{ #category : 'helpers' }
ZealHeaderExamples >> assert: actual equals: expected label: label [
	actual = expected ifTrue: [ ^ self ].
	^ self error: label , ' — expected ' , expected printString
		, ' but got ' , actual printString
]

{ #category : 'helpers' }
ZealHeaderExamples >> assert: aBoolean label: label [
	aBoolean ifTrue: [ ^ self ].
	^ self error: label , ' — expected true but got false'
]

{ #category : 'examples-emit' }
ZealHeaderExamples >> emitHeaderOrdersMetaCanonically [
	"orderedMetaKeys: drives a stable order — kind, name, returns, params, parent,
	 zealLines, targetLines, file. Independent of dictionary insertion order."
	<gtExample>
	| header kindIdx nameIdx returnsIdx fileIdx |
	header := ZealCompiler
		zealHeaderFor: 'src'
		metadata: (Dictionary new
			at: #file put: '/x.as';
			at: #returns put: 'int';
			at: #name put: 'foo';
			at: #kind put: 'defn';
			yourself).
	kindIdx := header indexOfSubCollection: '@meta kind'.
	nameIdx := header indexOfSubCollection: '@meta name'.
	returnsIdx := header indexOfSubCollection: '@meta returns'.
	fileIdx := header indexOfSubCollection: '@meta file'.
	self assert: (kindIdx < nameIdx and: [ nameIdx < returnsIdx and: [ returnsIdx < fileIdx ] ])
		label: 'meta lines emitted in canonical order regardless of dict insertion'.
	^ header
]

{ #category : 'examples-emit' }
ZealHeaderExamples >> emitHeaderUsesMarkerCommentAndMeta [
	"zealHeaderFor:metadata: emits the marker on its own line, then `<metaPrefix>key: value`
	 lines for each metadata entry, then `<commentPrefix><source-line>` lines, then end."
	<gtExample>
	| header |
	header := ZealCompiler
		zealHeaderFor: '(def speed:float 600.0)'
		metadata: (Dictionary new
			at: #kind put: 'def';
			at: #name put: 'speed';
			at: #returns put: 'float';
			yourself).
	self assert: (header beginsWith: '// @zeal') label: 'starts with marker'.
	self assert: (header includesSubstring: '// @meta kind: def') label: 'has kind meta line'.
	self assert: (header includesSubstring: '// @meta name: speed') label: 'has name meta line'.
	self assert: (header includesSubstring: '// @meta returns: float') label: 'has returns meta line'.
	self assert: (header includesSubstring: '// (def speed:float 600.0)') label: 'has zeal source line'.
	self assert: (header trimRight endsWith: '// @end') label: 'ends with end marker'.
	^ header
]

{ #category : 'examples-extract-metadata' }
ZealHeaderExamples >> extractDefclassMetadata [
	"defclass with a parent type — both #returns and #parent should be set
	 to the parent type symbol."
	<gtExample>
	| meta |
	meta := ZealCompiler extractMetadataFor: '(defclass boss:AActor (var hp:int 100))'.
	self assert: (meta at: #kind) equals: 'defclass' label: 'kind is defclass'.
	self assert: (meta at: #name) equals: 'boss' label: 'name is boss'.
	self assert: (meta at: #returns) equals: 'AActor' label: 'returns mirrors parent'.
	self assert: (meta at: #parent) equals: 'AActor' label: 'parent is AActor'.
	^ meta
]

{ #category : 'examples-extract-metadata' }
ZealHeaderExamples >> extractDefnMetadata [
	"extractMetadataFor: on a (defn name:type [params] body) form should
	 yield kind, name, returns, and params keys."
	<gtExample>
	| meta |
	meta := ZealCompiler extractMetadataFor: '(defn add:int [x:int y:int] (+ x y))'.
	self assert: (meta at: #kind) equals: 'defn' label: 'kind is defn'.
	self assert: (meta at: #name) equals: 'add' label: 'name is add'.
	self assert: (meta at: #returns) equals: 'int' label: 'returns is int'.
	self assert: (meta at: #params) equals: 'x:int, y:int' label: 'params joined comma-space'.
	self assert: meta size equals: 4 label: 'exactly 4 keys for a plain defn'.
	^ meta
]

{ #category : 'examples-extract-metadata' }
ZealHeaderExamples >> extractVarMetadata [
	"(var x 1) — only kind and name; no params, returns, or parent."
	<gtExample>
	| meta |
	meta := ZealCompiler extractMetadataFor: '(var x 1)'.
	self assert: (meta at: #kind) equals: 'var' label: 'kind is var'.
	self assert: (meta at: #name) equals: 'x' label: 'name is x'.
	self assert: (meta includesKey: #params) equals: false label: 'no params for var'.
	self assert: (meta includesKey: #parent) equals: false label: 'no parent for var'.
	^ meta
]

{ #category : 'examples-dialects' }
ZealHeaderExamples >> godotOverridesHashStyle [
	"GodotZealCompiler must override all four hooks to `#`-style for GDScript."
	<gtExample>
	self assert: GodotZealCompiler zealHeaderMarker equals: '# @zeal' label: 'godot marker'.
	self assert: GodotZealCompiler zealHeaderEnd equals: '# @end' label: 'godot end'.
	self assert: GodotZealCompiler zealCommentPrefix equals: '# ' label: 'godot comment prefix'.
	self assert: GodotZealCompiler zealMetaPrefix equals: '# @meta ' label: 'godot meta prefix'.
	^ #ok
]

{ #category : 'examples-dialects' }
ZealHeaderExamples >> godotRoundtripUsesHashPrefix [
	"Godot emits and parses with `#`. The same metadata pipeline produces a
	 valid GDScript-comment header."
	<gtExample>
	| zealSrc meta header file sect |
	zealSrc := '(defn jump:void [] (set velocity-y -500.0))'.
	meta := GodotZealCompiler extractMetadataFor: zealSrc.
	header := GodotZealCompiler zealHeaderFor: zealSrc metadata: meta.
	self assert: (header beginsWith: '# @zeal') label: 'starts with # @zeal'.
	self assert: (header includesSubstring: '# @meta kind: defn') label: 'meta line uses #'.
	self assert: (header includesSubstring: '# (defn jump') label: 'source line uses #'.
	file := header , 'func jump() -> void:', String lf, '    velocity_y = -500.0', String lf.
	sect := (GodotZealCompiler parseSections: file) first.
	self assert: (sect at: #zealSource) equals: zealSrc label: 'godot zeal round-trip'.
	self assert: ((sect at: #metadata) at: #name) equals: 'jump' label: 'godot meta round-trip'.
	^ sect
]

{ #category : 'examples-roundtrip' }
ZealHeaderExamples >> parseSectionsRecordsLineRanges [
	"After parseSections:, each section reports lineStart/lineEnd, zealLineStart/zealLineEnd,
	 targetLineStart/targetLineEnd. Verify they're 1-based and consistent."
	<gtExample>
	| zealSrc header file sections sect |
	zealSrc := '(def x 1)'.
	header := ZealCompiler zealHeaderFor: zealSrc metadata: Dictionary new.
	file := header , 'int X = 1;' , String lf.
	sections := ZealCompiler parseSections: file.
	sect := sections first.
	self assert: (sect at: #lineStart) equals: 1 label: 'first section starts at line 1'.
	self assert: (sect at: #zealLineStart) >= 1 label: 'zeal range starts within file'.
	self assert: (sect at: #targetLineStart) > (sect at: #zealLineEnd)
		label: 'target lines come after zeal lines'.
	^ sect
]

{ #category : 'examples-roundtrip' }
ZealHeaderExamples >> roundtripEmitThenParse [
	"Header → file → parseSections: round-trips the metadata + source intact."
	<gtExample>
	| zealSrc meta header file sections sect |
	zealSrc := '(defn add:int [x:int y:int] (+ x y))'.
	meta := ZealCompiler extractMetadataFor: zealSrc.
	header := ZealCompiler zealHeaderFor: zealSrc metadata: meta.
	file := header , 'int Add(int X, int Y) { return X + Y; }', String lf.
	sections := ZealCompiler parseSections: file.
	self assert: sections size equals: 1 label: 'exactly one section'.
	sect := sections first.
	self assert: (sect at: #zealSource) equals: zealSrc label: 'zeal source round-trips'.
	self assert: ((sect at: #metadata) at: #name) equals: 'add' label: 'name in metadata'.
	self assert: ((sect at: #metadata) at: #kind) equals: 'defn' label: 'kind in metadata'.
	self assert: ((sect at: #metadata) at: #returns) equals: 'int' label: 'returns in metadata'.
	self assert: ((sect at: #targetCode) includesSubstring: 'int Add') label: 'target code captured'.
	^ sect
]
