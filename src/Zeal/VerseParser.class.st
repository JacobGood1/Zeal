Class {
	#name : 'VerseParser',
	#superclass : 'SmaCCGLRParser',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseParser class >> ambiguousTransitions [
^#(
#[ 0 50 0 233] 
#[ 0 46 0 50] 
#[ 0 90 1 1] 
#[ 0 94 1 5] 
#[ 0 98 1 9] 
#[ 0 98 1 13] 
#[ 0 98 1 17] 
#[ 0 98 1 21] 
#[ 0 98 1 25] 
#[ 0 98 1 29] 
#[ 0 106 1 33] 
#[ 0 106 1 37] 
#[ 0 106 1 41] 
#[ 0 110 1 45] 
#[ 0 110 1 49] 
#[ 0 118 1 53] 
#[ 0 118 1 57] 
#[ 0 118 1 61] 
#[ 0 118 1 65] 
#[ 0 118 1 69] 
#[ 0 190 2 105] 
#[ 0 210 1 5] 
#[ 0 214 1 9] 
#[ 0 214 1 13] 
#[ 0 214 1 17] 
#[ 0 214 1 21] 
#[ 0 214 1 25] 
#[ 0 214 1 29] 
#[ 0 242 1 37] 
#[ 0 242 1 41] 
#[ 0 246 1 45] 
#[ 0 246 1 49] 
#[ 0 250 1 45] 
#[ 0 250 1 49]
	).
]

