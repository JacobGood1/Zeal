Trait {
	#name : 'TVerseProgramNodeVisitor',
	#traits : 'TSmaCCParseNodeVisitor',
	#classTraits : 'TSmaCCParseNodeVisitor classTrait',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitAnnotatedDef: anAnnotatedDef [
	^ self visitProgram: anAnnotatedDef
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitArchetype: anArchetype [
	^ self visitProgram: anArchetype
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitArrayLit: anArrayLit [
	^ self visitProgram: anArrayLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitArrayType: anArrayType [
	^ self visitProgram: anArrayType
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitBinOp: aBinOp [
	^ self visitProgram: aBinOp
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitBlock: aBlock [
	^ self visitProgram: aBlock
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitBoolLit: aBoolLit [
	^ self visitProgram: aBoolLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitBreak: aBreak [
	^ self visitProgram: aBreak
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitCall: aCall [
	^ self visitProgram: aCall
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitCharLit: aCharLit [
	^ self visitProgram: aCharLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitClass: aClass [
	^ self visitProgram: aClass
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitConstDef: aConstDef [
	^ self visitProgram: aConstDef
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitEnum: anEnum [
	^ self visitProgram: anEnum
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitFailableCall: aFailableCall [
	^ self visitProgram: aFailableCall
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitFieldInit: aFieldInit [
	^ self visitProgram: aFieldInit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitFloatLit: aFloatLit [
	^ self visitProgram: aFloatLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitFor: aFor [
	^ self visitProgram: aFor
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitForClause: aForClause [
	^ self visitProgram: aForClause
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitFuncDef: aFuncDef [
	^ self visitProgram: aFuncDef
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitFuncParam: aFuncParam [
	^ self visitProgram: aFuncParam
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitGenericType: aGenericType [
	^ self visitProgram: aGenericType
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitHexLit: aHexLit [
	^ self visitProgram: aHexLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitIdent: anIdent [
	^ self visitProgram: anIdent
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitIf: anIf [
	^ self visitProgram: anIf
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitIntLit: anIntLit [
	^ self visitProgram: anIntLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitInterface: anInterface [
	^ self visitProgram: anInterface
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitLoop: aLoop [
	^ self visitProgram: aLoop
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitMapEntry: aMapEntry [
	^ self visitProgram: aMapEntry
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitMapLit: aMapLit [
	^ self visitProgram: aMapLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitMapType: aMapType [
	^ self visitProgram: aMapType
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitMemberAccess: aMemberAccess [
	^ self visitProgram: aMemberAccess
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitModule: aModule [
	^ self visitProgram: aModule
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitNamed: aNamed [
	^ self visitProgram: aNamed
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitOptional: anOptional [
	^ self visitProgram: anOptional
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitParam: aParam [
	^ self visitProgram: aParam
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitParen: aParen [
	^ self visitProgram: aParen
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitProgram: aProgram [
	^ self visitSmaCCParseNode: aProgram
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitQuery: aQuery [
	^ self visitProgram: aQuery
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitReturn: aReturn [
	^ self visitProgram: aReturn
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitSet: aSet [
	^ self visitProgram: aSet
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitStringLit: aStringLit [
	^ self visitProgram: aStringLit
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitStruct: aStruct [
	^ self visitProgram: aStruct
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitTypeType: aTypeType [
	^ self visitProgram: aTypeType
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitUnaryOp: anUnaryOp [
	^ self visitProgram: anUnaryOp
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitUsingDef: anUsingDef [
	^ self visitProgram: anUsingDef
]

{ #category : 'generated' }
TVerseProgramNodeVisitor >> visitVarDef: aVarDef [
	^ self visitProgram: aVarDef
]
