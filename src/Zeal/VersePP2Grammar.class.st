Class {
	#name : 'VersePP2Grammar',
	#superclass : 'PP2CompositeNode',
	#instVars : [
		'addExpr',
		'addOp',
		'andExpr',
		'annotatedDef',
		'anonParam',
		'archetypeOp',
		'argList',
		'arrayExpr',
		'arrayType',
		'blockExpr',
		'boolLit',
		'breakExpr',
		'callOp',
		'charLit',
		'charLiteral',
		'comment',
		'compExpr',
		'compOp',
		'condBinding',
		'condList',
		'constDef',
		'definition',
		'elseClause',
		'expression',
		'fieldInit',
		'fieldInits',
		'float',
		'floatLit',
		'forClause',
		'forClauses',
		'forExpr',
		'funcDef',
		'funcTypeParam',
		'identExpr',
		'identifier',
		'ifExpr',
		'indexOp',
		'integer',
		'integerLit',
		'literal',
		'loopExpr',
		'mapEntries',
		'mapEntry',
		'mapExpr',
		'memberOp',
		'mulExpr',
		'mulOp',
		'namedType',
		'negExpr',
		'notExpr',
		'optionalType',
		'orExpr',
		'param',
		'paramList',
		'parenExpr',
		'parentClause',
		'postfixExpr',
		'postfixOp',
		'primaryExpr',
		'queryOp',
		'rangeExpr',
		'returnExpr',
		'setExpr',
		'setOp',
		'skip',
		'specifier',
		'specifiers',
		'statement',
		'statements',
		'stringLit',
		'stringLiteral',
		'type',
		'typeAnnotation',
		'typeDef',
		'typeKind',
		'typedParam',
		'unaryExpr',
		'usingDef',
		'usingPath',
		'varDef',
		'whereClause',
		'whereConstraint',
		'whitespace',
		'ws',
		'kwVar',
		'kwSet',
		'kwIf',
		'kwElse',
		'kwFor',
		'kwLoop',
		'kwReturn',
		'kwBreak',
		'kwNot',
		'kwAnd',
		'kwOr',
		'kwTrue',
		'kwFalse',
		'kwClass',
		'kwStruct',
		'kwEnum',
		'kwInterface',
		'kwModule',
		'kwUsing',
		'kwArray',
		'kwMap',
		'kwWhere',
		'kwType',
		'kwSubtype',
		'elseIfClause',
		'elseBlock',
		'fieldDecl',
		'kwCase',
		'caseExpr',
		'caseEntries',
		'caseEntry'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'expressions' }
VersePP2Grammar >> addExpr [
	^ mulExpr , (addOp , mulExpr ==> [:n | {n first. n second}]) star
		==> [:nodes | self leftAssoc: nodes first ops: nodes second]
]