{ #category : 'generated-accessing' }
VerseParser class >> cacheId [
	^'2026-03-21T14:39:44.707-04:00'
]

{ #category : 'generated' }
VerseParser class >> definitionComment [
"%root Program ;
%prefix Verse ;
%suffix Node ;
%glr ;
%ignore_variables whitespace lineComment blockComment ;
<whitespace> : \s+ ;
<lineComment> : \/\/ [^\r\n]* ;
<blockComment> : \# [^\r\n]* ;
<float> : \-? [0-9]+ \. [0-9]+ ([eE] [\+\-]? [0-9]+)? ;
<integer> : \-? [0-9]+ ;
<hex> : 0x [0-9a-fA-F]+ ;
<string> : \"" ([^\""\\] | \\ .)* \"" ;
<charLit> : \' [^'] \' ;
<kwVar> : var ; <kwSet> : set ; <kwIf> : if ; <kwElse> : else ; <kwFor> : for ;
<kwLoop> : loop ; <kwBlock> : block ; <kwReturn> : return ; <kwBreak> : break ;
<kwClass> : class ; <kwStruct> : struct ; <kwEnum> : enum ; <kwInterface> : interface ;
<kwModule> : module ; <kwUsing> : using ; <kwNot> : not ; <kwAnd> : and ; <kwOr> : or ;
<kwTrue> : true ; <kwFalse> : false ; <kwArray> : array ; <kwMap> : map ;
<kwWhere> : where ; <kwType> : type ; <kwSubtype> : subtype ;
<at> : \@ ;
<identifier> : [a-zA-Z_] [a-zA-Z0-9_]* ;
<colonEquals> : \:\= ; <fatArrow> : \=\> ; <dotDot> : \.\. ;
<lessEqual> : \<\= ; <greaterEqual> : \>\= ; <notEqual> : \<\> ;
<plusEquals> : \+\= ; <minusEquals> : \-\= ;
<leftParen> : \( ; <rightParen> : \) ; <leftBracket> : \[ ; <rightBracket> : \] ;
<leftBrace> : \{ ; <rightBrace> : \} ; <leftAngle> : \< ; <rightAngle> : \> ;
<colon> : \: ; <comma> : \, ; <dot> : \. ; <equals> : \= ;
<plus> : \+ ; <minus> : \- ; <star> : \* ; <slash> : \/ ; <question> : \? ;
Program : Statements {{}} ;
Statements : | Statements Statement 'statement' ;
Statement : Definition | Expression ;
Definition : VarDef | ConstDef | FuncDef | TypeDef | UsingDef | AnnotatedDef ;
UsingDef : <kwUsing> <leftBrace> ModulePath 'path' <rightBrace> {{}} ;
ModulePath : <slash> <identifier> 'segment' | ModulePath <dot> <identifier> 'segment' | ModulePath <slash> <identifier> 'segment' ;
AnnotatedDef : <at> <identifier> 'annotation' Definition 'definition' {{}} ;
ConstDef : <identifier> 'name' <colon> Type 'type' <equals> Expression 'value' {{}} | <identifier> 'name' <colonEquals> Expression 'value' {{}} | <identifier> 'name' <colon> Type 'type' {{}} ;
VarDef : <kwVar> <identifier> 'name' <colon> Type 'type' <equals> Expression 'value' {{}} | <kwVar> <identifier> 'name' <colonEquals> Expression 'value' {{}} | <kwVar> <identifier> 'name' <colon> Type 'type' {{}} ;
FuncDef : <identifier> 'name' Specifiers <leftParen> ParamList <rightParen> Specifiers ReturnType <equals> Expression 'body' {{}} | <identifier> 'name' Specifiers <leftParen> ParamList WhereClause <rightParen> Specifiers ReturnType <equals> Expression 'body' {{}} ;
WhereClause : <kwWhere> WhereConstraints ;
WhereConstraints : WhereConstraint | WhereConstraints <comma> WhereConstraint ;
WhereConstraint : <identifier> <colon> <kwType> | <identifier> <colon> <kwSubtype> <leftParen> <identifier> <rightParen> ;
ParamList : | Param 'param' | ParamList <comma> Param 'param' ;
Param : <identifier> 'name' <colon> Type 'type' {{}} | <question> <identifier> 'name' <colon> Type 'type' {{}} | <colon> <identifier> 'name' {{}} | <identifier> 'name' <leftParen> ParamList <rightParen> Specifiers <colon> Type 'type' {{FuncParam}} ;
Specifiers : | Specifiers <leftAngle> <identifier> 'spec' <rightAngle> ;
ReturnType : | <colon> Type 'type' ;
TypeDef : <identifier> 'name' Specifiers <colonEquals> <kwClass> ParentClause <leftBrace> Statements <rightBrace> {{Class}} | <identifier> 'name' Specifiers <colonEquals> <kwStruct> ParentClause <leftBrace> Statements <rightBrace> {{Struct}} | <identifier> 'name' Specifiers <colonEquals> <kwEnum> <leftBrace> EnumValues <rightBrace> {{Enum}} | <identifier> 'name' Specifiers <colonEquals> <kwInterface> ParentClause <leftBrace> Statements <rightBrace> {{Interface}} | <identifier> 'name' Specifiers <colonEquals> <kwModule> <leftBrace> Statements <rightBrace> {{Module}} ;
ParentClause : | <leftParen> ParentList <rightParen> ;
ParentList : <identifier> 'parent' | ParentList <comma> <identifier> 'parent' ;
EnumValues : | EnumValues <identifier> 'value' ;
Type : <identifier> 'name' {{Named}} | <question> Type 'inner' {{Optional}} | <leftBracket> <rightBracket> Type 'inner' {{ArrayType}} | <leftBracket> Type 'key' <rightBracket> Type 'value' {{MapType}} | <identifier> 'name' <leftParen> TypeArgs <rightParen> {{GenericType}} | <kwType> {{TypeType}} ;
TypeArgs : Type 'arg' | TypeArgs <comma> Type 'arg' ;
Expression : OrExpr ;
OrExpr : AndExpr | OrExpr 'left' <kwOr> 'op' AndExpr 'right' {{BinOp}} ;
AndExpr : CompExpr | AndExpr 'left' <kwAnd> 'op' CompExpr 'right' {{BinOp}} ;
CompExpr : RangeExpr | CompExpr 'left' <equals> 'op' RangeExpr 'right' {{BinOp}} | CompExpr 'left' <notEqual> 'op' RangeExpr 'right' {{BinOp}} | CompExpr 'left' <leftAngle> 'op' RangeExpr 'right' {{BinOp}} | CompExpr 'left' <rightAngle> 'op' RangeExpr 'right' {{BinOp}} | CompExpr 'left' <lessEqual> 'op' RangeExpr 'right' {{BinOp}} | CompExpr 'left' <greaterEqual> 'op' RangeExpr 'right' {{BinOp}} ;
RangeExpr : AddExpr | AddExpr 'left' <dotDot> 'op' AddExpr 'right' {{BinOp}} ;
AddExpr : MulExpr | AddExpr 'left' <plus> 'op' MulExpr 'right' {{BinOp}} | AddExpr 'left' <minus> 'op' MulExpr 'right' {{BinOp}} ;
MulExpr : UnaryExpr | MulExpr 'left' <star> 'op' UnaryExpr 'right' {{BinOp}} | MulExpr 'left' <slash> 'op' UnaryExpr 'right' {{BinOp}} ;
UnaryExpr : PostfixExpr | <kwNot> 'op' UnaryExpr 'operand' {{UnaryOp}} | <minus> 'op' UnaryExpr 'operand' {{UnaryOp}} ;
PostfixExpr : PrimaryExpr | PostfixExpr 'receiver' <leftParen> ArgList <rightParen> {{Call}} | PostfixExpr 'receiver' <leftBracket> ArgList <rightBracket> {{FailableCall}} | PostfixExpr 'receiver' <dot> <identifier> 'member' {{MemberAccess}} | PostfixExpr 'receiver' <question> {{Query}} | PostfixExpr 'receiver' <leftBrace> FieldInits <rightBrace> {{Archetype}} ;
PrimaryExpr : Literal | <identifier> 'value' {{Ident}} | <leftParen> Expression <rightParen> {{Paren}} | <kwIf> <leftParen> CondList <rightParen> <leftBrace> Statements <rightBrace> ElseClause {{If}} | <kwFor> <leftParen> ForClauses <rightParen> <leftBrace> Statements <rightBrace> {{For}} | <kwLoop> <leftBrace> Statements <rightBrace> {{Loop}} | <kwSet> <identifier> 'target' <equals> Expression 'value' {{Set}} | <kwSet> <identifier> 'target' <plusEquals> Expression 'value' {{Set}} | <kwSet> <identifier> 'target' <minusEquals> Expression 'value' {{Set}} | <kwReturn> Expression 'value' {{Return}} | <kwBreak> {{Break}} | <kwArray> <leftBrace> ArgList <rightBrace> {{ArrayLit}} | <kwMap> <leftBrace> MapEntries <rightBrace> {{MapLit}} | <leftBrace> Statements <rightBrace> {{Block}} ;
CondList : Expression 'cond' | CondList <comma> Expression 'cond' | CondList <comma> <identifier> 'name' <colonEquals> Expression 'value' ;
Literal : <integer> 'value' {{IntLit}} | <float> 'value' {{FloatLit}} | <hex> 'value' {{HexLit}} | <string> 'value' {{StringLit}} | <charLit> 'value' {{CharLit}} | <kwTrue> 'value' {{BoolLit}} | <kwFalse> 'value' {{BoolLit}} ;
ElseClause : | <kwElse> <kwIf> <leftParen> CondList <rightParen> <leftBrace> Statements <rightBrace> ElseClause | <kwElse> <leftBrace> Statements <rightBrace> ;
ForClauses : ForClause 'clause' | ForClauses <comma> ForClause 'clause' ;
ForClause : <identifier> 'name' <colon> Expression 'collection' {{}} | <identifier> 'name' <colonEquals> Expression 'range' {{}} | Expression 'filter' ;
ArgList : | Expression 'arg' | ArgList <comma> Expression 'arg' ;
FieldInits : | FieldInit 'init' | FieldInits <comma> FieldInit 'init' ;
FieldInit : <identifier> 'name' <colonEquals> Expression 'value' {{}} ;
MapEntries : | MapEntry 'entry' | MapEntries <comma> MapEntry 'entry' ;
MapEntry : Expression 'key' <fatArrow> Expression 'value' {{}} ;"
]

{ #category : 'generated' }
VerseParser class >> reduceTable [
^#(
	#(60 0 #reduceActionForStatements1: 1416193 false) 
	#(59 1 #reduceActionForProgram1: 1387521 false) 
	#(93 1 #reduceActionForLiteral2: 6778882 false) 
	#(93 1 #reduceActionForLiteral1: 6778881 false) 
	#(93 1 #reduceActionForLiteral3: 6778883 false) 
	#(93 1 #reduceActionForLiteral4: 6778884 false) 
	#(93 1 #reduceActionForLiteral5: 6778885 false) 
	#(91 1 #reduceActionForPrimaryExpr11: 5827595 false) 
	#(93 1 #reduceActionForLiteral6: 6778886 false) 
	#(93 1 #reduceActionForLiteral6: 6778887 false) 
	#(91 1 #reduceActionForPrimaryExpr2: 5827586 false) 
	#(74 0 #reduceActionForStatements1: 3137537 false) 
	#(60 2 #reduceActionForStatements2: 1416194 false) 
	#(61 1 #liftFirstValue: 1467393 false) 
	#(62 1 #liftFirstValue: 1506309 false) 
	#(62 1 #liftFirstValue: 1506310 false) 
	#(62 1 #liftFirstValue: 1506306 false) 
	#(62 1 #liftFirstValue: 1506305 false) 
	#(62 1 #liftFirstValue: 1506307 false) 
	#(62 1 #liftFirstValue: 1506308 false) 
	#(61 1 #liftFirstValue: 1467394 false) 
	#(82 1 #liftFirstValue: 4387841 false) 
	#(83 1 #liftFirstValue: 4410369 false) 
	#(84 1 #liftFirstValue: 4485121 false) 
	#(85 1 #liftFirstValue: 4564993 false) 
	#(86 1 #liftFirstValue: 4975617 false) 
	#(87 1 #liftFirstValue: 5056513 false) 
	#(88 1 #liftFirstValue: 5190657 false) 
	#(89 1 #liftFirstValue: 5330945 false) 
	#(90 1 #liftFirstValue: 5453825 false) 
	#(91 1 #liftFirstValue: 5827585 false) 
	#(91 2 #reduceActionForPrimaryExpr10: 5827594 false) 
	#(89 2 #reduceActionForUnaryExpr2: 5330946 false) 
	#(97 0 #reduceActionForStatements1: 7408641 false) 
	#(100 0 #reduceActionForStatements1: 7623681 false) 
	#(89 2 #reduceActionForUnaryExpr2: 5330947 false) 
	#(98 0 #reduceActionForStatements1: 7476225 false) 
	#(90 2 #reduceActionForPostfixExpr5: 5453829 false) 
	#(92 1 #reduceActionForCondList1: 6635521 false) 
	#(96 1 #liftFirstValue: 7251971 false) 
	#(95 1 #reduceActionForForClauses1: 7176193 false) 
	#(97 1 #reduceActionForForClauses1: 7408642 false) 
	#(100 1 #reduceActionForForClauses1: 7623682 false) 
	#(65 3 #reduceActionForAnnotatedDef1: 1795073 false) 
	#(66 3 #reduceActionForConstDef2: 1873922 false) 
	#(80 1 #reduceActionForType6: 4026374 false) 
	#(80 1 #reduceActionForType1: 4026369 false) 
	#(66 3 #reduceActionForConstDef3: 1873923 false) 
	#(72 0 #reduceActionForStatements1: 2816001 false) 
	#(91 3 #reduceActionForPrimaryExpr3: 5827587 false) 
	#(91 3 #reduceActionForPrimaryExpr14: 5827598 false) 
	#(83 3 #reduceActionForOrExpr2: 4410370 false) 
	#(84 3 #reduceActionForOrExpr2: 4485122 false) 
	#(85 3 #reduceActionForOrExpr2: 4564998 false) 
	#(85 3 #reduceActionForOrExpr2: 4564999 false) 
	#(85 3 #reduceActionForOrExpr2: 4564995 false) 
	#(85 3 #reduceActionForOrExpr2: 4564996 false) 
	#(85 3 #reduceActionForOrExpr2: 4564997 false) 
	#(85 3 #reduceActionForOrExpr2: 4564994 false) 
	#(86 3 #reduceActionForOrExpr2: 4975618 false) 
	#(87 3 #reduceActionForOrExpr2: 5056514 false) 
	#(87 3 #reduceActionForOrExpr2: 5056515 false) 
	#(88 3 #reduceActionForOrExpr2: 5190658 false) 
	#(88 3 #reduceActionForOrExpr2: 5190659 false) 
	#(98 1 #reduceActionForForClauses1: 7476226 false) 
	#(90 3 #reduceActionForPostfixExpr4: 5453828 false) 
	#(67 4 #reduceActionForVarDef2: 2071554 false) 
	#(67 4 #reduceActionForVarDef3: 2071555 false) 
	#(91 4 #reduceActionForPrimaryExpr8: 5827592 false) 
	#(91 4 #reduceActionForPrimaryExpr8: 5827593 false) 
	#(91 4 #reduceActionForPrimaryExpr8: 5827591 false) 
	#(91 4 #reduceActionForPrimaryExpr6: 5827590 false) 
	#(64 2 #liftFirstValue: 1659905 false) 
	#(63 4 #reduceActionForUsingDef1: 1587201 false) 
	#(91 4 #reduceActionForPrimaryExpr12: 5827596 false) 
	#(91 4 #reduceActionForPrimaryExpr13: 5827597 false) 
	#(80 2 #reduceActionForType2: 4026370 false) 
	#(77 0 #reduceActionForStatements1: 3837953 false) 
	#(72 1 #reduceActionForForClauses1: 2816002 false) 
	#(90 4 #reduceActionForPostfixExpr2: 5453826 false) 
	#(90 4 #reduceActionForPostfixExpr3: 5453827 false) 
	#(90 4 #reduceActionForPostfixExpr6: 5453830 false) 
	#(92 3 #reduceActionForCondList2: 6635522 false) 
	#(96 3 #reduceActionForForClause2: 7251970 false) 
	#(96 3 #reduceActionForForClause1: 7251969 false) 
	#(95 3 #reduceActionForForClauses2: 7176194 false) 
	#(64 3 #liftFirstValue: 1659906 false) 
	#(64 3 #liftFirstValue: 1659907 false) 
	#(97 3 #reduceActionForForClauses2: 7408643 false) 
	#(101 3 #reduceActionForMapEntry1: 7697409 false) 
	#(100 3 #reduceActionForForClauses2: 7623683 false) 
	#(81 1 #reduceActionForForClauses1: 4332545 false) 
	#(80 3 #reduceActionForType3: 4026371 false) 
	#(66 5 #reduceActionForConstDef1: 1873921 false) 
	#(79 0 #reduceActionForStatements1: 3976193 false) 
	#(73 2 #reduceActionForParam3: 2881539 false) 
	#(74 4 #reduceActionForForClauses2: 3137538 false) 
	#(99 3 #reduceActionForFieldInit1: 7549953 false) 
	#(98 3 #reduceActionForForClauses2: 7476227 false) 
	#(67 6 #reduceActionForVarDef1: 2071553 false) 
	#(80 4 #reduceActionForType5: 4026373 false) 
	#(80 4 #reduceActionForType4: 4026372 false) 
	#(78 1 #reduceActionForForClauses1: 3894273 false) 
	#(73 3 #reduceActionForParam1: 2881537 false) 
	#(69 2 #liftSecondValue: 2564097 false) 
	#(70 1 #liftFirstValue: 2608129 false) 
	#(75 0 #nil 3212289 false) 
	#(72 3 #reduceActionForForClauses2: 2816003 false) 
	#(94 0 #reduceActionForElseClause1: 7011329 false) 
	#(92 5 #reduceActionForCondList3: 6635523 false) 
	#(91 7 #reduceActionForPrimaryExpr5: 5827589 false) 
	#(81 3 #reduceActionForForClauses2: 4332546 false) 
	#(77 3 #reduceActionForParentClause2: 3837954 false) 
	#(79 2 #reduceActionForStatements2: 3976194 false) 
	#(76 7 #reduceActionForTypeDef3: 3250179 false) 
	#(76 7 #reduceActionForTypeDef5: 3250181 false) 
	#(73 4 #reduceActionForParam2: 2881538 false) 
	#(91 8 #reduceActionForPrimaryExpr4: 5827588 false) 
	#(78 3 #reduceActionForForClauses2: 3894274 false) 
	#(76 8 #reduceActionForTypeDef1: 3250177 false) 
	#(76 8 #reduceActionForTypeDef2: 3250178 false) 
	#(76 8 #reduceActionForTypeDef4: 3250180 false) 
	#(71 3 #liftFirstValue: 2690049 false) 
	#(70 3 #liftFirstValue: 2608130 false) 
	#(75 2 #liftSecondValue: 3212290 false) 
	#(68 9 #reduceActionForFuncDef1: 2291713 false) 
	#(73 7 #reduceActionForParam4: 2881540 false) 
	#(68 10 #reduceActionForFuncDef2: 2291714 false) 
	#(94 4 #reduceActionForElseClause3: 7011331 false) 
	#(71 6 #liftFirstValue: 2690050 false) 
	#(94 9 #reduceActionForElseClause2: 7011330 false)
	).
]

{ #category : 'generated-accessing' }
VerseParser class >> scannerClass [
	^VerseScanner
]

{ #category : 'generated' }
VerseParser class >> startingStateForProgram [
	^ 1
]

{ #category : 'generated' }
VerseParser class >> symbolNames [
	^ #('<whitespace>' '<float>' '<integer>' '<hex>' '<string>' '<charLit>' '<kwVar>' '<kwSet>' '<kwIf>' '<kwElse>' '<kwFor>' '<kwLoop>' '<kwReturn>' '<kwBreak>' '<kwClass>' '<kwStruct>' '<kwEnum>' '<kwInterface>' '<kwModule>' '<kwUsing>' '<kwNot>' '<kwAnd>' '<kwOr>' '<kwTrue>' '<kwFalse>' '<kwArray>' '<kwMap>' '<kwWhere>' '<kwType>' '<kwSubtype>' '<at>' '<identifier>' '<colonEquals>' '<fatArrow>' '<dotDot>' '<lessEqual>' '<greaterEqual>' '<notEqual>' '<plusEquals>' '<minusEquals>' '<leftParen>' '<rightParen>' '<leftBracket>' '<rightBracket>' '<leftBrace>' '<rightBrace>' '<leftAngle>' '<rightAngle>' '<colon>' '<comma>' '<dot>' '<equals>' '<plus>' '<minus>' '<star>' '<slash>' '<question>' 'B e g i n' 'Program' 'Statements' 'Statement' 'Definition' 'UsingDef' 'ModulePath' 'AnnotatedDef' 'ConstDef' 'VarDef' 'FuncDef' 'WhereClause' 'WhereConstraints' 'WhereConstraint' 'ParamList' 'Param' 'Specifiers' 'ReturnType' 'TypeDef' 'ParentClause' 'ParentList' 'EnumValues' 'Type' 'TypeArgs' 'Expression' 'OrExpr' 'AndExpr' 'CompExpr' 'RangeExpr' 'AddExpr' 'MulExpr' 'UnaryExpr' 'PostfixExpr' 'PrimaryExpr' 'CondList' 'Literal' 'ElseClause' 'ForClauses' 'ForClause' 'ArgList' 'FieldInits' 'FieldInit' 'MapEntries' 'MapEntry' 'E O F' 'error')
]

{ #category : 'generated' }
VerseParser class >> symbolTypes [
	^ #(#SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #SmaCCToken #VerseProgramNode #VerseProgramNode #OrderedCollection #VerseProgramNode #VerseProgramNode #VerseUsingDefNode #SmaCCToken #VerseAnnotatedDefNode #VerseConstDefNode #VerseVarDefNode #VerseFuncDefNode #SmaCCToken #SmaCCToken #SmaCCToken #OrderedCollection #VerseProgramNode #OrderedCollection #VerseProgramNode #VerseProgramNode #OrderedCollection #OrderedCollection #OrderedCollection #VerseProgramNode #OrderedCollection #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #VerseProgramNode #OrderedCollection #VerseProgramNode #OrderedCollection #OrderedCollection #VerseProgramNode #OrderedCollection #OrderedCollection #VerseFieldInitNode #OrderedCollection #VerseMapEntryNode #SmaCCToken #SmaCCErrorNode)
]

{ #category : 'generated' }
VerseParser class >> transitionTable [
^#(
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 54 0 9 0 59 0 13 0 60 0 6 0 102] 
#[0 0 0 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 0 10 0 102] 
#[0 0 14 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 18 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 22 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 26 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 30 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 185 0 32] 
#[0 0 189 0 32] 
#[0 0 193 0 41] 
#[0 0 197 0 41] 
#[0 0 201 0 45] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 0 209 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 0 34 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 213 0 45] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 0 217 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 0 38 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 42 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 221 0 45] 
#[0 0 225 0 45] 
#[0 0 229 0 32] 
#[1 0 46 0 2 0 46 0 3 0 46 0 4 0 46 0 5 0 46 0 6 0 46 0 7 0 46 0 8 0 46 0 9 0 46 0 11 0 46 0 12 0 46 0 13 0 46 0 14 0 46 0 20 0 46 0 21 0 46 0 22 0 46 0 23 0 46 0 24 0 46 0 25 0 46 0 26 0 46 0 27 0 46 0 31 0 46 0 32 0 7 0 33 0 46 0 35 0 46 0 36 0 46 0 37 0 46 0 38 0 11 0 41 0 46 0 43 0 46 0 45 0 46 0 46 0 11 0 47 0 46 0 48 0 237 0 49 0 46 0 51 0 46 0 52 0 46 0 53 0 46 0 54 0 46 0 55 0 46 0 56 0 46 0 57 0 241 0 74 0 46 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 0 245 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 0 249 0 60] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 0 253 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 0 54 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 58 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 62 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 66 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 70 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 74 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 78 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 82 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 86 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 0 90 0 2 0 90 0 3 0 90 0 4 0 90 0 5 0 90 0 6 0 90 0 7 0 90 0 8 0 90 0 9 0 90 0 11 0 90 0 12 0 90 0 13 0 90 0 14 0 90 0 20 0 90 0 21 0 90 0 22 0 15 0 23 0 90 0 24 0 90 0 25 0 90 0 26 0 90 0 27 0 90 0 31 0 90 0 32 0 90 0 34 0 90 0 35 0 90 0 36 0 90 0 37 0 90 0 38 0 90 0 41 0 90 0 42 0 90 0 43 0 90 0 44 0 90 0 45 0 90 0 46 0 90 0 47 0 90 0 48 0 90 0 50 0 90 0 51 0 90 0 52 0 90 0 53 0 90 0 54 0 90 0 55 0 90 0 56 0 90 0 57 0 90 0 102] 
#[1 0 94 0 2 0 94 0 3 0 94 0 4 0 94 0 5 0 94 0 6 0 94 0 7 0 94 0 8 0 94 0 9 0 94 0 11 0 94 0 12 0 94 0 13 0 94 0 14 0 94 0 20 0 94 0 21 0 19 0 22 0 94 0 23 0 94 0 24 0 94 0 25 0 94 0 26 0 94 0 27 0 94 0 31 0 94 0 32 0 94 0 34 0 94 0 35 0 94 0 36 0 94 0 37 0 94 0 38 0 94 0 41 0 94 0 42 0 94 0 43 0 94 0 44 0 94 0 45 0 94 0 46 0 94 0 47 0 94 0 48 0 94 0 50 0 94 0 51 0 94 0 52 0 94 0 53 0 94 0 54 0 94 0 55 0 94 0 56 0 94 0 57 0 94 0 102] 
#[1 0 98 0 2 0 98 0 3 0 98 0 4 0 98 0 5 0 98 0 6 0 98 0 7 0 98 0 8 0 98 0 9 0 98 0 11 0 98 0 12 0 98 0 13 0 98 0 14 0 98 0 20 0 98 0 21 0 98 0 22 0 98 0 23 0 98 0 24 0 98 0 25 0 98 0 26 0 98 0 27 0 98 0 31 0 98 0 32 0 98 0 34 0 98 0 35 0 23 0 36 0 27 0 37 0 31 0 38 0 98 0 41 0 98 0 42 0 98 0 43 0 98 0 44 0 98 0 45 0 98 0 46 0 35 0 47 0 39 0 48 0 98 0 50 0 98 0 51 0 43 0 52 0 98 0 53 0 98 0 54 0 98 0 55 0 98 0 56 0 98 0 57 0 98 0 102] 
#[0 0 102 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 106 0 2 0 106 0 3 0 106 0 4 0 106 0 5 0 106 0 6 0 106 0 7 0 106 0 8 0 106 0 9 0 106 0 11 0 106 0 12 0 106 0 13 0 106 0 14 0 106 0 20 0 106 0 21 0 106 0 22 0 106 0 23 0 106 0 24 0 106 0 25 0 106 0 26 0 106 0 27 0 106 0 31 0 106 0 32 0 106 0 34 0 47 0 35 0 106 0 36 0 106 0 37 0 106 0 38 0 106 0 41 0 106 0 42 0 106 0 43 0 106 0 44 0 106 0 45 0 106 0 46 0 106 0 47 0 106 0 48 0 106 0 50 0 106 0 51 0 106 0 52 0 51 0 53 0 55 0 54 0 106 0 55 0 106 0 56 0 106 0 57 0 106 0 102] 
#[1 0 110 0 2 0 110 0 3 0 110 0 4 0 110 0 5 0 110 0 6 0 110 0 7 0 110 0 8 0 110 0 9 0 110 0 11 0 110 0 12 0 110 0 13 0 110 0 14 0 110 0 20 0 110 0 21 0 110 0 22 0 110 0 23 0 110 0 24 0 110 0 25 0 110 0 26 0 110 0 27 0 110 0 31 0 110 0 32 0 110 0 34 0 110 0 35 0 110 0 36 0 110 0 37 0 110 0 38 0 110 0 41 0 110 0 42 0 110 0 43 0 110 0 44 0 110 0 45 0 110 0 46 0 110 0 47 0 110 0 48 0 110 0 50 0 110 0 51 0 110 0 52 0 110 0 53 0 110 0 54 0 59 0 55 0 63 0 56 0 110 0 57 0 110 0 102] 
#[0 0 114 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 118 0 2 0 118 0 3 0 118 0 4 0 118 0 5 0 118 0 6 0 118 0 7 0 118 0 8 0 118 0 9 0 118 0 11 0 118 0 12 0 118 0 13 0 118 0 14 0 118 0 20 0 118 0 21 0 118 0 22 0 118 0 23 0 118 0 24 0 118 0 25 0 118 0 26 0 118 0 27 0 118 0 31 0 118 0 32 0 118 0 34 0 118 0 35 0 118 0 36 0 118 0 37 0 118 0 38 0 67 0 41 0 118 0 42 0 71 0 43 0 118 0 44 0 75 0 45 0 118 0 46 0 118 0 47 0 118 0 48 0 118 0 50 0 79 0 51 0 118 0 52 0 118 0 53 0 118 0 54 0 118 0 55 0 118 0 56 0 83 0 57 0 118 0 102] 
#[0 0 122 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 126 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 1 73 0 33 1 77 0 49] 
#[1 1 81 0 39 1 85 0 40 1 89 0 52] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 93 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 1 97 0 92 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 1 101 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 113 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 1 109 0 95 1 113 0 96] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 1 117 0 60] 
#[0 0 46 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 130 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 1 121 0 56 1 125 0 64] 
#[0 0 134 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 138 0 46 0 138 0 50 0 105 0 54 1 129 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 1 133 0 97] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 142 0 46 0 142 0 50 0 105 0 54 1 137 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 1 141 0 100 1 145 0 101] 
#[1 0 37 0 7 0 65 0 20 0 89 0 31 1 149 0 32 1 153 0 62 1 153 0 63 1 153 0 65 1 153 0 66 1 153 0 67 1 153 0 68 1 153 0 76] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 157 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 1 177 0 80] 
#[1 1 181 0 33 1 185 0 41 1 189 0 47] 
#[0 1 193 0 42] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 1 197 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 0 146 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 201 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 205 0 85 1 205 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 209 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 213 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 217 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 221 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 225 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 229 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 233 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 237 0 88 1 237 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 241 0 88 1 241 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 245 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 249 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 138 0 42 0 101 0 45 0 138 0 50 0 105 0 54 1 129 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 1 253 0 97] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 138 0 44 0 101 0 45 0 138 0 50 0 105 0 54 1 129 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 2 1 0 97] 
#[1 2 5 0 32 0 150 0 46 0 150 0 50 2 9 0 98 2 13 0 99] 
#[0 2 17 0 32] 
#[0 0 154 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 21 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 2 25 0 80] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 29 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 33 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 37 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 0 158 0 42 0 50] 
#[1 2 41 0 42 2 45 0 50] 
#[1 0 46 0 22 0 46 0 23 2 49 0 33 0 46 0 35 0 46 0 36 0 46 0 37 0 46 0 38 0 46 0 41 0 46 0 42 0 46 0 43 0 46 0 45 0 46 0 47 0 46 0 48 2 53 0 49 0 46 0 50 0 46 0 51 0 46 0 52 0 46 0 53 0 46 0 54 0 46 0 55 0 46 0 56 0 46 0 57] 
#[0 0 162 0 42 0 50] 
#[1 2 57 0 42 2 61 0 50] 
#[0 0 166 0 42 0 50] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 2 65 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 2 69 0 32] 
#[1 2 73 0 46 2 77 0 51 2 81 0 56] 
#[0 0 170 0 42 0 44 0 46 0 50] 
#[1 2 85 0 46 2 89 0 50] 
#[0 2 93 0 34] 
#[1 2 97 0 46 2 101 0 50] 
#[0 0 174 0 46 0 50] 
#[1 0 7 0 33 0 50 0 41 0 50 0 47 0 237 0 49 0 241 0 74] 
#[0 0 178 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 182 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 0 186 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 28 0 31 0 32 0 41 0 42 0 44 0 45 0 46 0 50 0 52 0 54 0 102] 
#[1 0 190 0 2 0 190 0 3 0 190 0 4 0 190 0 5 0 190 0 6 0 190 0 7 0 190 0 8 0 190 0 9 0 190 0 11 0 190 0 12 0 190 0 13 0 190 0 14 0 190 0 20 0 190 0 21 0 190 0 24 0 190 0 25 0 190 0 26 0 190 0 27 0 190 0 28 0 190 0 31 0 190 0 32 0 87 0 41 0 190 0 42 0 190 0 44 0 190 0 45 0 190 0 46 0 190 0 50 0 190 0 52 0 190 0 54 0 190 0 102] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 2 109 0 44 1 173 0 57 2 113 0 80] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 2 117 0 80] 
#[1 0 194 0 2 0 194 0 3 0 194 0 4 0 194 0 5 0 194 0 6 0 194 0 7 0 194 0 8 0 194 0 9 0 194 0 11 0 194 0 12 0 194 0 13 0 194 0 14 0 194 0 20 0 194 0 21 0 194 0 24 0 194 0 25 0 194 0 26 0 194 0 27 0 194 0 31 0 194 0 32 0 194 0 41 0 194 0 45 0 194 0 46 2 121 0 52 0 194 0 54 0 194 0 102] 
#[1 2 125 0 15 2 129 0 16 2 133 0 17 2 137 0 18 2 141 0 19] 
#[1 0 198 0 28 2 145 0 32 0 198 0 42 2 149 0 49 0 198 0 50 2 153 0 57 2 157 0 72 2 161 0 73] 
#[0 2 165 0 32] 
#[0 0 202 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 206 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 210 0 2 0 210 0 3 0 210 0 4 0 210 0 5 0 210 0 6 0 210 0 7 0 210 0 8 0 210 0 9 0 210 0 11 0 210 0 12 0 210 0 13 0 210 0 14 0 210 0 20 0 210 0 21 0 91 0 22 0 210 0 23 0 210 0 24 0 210 0 25 0 210 0 26 0 210 0 27 0 210 0 31 0 210 0 32 0 210 0 34 0 210 0 35 0 210 0 36 0 210 0 37 0 210 0 38 0 210 0 41 0 210 0 42 0 210 0 43 0 210 0 44 0 210 0 45 0 210 0 46 0 210 0 47 0 210 0 48 0 210 0 50 0 210 0 51 0 210 0 52 0 210 0 53 0 210 0 54 0 210 0 55 0 210 0 56 0 210 0 57 0 210 0 102] 
#[1 0 214 0 2 0 214 0 3 0 214 0 4 0 214 0 5 0 214 0 6 0 214 0 7 0 214 0 8 0 214 0 9 0 214 0 11 0 214 0 12 0 214 0 13 0 214 0 14 0 214 0 20 0 214 0 21 0 214 0 22 0 214 0 23 0 214 0 24 0 214 0 25 0 214 0 26 0 214 0 27 0 214 0 31 0 214 0 32 0 214 0 34 0 214 0 35 0 95 0 36 0 99 0 37 0 103 0 38 0 214 0 41 0 214 0 42 0 214 0 43 0 214 0 44 0 214 0 45 0 214 0 46 0 107 0 47 0 111 0 48 0 214 0 50 0 214 0 51 0 115 0 52 0 214 0 53 0 214 0 54 0 214 0 55 0 214 0 56 0 214 0 57 0 214 0 102] 
#[0 0 218 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 222 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 226 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 230 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 234 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 0 238 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 242 0 2 0 242 0 3 0 242 0 4 0 242 0 5 0 242 0 6 0 242 0 7 0 242 0 8 0 242 0 9 0 242 0 11 0 242 0 12 0 242 0 13 0 242 0 14 0 242 0 20 0 242 0 21 0 242 0 22 0 242 0 23 0 242 0 24 0 242 0 25 0 242 0 26 0 242 0 27 0 242 0 31 0 242 0 32 0 242 0 34 0 242 0 35 0 242 0 36 0 242 0 37 0 242 0 38 0 242 0 41 0 242 0 42 0 242 0 43 0 242 0 44 0 242 0 45 0 242 0 46 0 242 0 47 0 242 0 48 0 242 0 50 0 242 0 51 0 242 0 52 0 119 0 53 0 123 0 54 0 242 0 55 0 242 0 56 0 242 0 57 0 242 0 102] 
#[1 0 246 0 2 0 246 0 3 0 246 0 4 0 246 0 5 0 246 0 6 0 246 0 7 0 246 0 8 0 246 0 9 0 246 0 11 0 246 0 12 0 246 0 13 0 246 0 14 0 246 0 20 0 246 0 21 0 246 0 22 0 246 0 23 0 246 0 24 0 246 0 25 0 246 0 26 0 246 0 27 0 246 0 31 0 246 0 32 0 246 0 34 0 246 0 35 0 246 0 36 0 246 0 37 0 246 0 38 0 246 0 41 0 246 0 42 0 246 0 43 0 246 0 44 0 246 0 45 0 246 0 46 0 246 0 47 0 246 0 48 0 246 0 50 0 246 0 51 0 246 0 52 0 246 0 53 0 246 0 54 0 127 0 55 0 131 0 56 0 246 0 57 0 246 0 102] 
#[1 0 250 0 2 0 250 0 3 0 250 0 4 0 250 0 5 0 250 0 6 0 250 0 7 0 250 0 8 0 250 0 9 0 250 0 11 0 250 0 12 0 250 0 13 0 250 0 14 0 250 0 20 0 250 0 21 0 250 0 22 0 250 0 23 0 250 0 24 0 250 0 25 0 250 0 26 0 250 0 27 0 250 0 31 0 250 0 32 0 250 0 34 0 250 0 35 0 250 0 36 0 250 0 37 0 250 0 38 0 250 0 41 0 250 0 42 0 250 0 43 0 250 0 44 0 250 0 45 0 250 0 46 0 250 0 47 0 250 0 48 0 250 0 50 0 250 0 51 0 250 0 52 0 250 0 53 0 250 0 54 0 135 0 55 0 139 0 56 0 250 0 57 0 250 0 102] 
#[0 0 254 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 2 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 2 169 0 42 2 89 0 50] 
#[1 2 173 0 44 2 89 0 50] 
#[0 2 177 0 33] 
#[1 2 181 0 46 2 185 0 50] 
#[0 1 6 0 46 0 50] 
#[0 1 10 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 14 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 1 18 0 2 1 18 0 3 1 18 0 4 1 18 0 5 1 18 0 6 1 18 0 7 1 18 0 8 1 18 0 9 1 18 0 11 1 18 0 12 1 18 0 13 1 18 0 14 1 18 0 20 1 18 0 21 1 18 0 24 1 18 0 25 1 18 0 26 1 18 0 27 1 18 0 31 1 18 0 32 1 18 0 41 1 18 0 45 1 18 0 46 2 189 0 52 1 18 0 54 1 18 0 102] 
#[0 1 22 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 26 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 30 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 2 193 0 45] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 2 197 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 201 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 205 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 209 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 2 213 0 45] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 1 101 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 217 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 2 217 0 96] 
#[0 1 34 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 38 0 46 0 51 0 56] 
#[0 1 42 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 2 221 0 32] 
#[0 2 225 0 32] 
#[0 1 46 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 229 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 2 233 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 1 50 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 137 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93 2 237 0 101] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 2 241 0 80 2 245 0 81] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 2 249 0 80] 
#[0 2 253 0 44] 
#[0 1 54 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 28 0 31 0 32 0 41 0 42 0 44 0 45 0 46 0 50 0 52 0 54 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 3 1 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 3 5 0 41 1 58 0 45 3 9 0 77] 
#[1 3 5 0 41 1 58 0 45 3 13 0 77] 
#[0 3 17 0 45] 
#[1 3 5 0 41 1 58 0 45 3 21 0 77] 
#[0 3 25 0 45] 
#[1 3 29 0 41 3 33 0 49] 
#[0 3 37 0 32] 
#[0 3 41 0 32] 
#[1 3 45 0 28 3 49 0 42 3 53 0 50 3 57 0 69] 
#[0 1 62 0 28 0 42 0 50] 
#[0 3 61 0 48] 
#[0 1 66 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 70 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 3 65 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 1 74 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[1 2 5 0 32 3 69 0 99] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 3 73 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 3 77 0 60] 
#[1 0 46 0 22 0 46 0 23 3 81 0 33 0 46 0 35 0 46 0 36 0 46 0 37 0 46 0 38 0 46 0 41 0 46 0 42 0 46 0 43 0 46 0 45 0 46 0 47 0 46 0 48 0 46 0 50 0 46 0 51 0 46 0 52 0 46 0 53 0 46 0 54 0 46 0 55 0 46 0 56 0 46 0 57] 
#[0 1 78 0 42 0 50] 
#[0 1 82 0 42 0 50] 
#[0 1 86 0 42 0 50] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 3 85 0 60] 
#[0 1 90 0 42 0 50] 
#[0 1 94 0 46 0 51 0 56] 
#[0 1 98 0 46 0 51 0 56] 
#[0 1 102 0 42 0 44 0 46 0 50] 
#[0 1 106 0 46 0 50] 
#[0 1 110 0 46 0 50] 
#[0 1 114 0 42 0 50] 
#[1 3 89 0 42 3 93 0 50] 
#[0 1 118 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 28 0 31 0 32 0 41 0 42 0 44 0 45 0 46 0 50 0 52 0 54 0 102] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 3 97 0 80] 
#[0 1 122 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 3 101 0 32 3 105 0 78] 
#[0 3 109 0 45] 
#[0 3 113 0 45] 
#[1 1 126 0 32 1 126 0 46 3 117 0 79] 
#[0 3 121 0 45] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 3 125 0 60] 
#[1 2 145 0 32 0 198 0 42 2 149 0 49 0 198 0 50 2 153 0 57 3 129 0 72 2 161 0 73] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 3 133 0 80] 
#[0 1 130 0 28 0 42 0 50] 
#[0 3 137 0 49] 
#[1 3 141 0 32 3 145 0 70 3 145 0 71] 
#[1 0 50 0 47 0 50 0 49 0 50 0 52 3 153 0 74] 
#[1 2 145 0 32 2 149 0 49 2 153 0 57 3 157 0 73] 
#[0 3 161 0 42] 
#[0 1 134 0 33 0 41 0 47 0 49 0 52] 
#[0 1 138 0 46 0 50] 
#[0 1 142 0 46 0 50] 
#[0 1 146 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 3 165 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 3 169 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 3 173 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 1 150 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 28 0 31 0 32 0 41 0 42 0 44 0 45 0 46 0 50 0 52 0 54 0 102] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 3 177 0 80] 
#[0 1 154 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 28 0 31 0 32 0 41 0 42 0 44 0 45 0 46 0 50 0 52 0 54 0 102] 
#[0 1 158 0 42 0 50] 
#[1 3 181 0 42 3 185 0 50] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 3 189 0 60] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 3 193 0 60] 
#[1 3 197 0 32 3 201 0 46] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 3 205 0 60] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 3 209 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 3 213 0 42 3 53 0 50] 
#[0 1 162 0 28 0 42 0 50] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 3 217 0 80] 
#[0 3 221 0 49] 
#[1 1 166 0 42 3 225 0 50] 
#[0 1 170 0 42 0 50] 
#[1 1 189 0 47 3 229 0 49 1 174 0 52 3 233 0 75] 
#[0 1 178 0 28 0 42 0 50] 
#[1 0 50 0 47 0 50 0 49 0 50 0 52 3 237 0 74] 
#[1 1 182 0 2 1 182 0 3 1 182 0 4 1 182 0 5 1 182 0 6 1 182 0 7 1 182 0 8 1 182 0 9 3 241 0 10 1 182 0 11 1 182 0 12 1 182 0 13 1 182 0 14 1 182 0 20 1 182 0 21 1 182 0 22 1 182 0 23 1 182 0 24 1 182 0 25 1 182 0 26 1 182 0 27 1 182 0 31 1 182 0 32 1 182 0 34 1 182 0 35 1 182 0 36 1 182 0 37 1 182 0 38 1 182 0 41 1 182 0 42 1 182 0 43 1 182 0 44 1 182 0 45 1 182 0 46 1 182 0 47 1 182 0 48 1 182 0 50 1 182 0 51 1 182 0 52 1 182 0 53 1 182 0 54 1 182 0 55 1 182 0 56 1 182 0 57 3 245 0 94 1 182 0 102] 
#[0 1 186 0 42 0 50] 
#[0 1 190 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 194 0 42 0 50] 
#[0 1 198 0 45] 
#[0 3 249 0 32] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 3 253 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 4 1 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 1 202 0 32 0 46] 
#[0 1 206 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 4 5 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 1 210 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 0 50 0 47 0 50 0 49 4 9 0 74] 
#[0 1 214 0 28 0 42 0 50] 
#[1 4 13 0 29 4 17 0 30] 
#[1 3 141 0 32 4 21 0 71] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 4 25 0 80] 
#[0 4 29 0 52] 
#[1 1 189 0 47 3 229 0 49 1 174 0 52 4 33 0 75] 
#[1 4 37 0 9 4 41 0 45] 
#[0 1 218 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 1 222 0 42 0 50] 
#[0 1 226 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 1 230 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[0 1 234 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 1 189 0 47 4 45 0 49] 
#[0 1 238 0 42 0 50] 
#[0 4 49 0 41] 
#[0 1 242 0 42 0 50] 
#[0 1 246 0 52] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 4 53 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 4 57 0 52] 
#[0 4 61 0 41] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 4 65 0 60] 
#[1 1 161 0 29 1 165 0 32 1 169 0 43 1 173 0 57 4 69 0 80] 
#[0 4 73 0 32] 
#[0 1 250 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 4 77 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 205 0 32 0 97 0 41 0 101 0 45 0 105 0 54 1 93 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 4 81 0 92 0 173 0 93] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 4 85 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[0 1 254 0 28 0 42 0 50] 
#[0 4 89 0 42] 
#[0 2 2 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 24 0 25 0 26 0 27 0 31 0 32 0 41 0 45 0 46 0 54 0 102] 
#[1 4 93 0 42 2 45 0 50] 
#[0 2 6 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102] 
#[0 2 10 0 42 0 50] 
#[0 4 97 0 45] 
#[1 0 6 0 2 0 6 0 3 0 6 0 4 0 6 0 5 0 6 0 6 0 6 0 7 0 6 0 8 0 6 0 9 0 6 0 11 0 6 0 12 0 6 0 13 0 6 0 14 0 6 0 20 0 6 0 21 0 6 0 24 0 6 0 25 0 6 0 26 0 6 0 27 0 6 0 31 0 6 0 32 0 6 0 41 0 6 0 45 0 6 0 46 0 6 0 54 4 101 0 60] 
#[1 0 17 0 2 0 21 0 3 0 25 0 4 0 29 0 5 0 33 0 6 0 37 0 7 0 41 0 8 0 45 0 9 0 49 0 11 0 53 0 12 0 57 0 13 0 61 0 14 0 65 0 20 0 69 0 21 0 73 0 24 0 77 0 25 0 81 0 26 0 85 0 27 0 89 0 31 0 93 0 32 0 97 0 41 0 101 0 45 4 105 0 46 0 105 0 54 0 109 0 61 0 109 0 62 0 109 0 63 0 109 0 65 0 109 0 66 0 109 0 67 0 109 0 68 0 109 0 76 0 109 0 82 0 145 0 83 0 149 0 84 0 153 0 85 0 153 0 86 0 161 0 87 0 165 0 88 0 165 0 89 0 173 0 90 0 173 0 91 0 173 0 93] 
#[1 1 182 0 2 1 182 0 3 1 182 0 4 1 182 0 5 1 182 0 6 1 182 0 7 1 182 0 8 1 182 0 9 3 241 0 10 1 182 0 11 1 182 0 12 1 182 0 13 1 182 0 14 1 182 0 20 1 182 0 21 1 182 0 22 1 182 0 23 1 182 0 24 1 182 0 25 1 182 0 26 1 182 0 27 1 182 0 31 1 182 0 32 1 182 0 34 1 182 0 35 1 182 0 36 1 182 0 37 1 182 0 38 1 182 0 41 1 182 0 42 1 182 0 43 1 182 0 44 1 182 0 45 1 182 0 46 1 182 0 47 1 182 0 48 1 182 0 50 1 182 0 51 1 182 0 52 1 182 0 53 1 182 0 54 1 182 0 55 1 182 0 56 1 182 0 57 4 109 0 94 1 182 0 102] 
#[0 2 14 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 11 0 12 0 13 0 14 0 20 0 21 0 22 0 23 0 24 0 25 0 26 0 27 0 31 0 32 0 34 0 35 0 36 0 37 0 38 0 41 0 42 0 43 0 44 0 45 0 46 0 47 0 48 0 50 0 51 0 52 0 53 0 54 0 55 0 56 0 57 0 102]
	).
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForAnnotatedDef1: nodes [
	| result |
	result := VerseAnnotatedDefNode new.
	result annotation: (nodes at: 2).
	result definition: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForCondList1: nodes [
	| result |
	result := Array new: 3.
	result at: 1 put: (OrderedCollection new: 2).
	result at: 2 put: (OrderedCollection new: 2).
	result at: 3 put: (OrderedCollection new: 2).
	self add: (nodes at: 1) to: (result at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForCondList2: nodes [
	| result |
	result := nodes at: 1.
	self add: (nodes at: 3) to: (result at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForCondList3: nodes [
	| result |
	result := nodes at: 1.
	self add: (nodes at: 3) to: (result at: 2).
	self add: (nodes at: 5) to: (result at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForConstDef1: nodes [
	| result |
	result := VerseConstDefNode new.
	result name: (nodes at: 1).
	result type: (nodes at: 3).
	result value: (nodes at: 5).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForConstDef2: nodes [
	| result |
	result := VerseConstDefNode new.
	result name: (nodes at: 1).
	result value: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForConstDef3: nodes [
	| result |
	result := VerseConstDefNode new.
	result name: (nodes at: 1).
	result type: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForElseClause1: nodes [
	| result |
	result := Array new: 4.
	result at: 1 put: (OrderedCollection new: 2).
	result at: 2 put: (OrderedCollection new: 2).
	result at: 3 put: (OrderedCollection new: 2).
	result at: 4 put: (OrderedCollection new: 2).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForElseClause2: nodes [
	| result |
	result := nodes at: 9.
	self addAllFirst: ((nodes at: 4) at: 1) to: (result at: 1).
	self addAllFirst: ((nodes at: 4) at: 2) to: (result at: 2).
	self addAllFirst: ((nodes at: 4) at: 3) to: (result at: 3).
	self addAllFirst: (nodes at: 7) to: (result at: 4).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForElseClause3: nodes [
	| result |
	result := Array new: 4.
	result at: 1 put: (OrderedCollection new: 2).
	result at: 2 put: (OrderedCollection new: 2).
	result at: 3 put: (OrderedCollection new: 2).
	result at: 4 put: (OrderedCollection new: 2).
	self addAll: (nodes at: 3) to: (result at: 4).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForFieldInit1: nodes [
	| result |
	result := VerseFieldInitNode new.
	result name: (nodes at: 1).
	result value: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForForClause1: nodes [
	| result |
	result := VerseForClauseNode new.
	result name: (nodes at: 1).
	result collection: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForForClause2: nodes [
	| result |
	result := VerseForClauseNode new.
	result name: (nodes at: 1).
	result range: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForForClauses1: nodes [
	| result |
	result := OrderedCollection new: 2.
	self add: (nodes at: 1) to: result.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForForClauses2: nodes [
	| result |
	result := nodes at: 1.
	self add: (nodes at: 3) to: result.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForFuncDef1: nodes [
	| result |
	result := VerseFuncDefNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addNodes: (nodes at: 4) to: result params.
	result addTokens: (nodes at: 6) to: result specs.
	result type: (nodes at: 7).
	result body: (nodes at: 9).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForFuncDef2: nodes [
	| result |
	result := VerseFuncDefNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addNodes: (nodes at: 4) to: result params.
	result addTokens: (nodes at: 7) to: result specs.
	result type: (nodes at: 8).
	result body: (nodes at: 10).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForLiteral1: nodes [
	| result |
	result := VerseIntLitNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForLiteral2: nodes [
	| result |
	result := VerseFloatLitNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForLiteral3: nodes [
	| result |
	result := VerseHexLitNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForLiteral4: nodes [
	| result |
	result := VerseStringLitNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForLiteral5: nodes [
	| result |
	result := VerseCharLitNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForLiteral6: nodes [
	| result |
	result := VerseBoolLitNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForMapEntry1: nodes [
	| result |
	result := VerseMapEntryNode new.
	result key: (nodes at: 1).
	result value: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForOrExpr2: nodes [
	| result |
	result := VerseBinOpNode new.
	result left: (nodes at: 1).
	result op: (nodes at: 2).
	result right: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForParam1: nodes [
	| result |
	result := VerseParamNode new.
	result name: (nodes at: 1).
	result type: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForParam2: nodes [
	| result |
	result := VerseParamNode new.
	result name: (nodes at: 2).
	result type: (nodes at: 4).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForParam3: nodes [
	| result |
	result := VerseParamNode new.
	result name: (nodes at: 2).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForParam4: nodes [
	| result |
	result := VerseFuncParamNode new.
	result name: (nodes at: 1).
	result addNodes: (nodes at: 3) to: result params.
	result addTokens: (nodes at: 5) to: result specs.
	result type: (nodes at: 7).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForParentClause2: nodes [
	| result |
	result := nodes at: 2.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPostfixExpr2: nodes [
	| result |
	result := VerseCallNode new.
	result receiver: (nodes at: 1).
	result addNodes: (nodes at: 3) to: result args.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPostfixExpr3: nodes [
	| result |
	result := VerseFailableCallNode new.
	result receiver: (nodes at: 1).
	result addNodes: (nodes at: 3) to: result args.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPostfixExpr4: nodes [
	| result |
	result := VerseMemberAccessNode new.
	result receiver: (nodes at: 1).
	result member: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPostfixExpr5: nodes [
	| result |
	result := VerseQueryNode new.
	result receiver: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPostfixExpr6: nodes [
	| result |
	result := VerseArchetypeNode new.
	result receiver: (nodes at: 1).
	result addNodes: (nodes at: 3) to: result inits.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr10: nodes [
	| result |
	result := VerseReturnNode new.
	result value: (nodes at: 2).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr11: nodes [
	| result |
	result := VerseBreakNode new.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr12: nodes [
	| result |
	result := VerseArrayLitNode new.
	result addNodes: (nodes at: 3) to: result args.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr13: nodes [
	| result |
	result := VerseMapLitNode new.
	result addNodes: (nodes at: 3) to: result entries.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr14: nodes [
	| result |
	result := VerseBlockNode new.
	result addNodes: (nodes at: 2) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr2: nodes [
	| result |
	result := VerseIdentNode new.
	result value: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr3: nodes [
	| result |
	result := VerseParenNode new.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr4: nodes [
	| result |
	result := VerseIfNode new.
	result addNodes: ((nodes at: 3) at: 1) to: result conds.
	result addTokens: ((nodes at: 3) at: 2) to: result names.
	result addNodes: ((nodes at: 3) at: 3) to: result values.
	result addNodes: (nodes at: 6) to: result statements.
	result addNodes: ((nodes at: 8) at: 1) to: result conds.
	result addTokens: ((nodes at: 8) at: 2) to: result names.
	result addNodes: ((nodes at: 8) at: 3) to: result values.
	result addNodes: ((nodes at: 8) at: 4) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr5: nodes [
	| result |
	result := VerseForNode new.
	result addNodes: (nodes at: 3) to: result clauses.
	result addNodes: (nodes at: 6) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr6: nodes [
	| result |
	result := VerseLoopNode new.
	result addNodes: (nodes at: 3) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForPrimaryExpr8: nodes [
	| result |
	result := VerseSetNode new.
	result target: (nodes at: 2).
	result value: (nodes at: 4).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForProgram1: nodes [
	| result |
	result := VerseProgramNode new.
	result addNodes: (nodes at: 1) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForStatements1: nodes [
	| result |
	result := OrderedCollection new: 2.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForStatements2: nodes [
	| result |
	result := nodes at: 1.
	self add: (nodes at: 2) to: result.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForType1: nodes [
	| result |
	result := VerseNamedNode new.
	result name: (nodes at: 1).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForType2: nodes [
	| result |
	result := VerseOptionalNode new.
	result inner: (nodes at: 2).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForType3: nodes [
	| result |
	result := VerseArrayTypeNode new.
	result inner: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForType4: nodes [
	| result |
	result := VerseMapTypeNode new.
	result key: (nodes at: 2).
	result value: (nodes at: 4).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForType5: nodes [
	| result |
	result := VerseGenericTypeNode new.
	result name: (nodes at: 1).
	result addNodes: (nodes at: 3) to: result args.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForType6: nodes [
	| result |
	result := VerseTypeTypeNode new.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForTypeDef1: nodes [
	| result |
	result := VerseClassNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addTokens: (nodes at: 5) to: result parents.
	result addNodes: (nodes at: 7) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForTypeDef2: nodes [
	| result |
	result := VerseStructNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addTokens: (nodes at: 5) to: result parents.
	result addNodes: (nodes at: 7) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForTypeDef3: nodes [
	| result |
	result := VerseEnumNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addTokens: (nodes at: 6) to: result values.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForTypeDef4: nodes [
	| result |
	result := VerseInterfaceNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addTokens: (nodes at: 5) to: result parents.
	result addNodes: (nodes at: 7) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForTypeDef5: nodes [
	| result |
	result := VerseModuleNode new.
	result name: (nodes at: 1).
	result addTokens: (nodes at: 2) to: result specs.
	result addNodes: (nodes at: 6) to: result statements.
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForUnaryExpr2: nodes [
	| result |
	result := VerseUnaryOpNode new.
	result op: (nodes at: 1).
	result operand: (nodes at: 2).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForUsingDef1: nodes [
	| result |
	result := VerseUsingDefNode new.
	result path: (nodes at: 3).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForVarDef1: nodes [
	| result |
	result := VerseVarDefNode new.
	result name: (nodes at: 2).
	result type: (nodes at: 4).
	result value: (nodes at: 6).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForVarDef2: nodes [
	| result |
	result := VerseVarDefNode new.
	result name: (nodes at: 2).
	result value: (nodes at: 4).
	^ result
]

{ #category : 'generated-reduction actions' }
VerseParser >> reduceActionForVarDef3: nodes [
	| result |
	result := VerseVarDefNode new.
	result name: (nodes at: 2).
	result type: (nodes at: 4).
	^ result
]
