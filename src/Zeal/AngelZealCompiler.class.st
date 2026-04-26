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
AngelZealCompiler class >> compileFileFromSources: zealForms [
	"Take a collection of top-level Zeal source strings and emit a complete
	 .as file. Each form gets its `// @zeal` header (with metadata including
	 line ranges) + compiled code, separated by blank lines."
	^ self compileFileFromSources: zealForms file: nil
]

{ #category : 'api' }
AngelZealCompiler class >> compileSection: zealSource [
	"Compile one Zeal definition to a target-language section: rich metadata
	 + `// @zeal` Zeal-source header + compiled AngelScript. Returns the full
	 section as a string (newline-terminated)."
	| target |
	target := [ self compileToAngelScript: zealSource ]
		on: Error do: [ :e | '// Compile error: ' , e messageText ].
	^ (self zealHeaderFor: zealSource metadata: (self extractMetadataFor: zealSource))
		, target , String lf
]

{ #category : 'api' }
AngelZealCompiler class >> compileToAngelScript: aString [
	"Full pipeline: AngelZeal source string -> AngelScript source string."
	^ AngelZealCodeGenerator new generate: (ZealParser parse: aString)
]

{ #category : 'compiling' }
AngelZealCompiler class >> compileToTarget: zealSource [
	"Dialect-neutral selector that base ZealBrowser dispatches to. Aliased
	 to the AngelScript-specific entry point so naming stays clear at the
	 compiler level."
	^ self compileToAngelScript: zealSource
]

{ #category : 'conversion' }
AngelZealCompiler class >> convertASChunkToZeal: aChunk [
	"Best-effort AS chunk → Zeal source. Falls back to (source-raw ...) when
	 the shape isn't recognized."
	| chunk |
	chunk := aChunk trimBoth.
	((chunk beginsWith: 'class ') or: [ chunk beginsWith: 'struct ' ]) ifTrue: [
		^ self convertASClassToZeal: chunk ].
	(chunk endsWith: ';') ifTrue: [
		| converted |
		converted := self convertASVarToZeal: chunk.
		converted ifNotNil: [ ^ converted ] ].
	((chunk includes: $() and: [ (chunk includes: ${) and: [ chunk endsWith: '}' ] ]) ifTrue: [
		^ self convertASFunctionToZeal: chunk ].
	^ '(source-raw ' , (self zealStringLiteralFor: chunk) , ')'
]

{ #category : 'conversion' }
AngelZealCompiler class >> convertASClassToZeal: aChunk [
	"class/struct → defclass/defstruct. Class name is kebab-cased; parent
	 type stays PascalCase since it's a type reference."
	| s headWord rest braceStart name parent body memberSources zealMembers stream header |
	s := aChunk trimBoth.
	headWord := (s beginsWith: 'class ') ifTrue: [ 'class' ] ifFalse: [ 'struct' ].
	rest := (s copyFrom: headWord size + 2 to: s size) trimBoth.
	braceStart := rest indexOf: ${ ifAbsent: [ 0 ].
	braceStart = 0 ifTrue: [ ^ '(source-raw ' , (self zealStringLiteralFor: aChunk) , ')' ].
	header := (rest copyFrom: 1 to: braceStart - 1) trimBoth.
	(header includes: $:)
		ifTrue: [
			| parts |
			parts := $: split: header.
			name := self pascalToKebab: parts first trimBoth.
			parent := (parts copyFrom: 2 to: parts size) inject: '' into: [ :acc :p |
				acc isEmpty ifTrue: [ p trimBoth ] ifFalse: [ acc , ':' , p trimBoth ] ] ]
		ifFalse: [ name := self pascalToKebab: header trimBoth. parent := nil ].
	body := (rest copyFrom: braceStart + 1 to: rest size - 1) trimBoth.
	memberSources := self splitTopLevelDefs: body.
	zealMembers := memberSources collect: [ :m | self convertASChunkToZeal: m ].
	stream := WriteStream on: String new.
	stream nextPut: $(.
	stream nextPutAll: (headWord = 'class' ifTrue: [ 'defclass' ] ifFalse: [ 'defstruct' ]).
	stream nextPut: Character space.
	stream nextPutAll: name.
	parent ifNotNil: [ stream nextPut: $:. stream nextPutAll: parent ].
	zealMembers do: [ :m |
		stream nextPut: Character lf.
		stream nextPutAll: '    '.
		stream nextPutAll: m ].
	stream nextPut: $).
	^ stream contents
]

{ #category : 'conversion' }
AngelZealCompiler class >> convertASFunctionToZeal: aChunk [
	"Function chunk → (defn name:retType [params] (source-raw body)).
	 Function and parameter names are kebab-cased; types kept verbatim."
	| s parenStart parenEnd braceStart braceEnd headPart paramsPart bodyPart tokens typeName name params zealParams |
	s := aChunk trimBoth.
	parenStart := s indexOf: $(.
	parenEnd := s indexOf: $) ifAbsent: [ 0 ].
	braceStart := s indexOf: ${ ifAbsent: [ 0 ].
	braceEnd := s size.
	((parenStart > 0 and: [ parenEnd > parenStart ])
		and: [ (braceStart > parenEnd) and: [ s last = $} ] ])
		ifFalse: [ ^ '(source-raw ' , (self zealStringLiteralFor: aChunk) , ')' ].
	headPart := (s copyFrom: 1 to: parenStart - 1) trimBoth.
	paramsPart := (s copyFrom: parenStart + 1 to: parenEnd - 1) trimBoth.
	bodyPart := (s copyFrom: braceStart + 1 to: braceEnd - 1) trimBoth.
	tokens := (headPart substrings: ' ') reject: [ :t | t isEmpty ].
	tokens size < 2 ifTrue: [ ^ '(source-raw ' , (self zealStringLiteralFor: aChunk) , ')' ].
	name := self pascalToKebab: tokens last.
	typeName := ' ' join: (tokens copyFrom: 1 to: tokens size - 1).
	params := self splitTopParams: paramsPart.
	zealParams := params collect: [ :p |
		| ptokens pname ptype |
		ptokens := (p substrings: ' ') reject: [ :t | t isEmpty ].
		ptokens size >= 2
			ifTrue: [
				pname := self pascalToKebab: ptokens last.
				ptype := ' ' join: (ptokens copyFrom: 1 to: ptokens size - 1).
				pname , ':' , ptype ]
			ifFalse: [ p ] ].
	^ '(defn ' , name , ':' , typeName , ' ['
		, (' ' join: zealParams) , ']' , String lf
		, '    (source-raw ' , (self zealStringLiteralFor: bodyPart) , '))'
]

{ #category : 'api' }
AngelZealCompiler class >> convertASVarToZeal: aChunk [
	"Type Name [= value]; → (var/def name:Type [value]).
	 Name is kebab-cased; type stays verbatim."
	| s isConst typeName name value tokens body |
	s := aChunk trimBoth.
	(s endsWith: ';') ifFalse: [ ^ nil ].
	body := (s copyFrom: 1 to: s size - 1) trimBoth.
	isConst := body beginsWith: 'const '.
	isConst ifTrue: [ body := (body copyFrom: 7 to: body size) trimBoth ].
	(body includes: $=) ifTrue: [
		| eqIdx leftPart rightPart |
		eqIdx := body indexOf: $=.
		leftPart := (body copyFrom: 1 to: eqIdx - 1) trimBoth.
		rightPart := (body copyFrom: eqIdx + 1 to: body size) trimBoth.
		tokens := (leftPart substrings: ' ') reject: [ :t | t isEmpty ].
		tokens size = 2 ifFalse: [ ^ nil ].
		typeName := tokens first.
		name := self pascalToKebab: tokens second.
		value := rightPart.
		^ '(' , (isConst ifTrue: [ 'def' ] ifFalse: [ 'var' ]) , ' '
			, name , ':' , typeName , ' ' , value , ')' ].
	tokens := (body substrings: ' ') reject: [ :t | t isEmpty ].
	tokens size = 2 ifFalse: [ ^ nil ].
	typeName := tokens first.
	name := self pascalToKebab: tokens second.
	^ '(' , (isConst ifTrue: [ 'def' ] ifFalse: [ 'var' ]) , ' '
		, name , ':' , typeName , ')'
]

{ #category : 'api' }
AngelZealCompiler class >> convertFile: targetFileContent [
	"Best-effort top-level conversion of an unannotated .as file to Zeal sources.
	 Returns an OrderedCollection of Zeal source strings (one per top-level def)."
	| chunks |
	chunks := self splitTopLevelDefs: targetFileContent.
	^ chunks collect: [ :c | self convertASChunkToZeal: c ]
]

{ #category : 'api' }
AngelZealCompiler class >> pascalToKebab: aString [
	"PascalCase / camelCase → kebab-case. Inserts a `-` before each uppercase
	 letter that follows a lowercase letter or digit, then lowercases.
	 Single-word identifiers (already lowercase) pass through unchanged.
	 `MaxHp` → `max-hp`, `TakeDamage` → `take-damage`, `XValue` → `x-value`."
	| stream prevWasLower |
	stream := WriteStream on: String new.
	prevWasLower := false.
	aString do: [ :ch |
		(ch isLetter and: [ ch isUppercase ])
			ifTrue: [
				prevWasLower ifTrue: [ stream nextPut: $- ].
				stream nextPut: ch asLowercase.
				prevWasLower := false ]
			ifFalse: [
				stream nextPut: ch.
				prevWasLower := ch isLetter or: [ ch isDigit ] ] ].
	^ stream contents
]

{ #category : 'api' }
AngelZealCompiler class >> splitTopLevelDefs: aSource [
	"Walk aSource by brace depth, returning a list of top-level chunks.
	 Tracks // line comments, /* block comments, and double-quoted strings."
	| out i size depth start inString inLine inBlock advanceBy |
	out := OrderedCollection new.
	i := 1. size := aSource size. depth := 0. start := nil.
	inString := false. inLine := false. inBlock := false.
	[ i <= size ] whileTrue: [
		| ch peek |
		ch := aSource at: i.
		peek := i + 1 <= size ifTrue: [ aSource at: i + 1 ] ifFalse: [ nil ].
		advanceBy := 1.
		inLine ifTrue: [
			(ch = Character cr or: [ ch = Character lf ]) ifTrue: [ inLine := false ] ]
		ifFalse: [ inBlock ifTrue: [
			(ch = $* and: [ peek = $/ ]) ifTrue: [ inBlock := false. advanceBy := 2 ] ]
		ifFalse: [ inString ifTrue: [
			ch = $\ ifTrue: [ advanceBy := 2 ]
			ifFalse: [ ch = $" ifTrue: [ inString := false ] ] ]
		ifFalse: [
			(ch = $/ and: [ peek = $/ ]) ifTrue: [ inLine := true. advanceBy := 2 ]
			ifFalse: [
			(ch = $/ and: [ peek = $* ]) ifTrue: [ inBlock := true. advanceBy := 2 ]
			ifFalse: [
			ch = $" ifTrue: [ inString := true. start ifNil: [ start := i ] ]
			ifFalse: [
				(start isNil and: [ ch isSeparator not ]) ifTrue: [ start := i ].
				ch = ${ ifTrue: [ depth := depth + 1 ].
				ch = $} ifTrue: [
					depth := depth - 1.
					(depth = 0 and: [ start notNil ]) ifTrue: [
						out add: (aSource copyFrom: start to: i) trimBoth.
						start := nil ] ].
				(ch = $; and: [ depth = 0 and: [ start notNil ] ]) ifTrue: [
					out add: (aSource copyFrom: start to: i) trimBoth.
					start := nil ] ] ] ] ] ] ].
		i := i + advanceBy ].
	^ out
]

{ #category : 'api' }
AngelZealCompiler class >> splitTopParams: paramsString [
	"Split a comma-separated parameter list at depth 0 (so default values
	 with their own commas/parens stay attached to the param). Returns an
	 OrderedCollection of trimmed parameter strings."
	| out i size depth start ch |
	out := OrderedCollection new.
	size := paramsString size.
	size = 0 ifTrue: [ ^ out ].
	i := 1. depth := 0. start := 1.
	[ i <= size ] whileTrue: [
		ch := paramsString at: i.
		(#($( $[ ${ $<) includes: ch) ifTrue: [ depth := depth + 1 ].
		(#($) $] $} $>) includes: ch) ifTrue: [ depth := depth - 1 ].
		(ch = $, and: [ depth = 0 ]) ifTrue: [
			out add: ((paramsString copyFrom: start to: i - 1) trimBoth).
			start := i + 1 ].
		i := i + 1 ].
	out add: ((paramsString copyFrom: start to: size) trimBoth).
	^ out reject: [ :p | p isEmpty ]
]

{ #category : 'api' }
AngelZealCompiler class >> zealStringLiteralFor: aString [
	"Format aString as a Zeal double-quoted string literal, escaping backslash
	 and double-quote with a leading backslash."
	| stream |
	stream := WriteStream on: String new.
	stream nextPut: $".
	aString do: [ :ch |
		ch = $\
			ifTrue: [ stream nextPut: $\. stream nextPut: $\ ]
			ifFalse: [
				ch = $"
					ifTrue: [ stream nextPut: $\. stream nextPut: $" ]
					ifFalse: [ stream nextPut: ch ] ] ].
	stream nextPut: $".
	^ stream contents
]
