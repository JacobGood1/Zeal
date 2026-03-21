Class {
	#name : 'ZealParser',
	#superclass : 'SmaCCParser',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated-accessing' }
ZealParser class >> cacheId [
	^'2026-03-20T22:30:32.12-04:00'
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
<range> : [0-9]+ \.\. [0-9]+ ;
<colonChain> : [a-zA-Z_] [a-zA-Z0-9_\-]* (\: [a-zA-Z_@\?] [a-zA-Z0-9_\-\?]*)+ ;
<symbol> : [a-zA-Z_!\+\-\*\/\=\<\>\&\.\?\@\#] [a-zA-Z0-9_!\+\-\*\/\=\<\>\&\.\?\-]* ;
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
Atom 
  : <float> 'value' {{FloatLiteral}} 
  | <integer> 'value' {{IntegerLiteral}} 
  | <hex> 'value' {{HexLiteral}}
  | <string> 'value' {{StringLiteral}} 
  | <range> 'value' {{RangeLiteral}}
  | <colonChain> 'value' {{ColonChain}} 
  | <symbol> 'value' {{Symbol}} 
  | <keyword> 'value' {{Keyword}} 
  ;"
]

{ #category : 'generated' }
ZealParser class >> reduceTable [
^#(
	#(19 0 #reduceActionForExpressions1: 685057 false) 
	#(18 1 #reduceActionForProgram1: 655361 false) 
	#(26 1 #reduceActionForAtom1: 1117185 false) 
	#(26 1 #reduceActionForAtom2: 1117186 false) 
	#(26 1 #reduceActionForAtom3: 1117187 false) 
	#(26 1 #reduceActionForAtom4: 1117188 false) 
	#(26 1 #reduceActionForAtom5: 1117189 false) 
	#(26 1 #reduceActionForAtom6: 1117190 false) 
	#(26 1 #reduceActionForAtom7: 1117191 false) 
	#(26 1 #reduceActionForAtom8: 1117192 false) 
	#(24 0 #reduceActionForExpressions1: 1022977 false) 
	#(19 2 #reduceActionForExpressions2: 685058 false) 
	#(20 1 #liftFirstValue: 740354 false) 
	#(20 1 #liftFirstValue: 740355 false) 
	#(20 1 #liftFirstValue: 740356 false) 
	#(20 1 #liftFirstValue: 740353 false) 
	#(21 3 #reduceActionForList1: 783361 false) 
	#(22 3 #reduceActionForVector1: 861185 false) 
	#(23 3 #reduceActionForMap1: 949249 false) 
	#(24 2 #reduceActionForExpressions2: 1022978 false) 
	#(25 2 #reduceActionForMapPair1: 1062913 false)
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
	^ #('<whitespace>' '<comment>' '<float>' '<integer>' '<hex>' '<string>' '<range>' '<colonChain>' '<symbol>' '<keyword>' '<leftParen>' '<rightParen>' '<leftBracket>' '<rightBracket>' '<leftBrace>' '<rightBrace>' 'B e g i n' 'Program' 'Expressions' 'Expression' 'List' 'Vector' 'Map' 'MapPairs' 'MapPair' 'Atom' 'E O F' 'error')
]

{ #category : 'generated' }
ZealParser class >> symbolTypes [
	^ #(#SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #ZealProgramNode #ZealProgramNode #OrderedCollection #ZealProgramNode #ZealListNode #ZealVectorNode #ZealMapNode #OrderedCollection #ZealMapPairNode #ZealProgramNode #SmaCCToken #SmaCCErrorNode)
]

{ #category : 'generated' }
ZealParser class >> transitionTable [
^#(
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 13 0 6 0 15 0 9 0 18 0 13 0 19 0 6 0 27] 
#[0 0 0 0 27] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 13 0 57 0 15 0 61 0 20 0 61 0 21 0 61 0 22 0 61 0 23 0 61 0 26 0 10 0 27] 
#[0 0 14 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 18 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 22 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 26 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 30 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 34 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 38 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 42 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 15 0 81 0 19] 
#[1 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 10 0 6 0 11 0 6 0 13 0 6 0 14 0 6 0 15 0 85 0 19] 
#[1 0 46 0 3 0 46 0 4 0 46 0 5 0 46 0 6 0 46 0 7 0 46 0 8 0 46 0 9 0 46 0 10 0 46 0 11 0 46 0 13 0 46 0 15 0 46 0 16 0 89 0 24] 
#[0 0 50 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 27] 
#[0 0 54 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 58 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 62 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 66 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 93 0 12 0 53 0 13 0 57 0 15 0 61 0 20 0 61 0 21 0 61 0 22 0 61 0 23 0 61 0 26] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 13 0 97 0 14 0 57 0 15 0 61 0 20 0 61 0 21 0 61 0 22 0 61 0 23 0 61 0 26] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 13 0 57 0 15 0 101 0 16 0 105 0 20 0 105 0 21 0 105 0 22 0 105 0 23 0 109 0 25 0 105 0 26] 
#[0 0 70 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 74 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[0 0 78 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 27] 
#[1 0 17 0 3 0 21 0 4 0 25 0 5 0 29 0 6 0 33 0 7 0 37 0 8 0 41 0 9 0 45 0 10 0 49 0 11 0 53 0 13 0 57 0 15 0 113 0 20 0 113 0 21 0 113 0 22 0 113 0 23 0 113 0 26] 
#[0 0 82 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 13 0 15 0 16] 
#[0 0 86 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 13 0 15 0 16]
	).
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
	result := ZealRangeLiteralNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom6: nodes [
	| result |
	result := ZealColonChainNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom7: nodes [
	| result |
	result := ZealSymbolNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
ZealParser >> reduceActionForAtom8: nodes [
	| result |
	result := ZealKeywordNode new.
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
