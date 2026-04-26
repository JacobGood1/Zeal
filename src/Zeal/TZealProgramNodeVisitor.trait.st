Trait {
	#name : 'TZealProgramNodeVisitor',
	#traits : 'TSmaCCParseNodeVisitor',
	#classTraits : 'TSmaCCParseNodeVisitor classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitCharLiteral: aCharLiteral [
	^ self visitProgram: aCharLiteral
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitColonChain: aColonChain [
	^ self visitProgram: aColonChain
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitFloatLiteral: aFloatLiteral [
	^ self visitProgram: aFloatLiteral
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitHexLiteral: aHexLiteral [
	^ self visitProgram: aHexLiteral
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitIntegerLiteral: anIntegerLiteral [
	^ self visitProgram: anIntegerLiteral
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitKeyword: aKeyword [
	^ self visitProgram: aKeyword
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitList: aList [
	^ self visitProgram: aList
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitMap: aMap [
	^ self visitProgram: aMap
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitMapPair: aMapPair [
	^ self visitProgram: aMapPair
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitProgram: aProgram [
	^ self visitSmaCCParseNode: aProgram
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitRangeLiteral: aRangeLiteral [
	^ self visitProgram: aRangeLiteral
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitStringLiteral: aStringLiteral [
	^ self visitProgram: aStringLiteral
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitSymbol: aSymbol [
	^ self visitProgram: aSymbol
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitVector: aVector [
	^ self visitProgram: aVector
]

{ #category : 'generated' }
TZealProgramNodeVisitor >> visitVectorLiteral: aVectorLiteral [
	^ self visitProgram: aVectorLiteral
]
