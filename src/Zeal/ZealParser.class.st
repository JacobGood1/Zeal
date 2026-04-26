Class {
	#name : 'ZealParser',
	#superclass : 'SmaCCParser',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated-accessing' }
ZealParser class >> cacheId [
	^'2026-04-26T13:04:46.177-04:00'
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
<arrowVector> : \-\> \[ ;
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
Expression : Atom | List | Vector | Map | VectorLiteral ;
List : <leftParen> 'leftParen' Expressions <rightParen> 'rightParen' {{}} ;
Vector : <leftBracket> 'leftBracket' Expressions <rightBracket> 'rightBracket' {{}} ;
VectorLiteral : <arrowVector> 'leftMarker' Expressions <rightBracket> 'rightBracket' {{}} ;
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
	#(22 0 #reduceActionForExpressions1: 955393 false) 
	#(21 1 #reduceActionForProgram1: 925697 false) 
	#(30 1 #reduceActionForAtom1: 1499137 false) 
	#(30 1 #reduceActionForAtom2: 1499138 false) 
	#(30 1 #reduceActionForAtom3: 1499139 false) 
	#(30 1 #reduceActionForAtom4: 1499140 false) 
	#(30 1 #reduceActionForAtom5: 1499141 false) 
	#(30 1 #reduceActionForAtom6: 1499142 false) 
	#(30 1 #reduceActionForAtom7: 1499143 false) 
	#(30 1 #reduceActionForAtom9: 1499145 false) 
	#(30 1 #reduceActionForAtom9: 1499144 false) 
	#(30 1 #reduceActionForAtom10: 1499146 false) 
	#(28 0 #reduceActionForExpressions1: 1403905 false) 
	#(22 2 #reduceActionForExpressions2: 955394 false) 
	#(23 1 #liftFirstValue: 1010690 false) 
	#(23 1 #liftFirstValue: 1010691 false) 
	#(23 1 #liftFirstValue: 1010693 false) 
	#(23 1 #liftFirstValue: 1010692 false) 
	#(23 1 #liftFirstValue: 1010689 false) 
	#(26 3 #reduceActionForVectorLiteral1: 1235969 false) 
	#(24 3 #reduceActionForList1: 1070081 false) 
	#(25 3 #reduceActionForVector1: 1147905 false) 
	#(27 3 #reduceActionForMap1: 1330177 false) 
	#(28 2 #reduceActionForExpressions2: 1403906 false) 
	#(29 2 #reduceActionForMapPair1: 1443841 false)
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
	^ #('<whitespace>' '<comment>' '<float>' '<integer>' '<hex>' '<string>' '<charLiteral>' '<range>' '<colonChain>' '<arrowVector>' '<symbol>' '<path>' '<keyword>' '<leftParen>' '<rightParen>' '<leftBracket>' '<rightBracket>' '<leftBrace>' '<rightBrace>' 'B e g i n' 'Program' 'Expressions' 'Expression' 'List' 'Vector' 'VectorLiteral' 'Map' 'MapPairs' 'MapPair' 'Atom' 'E O F' 'error')
]

{ #category : 'generated' }
ZealParser class >> symbolTypes [
	^ #(#SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #ZealProgramNode #ZealProgramNode #OrderedCollection #ZealProgramNode #ZealListNode #ZealVectorNode #ZealVectorLiteralNode #ZealMapNode #OrderedCollection #ZealMapPairNode #ZealProgramNode #SmaCCToken #SmaCCErrorNode)
]

{ #category : 'generated' }
ZealParser class >> transitionTable [
^#(
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 16 0 6 0 18 0 9 0 21 0 13 0 22 0 6 0 31] 
#[0 0 0 0 31] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 16 0 69 0 18 0 73 0 23 0 73 0 24 0 73 0 25 0 73 0 26 0 73 0 27 0 73 0 30 0 10 0 31] 
#[0 0 14 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 18 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 22 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 26 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 30 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 34 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 38 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 16 0 6 0 17 0 6 0 18 0 97 0 22] 
#[0 0 42 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 46 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 50 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 15 0 6 0 16 0 6 0 18 0 101 0 22] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 16 0 6 0 17 0 6 0 18 0 105 0 22] 
#[1 0 54 0 3 0 54 0 4 0 54 0 5 0 54 0 6 0 54 0 7 0 54 0 8 0 54 0 9 0 54 0 10 0 54 0 11 0 54 0 12 0 54 0 13 0 54 0 14 0 54 0 16 0 54 0 18 0 54 0 19 0 109 0 28] 
#[0 0 58 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 31] 
#[0 0 62 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 66 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 70 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 74 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 78 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 16 0 113 0 17 0 69 0 18 0 73 0 23 0 73 0 24 0 73 0 25 0 73 0 26 0 73 0 27 0 73 0 30] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 117 0 15 0 65 0 16 0 69 0 18 0 73 0 23 0 73 0 24 0 73 0 25 0 73 0 26 0 73 0 27 0 73 0 30] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 16 0 121 0 17 0 69 0 18 0 73 0 23 0 73 0 24 0 73 0 25 0 73 0 26 0 73 0 27 0 73 0 30] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 16 0 69 0 18 0 125 0 19 0 129 0 23 0 129 0 24 0 129 0 25 0 129 0 26 0 129 0 27 0 133 0 29 0 129 0 30] 
#[0 0 82 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 86 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 90 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[0 0 94 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 31] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 16 0 69 0 18 0 137 0 23 0 137 0 24 0 137 0 25 0 137 0 26 0 137 0 27 0 137 0 30] 
#[0 0 98 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 16 0 18 0 19] 
#[0 0 102 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 16 0 18 0 19]
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

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForVectorLiteral1: nodes [
	| result |
	result := ZealVectorLiteralNode new.
	result leftMarker: (nodes at: 1).
	result addNodes: (nodes at: 2) to: result expressions.
	result rightBracket: (nodes at: 3).
	^ result
]
