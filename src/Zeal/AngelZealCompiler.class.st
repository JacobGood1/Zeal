Class {
	#name : 'AngelZealCompiler',
	#superclass : 'ZealCompiler',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealCompiler class >> compile: aString [
	"Parse AngelZeal source -> ZealNode object(s), preserving the original text as
	 rawSource so the editor can round-trip comments / exact formatting."
	| ast result |
	ast := ZealParser parse: aString.
	result := self buildFromAST: ast.
	(result isKindOf: Collection)
		ifTrue: [ result do: [ :n | n rawSource: aString ] ]
		ifFalse: [ result rawSource: aString ].
	^ result
]

{ #category : 'api' }
AngelZealCompiler class >> compileToAngelScript: aString [
	"Full pipeline: AngelZeal source string -> AngelScript source string."
	^ AngelZealCodeGenerator new generate: (ZealParser parse: aString)
]