{ #category : 'expressions' }
VersePP2Grammar >> addOp [
	^ ($+ asPParser / $- asPParser) flatten trim , '=' asPParser not ==> [:nodes | nodes first]
]

{ #category : 'expressions' }
VersePP2Grammar >> andExpr [
	^ compExpr , (kwAnd trim , compExpr ==> [:n | {'and'. n second}]) star
		==> [:nodes | self leftAssoc: nodes first ops: nodes second]
]

{ #category : 'definitions' }
VersePP2Grammar >> annotatedDef [
	^ $@ asPParser trim , identifier trim , definition ==> [:n | {#annotated. n second. n third}]
]

{ #category : 'definitions' }
VersePP2Grammar >> anonParam [
	^ $: asPParser trim , identifier trim ==> [:n | {#anonParam. n second}]
]

{ #category : 'expressions' }
VersePP2Grammar >> archetypeOp [
	^ ${ asPParser trim , fieldInits , $} asPParser trim ==> [:n | [:recv | {#archetype. recv. n second}]]
]

{ #category : 'expressions' }
VersePP2Grammar >> argList [
	^ (expression , ($, asPParser trim , expression ==> [:n | n second]) star ==> [:n | {n first} , n second]) optional
		==> [:n | n ifNil: [#()] ifNotNil: [:v | v]]
]

{ #category : 'expressions' }
VersePP2Grammar >> arrayExpr [
	^ kwArray trim , ${ asPParser trim , argList , $} asPParser trim ==> [:n | {#array. n third}]
]

{ #category : 'types' }
VersePP2Grammar >> arrayType [
	^ $[ asPParser trim , $] asPParser trim , type ==> [:nodes | '[]' , nodes third]
]

{ #category : 'expressions' }
VersePP2Grammar >> blockExpr [
	^ ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#block. n second}]
]

{ #category : 'expressions' }
VersePP2Grammar >> boolLit [
	^ (kwTrue / kwFalse) flatten trim ==> [:v | {#bool. v}]
]

{ #category : 'expressions' }
VersePP2Grammar >> breakExpr [
	^ kwBreak trim ==> [:n | #break]
]

{ #category : 'expressions' }
VersePP2Grammar >> callOp [
	^ $( asPParser trim , argList , $) asPParser trim ==> [:n | [:recv | {#call. recv. n second}]]
]

{ #category : 'expressions' }
VersePP2Grammar >> caseEntries [
	^ caseEntry star
]

{ #category : 'expressions' }
VersePP2Grammar >> caseEntry [
	^ expression , '=>' asPParser trim , expression ==> [:n | {n first. n third}]
]

{ #category : 'expressions' }
VersePP2Grammar >> caseExpr [
	^ kwCase trim , $( asPParser trim , expression , $) asPParser trim , ${ asPParser trim , caseEntries , $} asPParser trim
	  ==> [:n | {#case. n third. n sixth}]
]

{ #category : 'expressions' }
VersePP2Grammar >> charLit [
	^ charLiteral trim ==> [:v | {#char. v}]
]

{ #category : 'tokens' }
VersePP2Grammar >> charLiteral [
	^ ($' asPParser , ($\ asPParser , #any asPParser / $' asPParser negate) , $' asPParser) flatten
]

{ #category : 'tokens' }
VersePP2Grammar >> comment [
	^ $# asPParser , (Character cr asPParser / Character lf asPParser) negate star
]

{ #category : 'expressions' }
VersePP2Grammar >> compExpr [
	^ rangeExpr , (compOp , rangeExpr ==> [:n | {n first. n second}]) optional
		==> [:nodes | nodes second ifNil: [nodes first] ifNotNil: [:op | {#binop. op first. nodes first. op second}]]
]

{ #category : 'expressions' }
VersePP2Grammar >> compOp [
	^ '<=' asPParser trim / '>=' asPParser trim / '<>' asPParser trim / $= asPParser trim / $< asPParser trim / $> asPParser trim
]

{ #category : 'expressions' }
VersePP2Grammar >> condBinding [
	^ identifier trim , ':=' asPParser trim , expression ==> [:n | {#binding. n first. n third}]
]

{ #category : 'expressions' }
VersePP2Grammar >> condList [
	^ (condBinding / expression) , ($, asPParser trim , (condBinding / expression) ==> [:n | n second]) star
	  ==> [:n | {n first} , n second]
]

{ #category : 'definitions' }
VersePP2Grammar >> constDef [
	^ (identifier trim , specifiers , $: asPParser trim , type , $= asPParser trim , expression
	    ==> [:n | | node | node := {#const. n first. (n at: 4). (n at: 6)}. 
			n second notEmpty ifTrue: [node := {#const. n first. (n at: 4). (n at: 6). n second}]. node])
	  / (identifier trim , ':=' asPParser trim , expression
	    ==> [:n | {#const. n first. nil. n third}])
]

{ #category : 'definitions' }
VersePP2Grammar >> definition [
	^ annotatedDef / typeDef / funcDef / varDef / constDef / fieldDecl / usingDef
]

{ #category : 'expressions' }
VersePP2Grammar >> elseBlock [
	^ ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#else. n second}]
]

{ #category : 'expressions' }
VersePP2Grammar >> elseClause [
	^ kwElse trim , (elseIfClause / elseBlock) ==> [:n | n second]
]

{ #category : 'expressions' }
VersePP2Grammar >> elseIfClause [
	^ kwIf trim , $( asPParser trim , condList , $) asPParser trim , ${ asPParser trim , statements , $} asPParser trim , elseClause optional
	  ==> [:n | {#elseif. n third. n sixth. n eighth}]
]

{ #category : 'expressions' }
VersePP2Grammar >> expression [
	^ orExpr
]

{ #category : 'definitions' }
VersePP2Grammar >> fieldDecl [
	^ identifier trim , specifiers , $: asPParser trim , type ==> [:n | {#field. n first. (n at: 4). n second}]
]

{ #category : 'expressions' }
VersePP2Grammar >> fieldInit [
	^ identifier trim , ':=' asPParser trim , expression ==> [:n | {n first. n third}]
]

{ #category : 'expressions' }
VersePP2Grammar >> fieldInits [
	^ (fieldInit , (($, asPParser optional trim) , fieldInit ==> [:n | n second]) star ==> [:n | {n first} , n second]) optional
	  ==> [:n | n ifNil: [#()] ifNotNil: [:v | v]]
]

{ #category : 'tokens' }
VersePP2Grammar >> float [
	^ ($- asPParser optional , #digit asPParser plus , $. asPParser , #digit asPParser plus , 
		(($e asPParser / $E asPParser) , ($+ asPParser / $- asPParser) optional , #digit asPParser plus) optional) flatten
]

{ #category : 'expressions' }
VersePP2Grammar >> floatLit [
	^ float trim ==> [:v | {#float. v}]
]

{ #category : 'expressions' }
VersePP2Grammar >> forClause [
	^ (identifier trim , ':=' asPParser trim , expression ==> [:n | {#forBind. n first. n third}])
	/ (identifier trim , $: asPParser trim , expression ==> [:n | {#forIn. n first. n third}])
	/ (expression ==> [:n | {#forFilter. n}])
]

{ #category : 'expressions' }
VersePP2Grammar >> forClauses [
	^ forClause , ($, asPParser trim , forClause ==> [:n | n second]) star ==> [:n | {n first} , n second]
]

{ #category : 'expressions' }
VersePP2Grammar >> forExpr [
	^ kwFor trim , $( asPParser trim , forClauses , $) asPParser trim ,
	  ${ asPParser trim , statements , $} asPParser trim
	  ==> [:n | {#for. n third. n sixth}]
]

{ #category : 'definitions' }
VersePP2Grammar >> funcDef [
	^ identifier trim , specifiers , $( asPParser trim , paramList , whereClause optional , $) asPParser trim , specifiers , ($: asPParser trim , type) optional , $= asPParser trim , expression
	  ==> [:n | {#func. n first. n second. (n at: 4). (n at: 7). (n at: 8) ifNotNil: [:t | t second]. (n at: 10)}]
]

{ #category : 'definitions' }
VersePP2Grammar >> funcTypeParam [
	^ identifier trim , $( asPParser trim , paramList , $) asPParser trim , specifiers , $: asPParser trim , type
	  ==> [:n | {#funcParam. n first. n third. n fifth. n seventh}]
]

{ #category : 'expressions' }
VersePP2Grammar >> identExpr [
	^ identifier trim ==> [:v | {#ident. v}]
]

{ #category : 'tokens' }
VersePP2Grammar >> identifier [
	^ (#letter asPParser / $_ asPParser) , (#word asPParser / $_ asPParser) star ==> [:nodes | 
		String streamContents: [:s | s nextPut: nodes first. nodes second do: [:ch | s nextPut: ch]]]
]

{ #category : 'expressions' }
VersePP2Grammar >> ifExpr [
	^ kwIf trim , $( asPParser trim , condList , $) asPParser trim , 
	  ${ asPParser trim , statements , $} asPParser trim , elseClause optional
	  ==> [:n | {#if. n third. n sixth. n eighth}]
]

{ #category : 'expressions' }
VersePP2Grammar >> indexOp [
	^ $[ asPParser trim , argList , $] asPParser trim ==> [:n | [:recv | {#index. recv. n second}]]
]

{ #category : 'tokens' }
VersePP2Grammar >> integer [
	^ ($- asPParser optional , #digit asPParser plus) flatten
]

{ #category : 'expressions' }
VersePP2Grammar >> integerLit [
	^ integer trim ==> [:v | {#int. v}]
]

{ #category : 'keywords' }
VersePP2Grammar >> kwAnd [ ^ 'and' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwArray [ ^ 'array' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwBreak [ ^ 'break' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwCase [ ^ 'case' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwClass [ ^ 'class' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwElse [ ^ 'else' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwEnum [ ^ 'enum' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwFalse [ ^ 'false' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwFor [ ^ 'for' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwIf [ ^ 'if' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwInterface [ ^ 'interface' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwLoop [ ^ 'loop' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwMap [ ^ 'map' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwModule [ ^ 'module' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwNot [ ^ 'not' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwOr [ ^ 'or' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwReturn [ ^ 'return' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwSet [ ^ 'set' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwStruct [ ^ 'struct' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwSubtype [ ^ 'subtype' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwTrue [ ^ 'true' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwType [ ^ 'type' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwUsing [ ^ 'using' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwVar [ ^ 'var' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'keywords' }
VersePP2Grammar >> kwWhere [ ^ 'where' asPParser , (#word asPParser / $_ asPParser) not
]

{ #category : 'helpers' }
VersePP2Grammar >> leftAssoc: left ops: opPairs [
	| result |
	result := left.
	opPairs do: [:pair | result := {#binop. pair first. result. pair second}].
	^ result
]

{ #category : 'expressions' }
VersePP2Grammar >> literal [
	^ floatLit / integerLit / stringLit / charLit / boolLit
]

{ #category : 'expressions' }
VersePP2Grammar >> loopExpr [
	^ kwLoop trim , ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#loop. n third}]
]

{ #category : 'expressions' }
VersePP2Grammar >> mapEntries [
	^ (mapEntry , ($, asPParser trim , mapEntry ==> [:n | n second]) star ==> [:n | {n first} , n second]) optional
	  ==> [:n | n ifNil: [#()] ifNotNil: [:v | v]]
]

{ #category : 'expressions' }
VersePP2Grammar >> mapEntry [
	^ expression , '=>' asPParser trim , expression ==> [:n | {n first. n third}]
]

{ #category : 'expressions' }
VersePP2Grammar >> mapExpr [
	^ kwMap trim , ${ asPParser trim , mapEntries , $} asPParser trim ==> [:n | {#map. n third}]
]

{ #category : 'expressions' }
VersePP2Grammar >> memberOp [
	^ $. asPParser trim , identifier trim ==> [:n | [:recv | {#member. recv. n second}]]
]

{ #category : 'expressions' }
VersePP2Grammar >> mulExpr [
	^ unaryExpr , (mulOp , unaryExpr ==> [:n | {n first. n second}]) star
		==> [:nodes | self leftAssoc: nodes first ops: nodes second]
]

{ #category : 'expressions' }
VersePP2Grammar >> mulOp [
	^ ($* asPParser / $/ asPParser) flatten trim
]

{ #category : 'types' }
VersePP2Grammar >> namedType [
	^ identifier trim
]

{ #category : 'expressions' }
VersePP2Grammar >> negExpr [
	^ $- asPParser trim , unaryExpr ==> [:n | {#unary. '-'. n second}]
]

{ #category : 'expressions' }
VersePP2Grammar >> notExpr [
	^ kwNot trim , unaryExpr ==> [:n | {#unary. 'not'. n second}]
]

{ #category : 'types' }
VersePP2Grammar >> optionalType [
	^ $? asPParser trim , type ==> [:nodes | '?' , nodes second]
]

{ #category : 'expressions' }
VersePP2Grammar >> orExpr [
	^ andExpr , (kwOr trim , andExpr ==> [:n | {'or'. n second}]) star
		==> [:nodes | self leftAssoc: nodes first ops: nodes second]
]

{ #category : 'definitions' }
VersePP2Grammar >> param [
	^ funcTypeParam / typedParam / anonParam
]

{ #category : 'definitions' }
VersePP2Grammar >> paramList [
	^ (param , ($, asPParser trim , param ==> [:n | n second]) star ==> [:n | {n first} , n second]) optional
	  ==> [:n | n ifNil: [#()] ifNotNil: [:v | v]]
]

{ #category : 'expressions' }
VersePP2Grammar >> parenExpr [
	^ $( asPParser trim , expression , $) asPParser trim ==> [:n | n second]
]

{ #category : 'definitions' }
VersePP2Grammar >> parentClause [
	^ ($( asPParser trim , identifier trim , ($, asPParser trim , identifier trim ==> [:n | n second]) star , $) asPParser trim ==> [:n | {n second} , n third]) optional
	  ==> [:n | n ifNil: [#()] ifNotNil: [:v | v]]
]

{ #category : 'expressions' }
VersePP2Grammar >> postfixExpr [
	^ primaryExpr , postfixOp star ==> [:nodes | 
		| result |
		result := nodes first.
		nodes second do: [:op | result := op value: result].
		result]
]

{ #category : 'expressions' }
VersePP2Grammar >> postfixOp [
	^ callOp / indexOp / memberOp / queryOp / archetypeOp
]

{ #category : 'expressions' }
VersePP2Grammar >> primaryExpr [
	^ literal / ifExpr / forExpr / loopExpr / caseExpr / setExpr / returnExpr / breakExpr / arrayExpr / mapExpr / parenExpr / blockExpr / identExpr
]

{ #category : 'expressions' }
VersePP2Grammar >> queryOp [
	^ $? asPParser trim ==> [:n | [:recv | {#query. recv}]]
]

{ #category : 'expressions' }
VersePP2Grammar >> rangeExpr [
	^ addExpr , ('.' asPParser , '.' asPParser , addExpr ==> [:n | n third]) optional
		==> [:nodes | nodes second ifNil: [nodes first] ifNotNil: [:right | {#range. nodes first. right}]]
]

{ #category : 'expressions' }
VersePP2Grammar >> returnExpr [
	^ kwReturn trim , expression ==> [:n | {#return. n second}]
]

{ #category : 'expressions' }
VersePP2Grammar >> setExpr [
	^ kwSet trim , identifier trim , setOp , expression ==> [:n | {#set. n second. n third. n fourth}]
]

{ #category : 'expressions' }
VersePP2Grammar >> setOp [
	^ '+=' asPParser trim / '-=' asPParser trim / '*=' asPParser trim / $= asPParser trim
]

{ #category : 'tokens' }
VersePP2Grammar >> skip [
	^ (whitespace / comment) star
]

{ #category : 'types' }
VersePP2Grammar >> specifier [
	^ $< asPParser trim , identifier trim , $> asPParser trim ==> [:nodes | nodes second]
]

{ #category : 'types' }
VersePP2Grammar >> specifiers [
	^ specifier star
]

{ #category : 'start' }
VersePP2Grammar >> start [
	^ skip , statements , skip ==> [:n | n second]
]

{ #category : 'statements' }
VersePP2Grammar >> statement [
	^ skip , (definition / expression) , skip ==> [:n | n second]
]

{ #category : 'statements' }
VersePP2Grammar >> statements [
	^ statement star
]

{ #category : 'expressions' }
VersePP2Grammar >> stringLit [
	^ stringLiteral trim ==> [:v | {#string. v}]
]

{ #category : 'tokens' }
VersePP2Grammar >> stringLiteral [
	^ $" asPParser , ($\ asPParser , #any asPParser / $" asPParser negate) star , $" asPParser ==> [:nodes |
		String streamContents: [:s | s nextPut: $". nodes second do: [:each | 
			each isArray ifTrue: [ s nextPut: each first; nextPut: each second ] ifFalse: [ s nextPut: each ] ]. s nextPut: $"]]
]

{ #category : 'types' }
VersePP2Grammar >> type [
	^ optionalType / arrayType / namedType
]

{ #category : 'types' }
VersePP2Grammar >> typeAnnotation [
	^ $: asPParser trim , type ==> [:nodes | nodes second]
]

{ #category : 'definitions' }
VersePP2Grammar >> typeDef [
	^ identifier trim , specifiers , ':=' asPParser trim , typeKind
	  ==> [:n | {n fourth first. n first. n second. n fourth second}]
]

{ #category : 'definitions' }
VersePP2Grammar >> typeKind [
	^ (kwClass trim , parentClause , ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#class. {n second. n fourth}}])
	 / (kwStruct trim , ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#struct. n third}])
	 / (kwEnum trim , ${ asPParser trim , (identifier trim) star , $} asPParser trim ==> [:n | {#enum. n third}])
	 / (kwInterface trim , parentClause , ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#interface. {n second. n fourth}}])
	 / (kwModule trim , ${ asPParser trim , statements , $} asPParser trim ==> [:n | {#module. n third}])
]

{ #category : 'definitions' }
VersePP2Grammar >> typedParam [
	^ $? asPParser optional trim , identifier trim , $: asPParser trim , type ==> [:n | {#param. n second. n fourth}]
]

{ #category : 'expressions' }
VersePP2Grammar >> unaryExpr [
	^ notExpr / negExpr / postfixExpr
]

{ #category : 'definitions' }
VersePP2Grammar >> usingDef [
	^ kwUsing trim , ${ asPParser trim , usingPath , $} asPParser trim
	  ==> [:n | {#using. n third}]
]

{ #category : 'definitions' }
VersePP2Grammar >> usingPath [
	^ ($/ asPParser , identifier , ($. asPParser , identifier ==> [:n | n second]) star , ($/ asPParser , identifier ==> [:n | n second]) star) flatten trim
]

{ #category : 'definitions' }
VersePP2Grammar >> varDef [
	^ kwVar trim , identifier trim , specifiers ,
	  (($: asPParser trim , type , ($= asPParser trim , expression) optional ==> [:n | {n second. n third ifNotNil: [:v | v second]}])
	   / (':=' asPParser trim , expression ==> [:n | {nil. n second}]))
	  ==> [:n | {#var. n second. n third. (n at: 4) first. (n at: 4) second}]
]

{ #category : 'definitions' }
VersePP2Grammar >> whereClause [
	^ kwWhere trim , whereConstraint , ($, asPParser trim , whereConstraint ==> [:n | n second]) star
]

{ #category : 'definitions' }
VersePP2Grammar >> whereConstraint [
	^ identifier trim , $: asPParser trim , ((kwSubtype trim , $( asPParser trim , identifier trim , $) asPParser trim) / kwType trim)
]

{ #category : 'tokens' }
VersePP2Grammar >> whitespace [
	^ (#blank asPParser / Character cr asPParser / Character lf asPParser) plus
]

{ #category : 'tokens' }
VersePP2Grammar >> ws [
	^ whitespace optional
]
