Class {
	#name : 'ZealCodeGenerator',
	#superclass : 'Object',
	#instVars : [
		'stream',
		'indentLevel'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'protocol' }
ZealCodeGenerator class >> transducerFormSelectors [
	"The Zeal transducer protocol — name -> selector mapping. Every concrete dialect
	 (GDZeal, VZeal, ...) provides emit methods for these. The names are the official
	 Zeal transducer surface; only the emission strategy varies per target language."
	^ Dictionary new
		"Transducers (1-arg returns xform Callable, 2-arg eager)"
		at: 'map' put: #generateMap:;
		at: 'filter' put: #generateFilter:;
		at: 'take' put: #generateTake:;
		at: 'drop' put: #generateDrop:;
		at: 'drop-last' put: #generateDropLast:;
		at: 'take-while' put: #generateTakeWhile:;
		at: 'drop-while' put: #generateDropWhile:;
		at: 'distinct' put: #generateDistinct:;
		at: 'dedupe' put: #generateDedupe:;
		at: 'keep' put: #generateKeep:;
		at: 'flatten' put: #generateFlatten:;
		at: 'indexed' put: #generateIndexed:;
		at: 'chunk' put: #generateChunk:;
		at: 'chunk-by' put: #generateChunkBy:;
		at: 'mapcat' put: #generateMapcat:;
		at: 'mapcat-indexed' put: #generateMapcatIndexed:;
		at: 'keep-indexed' put: #generateKeepIndexed:;
		at: 'interpose' put: #generateInterpose:;
		"Eager-only collection ops"
		at: 'interleave' put: #generateInterleave:;
		"Combinators"
		at: 'juxt' put: #generateJuxt:;
		"Reducers"
		at: 'sum' put: #generateSum:;
		at: 'product' put: #generateProduct:;
		at: 'tally' put: #generateTally:;
		at: 'avg' put: #generateAvg:;
		at: 'count' put: #generateCount:;
		at: 'max' put: #generateMax:;
		at: 'min' put: #generateMin:;
		at: 'any?' put: #generateAnyP:;
		at: 'every?' put: #generateEveryP:;
		at: 'into-array' put: #generateIntoArray:;
		at: 'into-map' put: #generateIntoMap:;
		at: 'into-string' put: #generateIntoString:;
		at: 'reduce' put: #generateReduce:;
		at: 'transduce' put: #generateTransduce:;
		"Sources"
		at: 'range' put: #generateRange:;
		at: 'iterate' put: #generateIterate:;
		at: 'repeat' put: #generateRepeat:;
		at: 'cycle' put: #generateCycle:;
		"Core"
		at: 'comp' put: #generateComp:;
		at: 'into' put: #generateInto:;
		yourself
]

{ #category : 'special-forms' }
ZealCodeGenerator >> baseSpecialForms [
	"Universal special forms shared across every Zeal dialect. Subclasses
	 build their full specialForms dict by adding their dialect-specific
	 entries on top of (or copying) what this returns.
	 `source-raw` is the escape hatch for inlining target-language code."
	^ Dictionary new
		at: 'source-raw' put: #generateSourceRaw:;
		yourself
]

{ #category : 'special-forms' }
ZealCodeGenerator >> baseStatementForms [
	"Universal forms that appear at statement position rather than expression
	 position. Subclasses concatenate this with their dialect-specific list."
	^ #('source-raw')
]

{ #category : 'emitting' }
ZealCodeGenerator >> dedent [
	indentLevel := indentLevel - 1
]

{ #category : 'emitting' }
ZealCodeGenerator >> emit: aString [
	stream nextPutAll: aString
]

{ #category : 'emitting' }
ZealCodeGenerator >> emitIndent [
	indentLevel timesRepeat: [ stream nextPutAll: '    ' ]
]

{ #category : 'generating' }
ZealCodeGenerator >> generate: aZealProgramNode [
	aZealProgramNode expressions do: [:expr |
		self visitExpression: expr ] separatedBy: [ self nl. self nl ].
	^ self output
]

{ #category : 'special-forms' }
ZealCodeGenerator >> generateSourceRaw: aListNode [
	"source-raw special form: emits the inner string literal verbatim into
	 the target output. Shared across every Zeal dialect — it's the universal
	 escape hatch for inlining target-language code that has no natural Zeal
	 surface syntax."
	| arg s |
	aListNode expressions size < 2 ifTrue: [ ^ self ].
	arg := aListNode expressions second.
	s := arg value value.
	(s size >= 2 and: [ s first = $" and: [ s last = $" ] ]) ifTrue: [
		s := s copyFrom: 2 to: s size - 1 ].
	s := (s copyReplaceAll: '\"' with: (String with: $")) copyReplaceAll: '\\' with: '\'.
	self emit: s
]

{ #category : 'emitting' }
ZealCodeGenerator >> indent [
	indentLevel := indentLevel + 1
]

{ #category : 'initialization' }
ZealCodeGenerator >> initialize [
	super initialize.
	stream := WriteStream on: String new.
	indentLevel := 0
]

{ #category : 'accessing' }
ZealCodeGenerator >> output [
	^ stream contents
]

{ #category : 'special-forms' }
ZealCodeGenerator >> specialForms [
	"Default: just the base universal forms. Dialect subclasses override to
	 add their own keywords (typically copying baseSpecialForms first)."
	^ self baseSpecialForms
]

{ #category : 'api' }
ZealCodeGenerator >> typeInferencer [
	"Each dialect's codegen returns its dialect's ZealTypeInferencer here.
	 Used by var/def/let/etc. to infer a type when none is annotated.
	 Base returns the primitive-only inferencer; subclasses override."
	^ ZealTypeInferencer default
]

{ #category : 'visiting' }
ZealCodeGenerator >> visitExpression: aNode [
	(aNode isKindOf: ZealListNode) ifTrue: [ ^ self visitList: aNode ].
	(aNode isKindOf: ZealVectorNode) ifTrue: [ ^ self visitVector: aNode ].
	(aNode isKindOf: ZealMapNode) ifTrue: [ ^ self visitMap: aNode ].
	^ self visitAtom: aNode
]
