Class {
	#name : 'ZealParser',
	#superclass : 'SmaCCParser',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated-accessing' }
ZealParser class >> cacheId [
	^'2026-04-26T12:12:14.935-04:00'
]

{ #category : 'generated' }
ZealParser class >> definitionComment [
"%root Program ;
%prefix Zeal ;
%suffix Node ;
%ignore_variables whitespace comment ;

<whitespace> : \s+ ;
<comment> : \; [^\r\n]* ;
<float> : \-? [0-9]+ \. [0-9]+ ([eE] [\+\-]? [0-9]+)? ;
<integer> : \-? [0-9]+ ;
<hex> : 0x [0-9a-fA-F]+ ;
<string> : \"" ([^\""\\] | \\ .)* \"" ;
<charLiteral> : \' ([^'\\] | \\ .) \' ;
<range> : [0-9]+ \.\. [0-9]+ ;
<colonChain> : [a-zA-Z_] [a-zA-Z0-9_\-]* (\: \[\] [a-zA-Z_] [a-zA-Z0-9_\-\?]* | \: [a-zA-Z_@\?] [a-zA-Z0-9_\-\?]*)+ ;
<symbol> : [a-zA-Z_!\+\-\*\/\=\<\>\&\.\?\@\#] [a-zA-Z0-9_!\+\-\*\/\=\<\>\&\.\?\@\#\-]* ;
<path> : [a-zA-Z_] [a-zA-Z0-9_\-]* (\/ ([a-zA-Z_!\+\-\*\=\<\>\&\.\?\@\#] [a-zA-Z0-9_!\+\-\*\=\<\>\&\.\?\@\#\-]* | \: [a-zA-Z_] [a-zA-Z0-9_\-]* | [0-9]+))+ ;
<keyword> : \: [a-zA-Z_] [a-zA-Z0-9_\-]* ;
<leftParen> : \( ;
<rightParen> : \) ;
<leftBracket> : \[ ;
<rightBracket> : \] ;
<leftBrace> : \{ ;
<rightBrace> : \} ;

Program : Expressions {{}} ;
Expressions : | Expressions Expression 'expression' ;
Expression : Atom | List | Vector | Map ;
List : <leftParen> 'leftParen' Expressions <rightParen> 'rightParen' {{}} ;
Vector : <leftBracket> 'leftBracket' Expressions <rightBracket> 'rightBracket' {{}} ;
Map : <leftBrace> 'leftBrace' MapPairs <rightBrace> 'rightBrace' {{}} ;
MapPairs : | MapPairs MapPair 'pair' ;
MapPair : Expression 'key' Expression 'value' {{}} ;

Atom   : <float> 'value' {{FloatLiteral}}
       | <integer> 'value' {{IntegerLiteral}}
       | <hex> 'value' {{HexLiteral}}
       | <string> 'value' {{StringLiteral}}
       | <charLiteral> 'value' {{CharLiteral}}
       | <range> 'value' {{RangeLiteral}}
       | <colonChain> 'value' {{ColonChain}}
       | <path> 'value' {{Symbol}}
       | <symbol> 'value' {{Symbol}}
       | <keyword> 'value' {{Keyword}}
       ;"
]

{ #category : 'generated' }
ZealParser class >> reduceTable [
^#(
	#(21 0 #reduceActionForExpressions1: 928769 false) 
	#(20 1 #reduceActionForProgram1: 899073 false) 
	#(28 1 #reduceActionForAtom1: 1361921 false) 
	#(28 1 #reduceActionForAtom2: 1361922 false) 
	#(28 1 #reduceActionForAtom3: 1361923 false) 
	#(28 1 #reduceActionForAtom4: 1361924 false) 
	#(28 1 #reduceActionForAtom5: 1361925 false) 
	#(28 1 #reduceActionForAtom6: 1361926 false) 
	#(28 1 #reduceActionForAtom7: 1361927 false) 
	#(28 1 #reduceActionForAtom9: 1361929 false) 
	#(28 1 #reduceActionForAtom9: 1361928 false) 
	#(28 1 #reduceActionForAtom10: 1361930 false) 
	#(26 0 #reduceActionForExpressions1: 1266689 false) 
	#(21 2 #reduceActionForExpressions2: 928770 false) 
	#(22 1 #liftFirstValue: 984066 false) 
	#(22 1 #liftFirstValue: 984067 false) 
	#(22 1 #liftFirstValue: 984068 false) 
	#(22 1 #liftFirstValue: 984065 false) 
	#(23 3 #reduceActionForList1: 1027073 false) 
	#(24 3 #reduceActionForVector1: 1104897 false) 
	#(25 3 #reduceActionForMap1: 1192961 false) 
	#(26 2 #reduceActionForExpressions2: 1266690 false) 
	#(27 2 #reduceActionForMapPair1: 1306625 false)
	).
]

{ #category : 'generated-accessing' }
ZealParser class >> scannerClass [
	^ZealScanner
]

{ #category : 'generated' }
ZealParser class >> startingStateForProgram [
	^ 1
]

{ #category : 'generated' }
ZealParser class >> symbolNames [
	^ #('<whitespace>' '<comment>' '<float>' '<integer>' '<hex>' '<string>' '<charLiteral>' '<range>' '<colonChain>' '<symbol>' '<path>' '<keyword>' '<leftParen>' '<rightParen>' '<leftBracket>' '<rightBracket>' '<leftBrace>' '<rightBrace>' 'B e g i n' 'Program' 'Expressions' 'Expression' 'List' 'Vector' 'Map' 'MapPairs' 'MapPair' 'Atom' 'E O F' 'error')
]

{ #category : 'generated' }
ZealParser class >> symbolTypes [
	^ #(#SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #ZealProgramNode #ZealProgramNode #OrderedCollection #ZealProgramNode #ZealListNode #ZealVectorNode #ZealMapNode #OrderedCollection #ZealMapPairNode #ZealProgramNode #SmaCCToken #SmaCCErrorNode)
]

{ #category : 'generated' }
ZealParser class >> transitionTable [
^#(
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 15 0 6 0 17 0 9 0 20 0 13 0 21 0 6 0 29] 
#[0 0 0 0 29] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 15 0 65 0 17 0 69 0 22 0 69 0 23 0 69 0 24 0 69 0 25 0 69 0 28 0 10 0 29] 
#[0 0 14 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 18 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 22 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 26 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 30 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 34 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 38 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 42 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 46 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 50 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 15 0 6 0 17 0 89 0 21] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 15 0 6 0 16 0 6 0 17 0 93 0 21] 
#[1 0 54 0 3 0 54 0 4 0 54 0 5 0 54 0 6 0 54 0 7 0 54 0 8 0 54 0 9 0 54 0 10 0 54 0 11 0 54 0 12 0 54 0 13 0 54 0 15 0 54 0 17 0 54 0 18 0 97 0 26] 
#[0 0 58 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 29] 
#[0 0 62 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 66 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 70 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 74 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 101 0 14 0 61 0 15 0 65 0 17 0 69 0 22 0 69 0 23 0 69 0 24 0 69 0 25 0 69 0 28] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 15 0 105 0 16 0 65 0 17 0 69 0 22 0 69 0 23 0 69 0 24 0 69 0 25 0 69 0 28] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 15 0 65 0 17 0 109 0 18 0 113 0 22 0 113 0 23 0 113 0 24 0 113 0 25 0 117 0 27 0 113 0 28] 
#[0 0 78 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 82 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[0 0 86 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 29] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 15 0 65 0 17 0 121 0 22 0 121 0 23 0 121 0 24 0 121 0 25 0 121 0 28] 
#[0 0 90 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 15 0 17 0 18] 
#[0 0 94 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 15 0 17 0 18]
	).
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom10: nodes [
	| result |
	result := ZealKeywordNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom1: nodes [
	| result |
	result := ZealFloatLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom2: nodes [
	| result |
	result := ZealIntegerLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom3: nodes [
	| result |
	result := ZealHexLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom4: nodes [
	| result |
	result := ZealStringLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom5: nodes [
	| result |
	result := ZealCharLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom6: nodes [
	| result |
	result := ZealRangeLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom7: nodes [
	| result |
	result := ZealColonChainNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom9: nodes [
	| result |
	result := ZealSymbolNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForExpressions1: nodes [
	| result |
	result := OrderedCollection new: 2.
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForExpressions2: nodes [
	| result |
	result := nodes at: 1.
	self add: (nodes at: 2) to: result.
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForList1: nodes [
	| result |
	result := ZealListNode new.
	result leftParen: (nodes at: 1).
	result addNodes: (nodes at: 2) to: result expressions.
	result rightParen: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForMap1: nodes [
	| result |
	result := ZealMapNode new.
	result leftBrace: (nodes at: 1).
	result addNodes: (nodes at: 2) to: result pairs.
	result rightBrace: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForMapPair1: nodes [
	| result |
	result := ZealMapPairNode new.
	result key: (nodes at: 1).
	result value: (nodes at: 2).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForProgram1: nodes [
	| result |
	result := ZealProgramNode new.
	result addNodes: (nodes at: 1) to: result expressions.
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForVector1: nodes [
	| result |
	result := ZealVectorNode new.
	result leftBracket: (nodes at: 1).
	result addNodes: (nodes at: 2) to: result expressions.
	result rightBracket: (nodes at: 3).
	^ result
]
