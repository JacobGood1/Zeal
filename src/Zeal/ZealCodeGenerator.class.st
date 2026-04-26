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
