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
AngelZealCompiler class >> compileFileFromSources: zealForms file: aFilePathOrNil [
	"Compile each form, threading line numbers into the metadata so each
	 section's `zeal-lines` / `target-lines` reflect their location in the
	 final file. aFilePathOrNil, when non-nil, is added as the `file` meta
	 entry so the section is self-locating."
	| stream lineCounter |
	stream := WriteStream on: String new.
	lineCounter := 1.
	zealForms do: [:zealSrc |
		| meta target headerEndLine zealStartLine zealEndLine targetStartLine targetEndLine sectionString sectionLines |
		meta := self extractMetadataFor: zealSrc.
		aFilePathOrNil ifNotNil: [ meta at: #file put: aFilePathOrNil ].

		"Pre-compute the section so we know its target-line span."
		target := [ self compileToAngelScript: zealSrc ]
			on: Error do: [ :e | '// Compile error: ' , e messageText ].

		"Compute line ranges. Header is: 1 marker line + N metadata lines + M zeal lines + 1 end line."
		zealStartLine := lineCounter
			+ 1   "marker line"
			+ ((self orderedMetaKeys: meta) size).
		zealEndLine := zealStartLine + zealSrc lines size - 1.
		headerEndLine := zealEndLine + 1.   "@end line"
		targetStartLine := headerEndLine + 1.
		targetEndLine := targetStartLine + target lines size - 1.

		meta at: #zealLines put: (self formatLineRange: zealStartLine to: zealEndLine).
		meta at: #targetLines put: (self formatLineRange: targetStartLine to: targetEndLine).

		sectionString := (self zealHeaderFor: zealSrc metadata: meta) , target , String lf , String lf.
		stream nextPutAll: sectionString.
		sectionLines := sectionString lines size.
		lineCounter := lineCounter + sectionLines ].
	^ stream contents
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

{ #category : 'api' }
AngelZealCompiler class >> convertASChunkToZeal: aChunk [
	"Best-effort AS chunk → Zeal source. Falls back to (angel-raw ...) when
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
	^ '(angel-raw ' , (self zealStringLiteralFor: chunk) , ')'
]

{ #category : 'api' }
AngelZealCompiler class >> convertASClassToZeal: aChunk [
	"class/struct → defclass/defstruct. Class name is kebab-cased to match
	 Verse-Zeal style (`(defclass player:AActor ...)`); parent type stays
	 PascalCase since it's a type reference."
	| s headWord rest braceStart name parent body memberSources zealMembers stream header |
	s := aChunk trimBoth.
	headWord := (s beginsWith: 'class ') ifTrue: [ 'class' ] ifFalse: [ 'struct' ].
	rest := (s copyFrom: headWord size + 2 to: s size) trimBoth.
	braceStart := rest indexOf: ${ ifAbsent: [ 0 ].
	braceStart = 0 ifTrue: [ ^ '(angel-raw ' , (self zealStringLiteralFor: aChunk) , ')' ].
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

{ #category : 'api' }
AngelZealCompiler class >> convertASFunctionToZeal: aChunk [
	"Function chunk → (defn name:retType [params] (angel-raw body)).
	 Function and parameter names are kebab-cased; types kept verbatim."
	| s parenStart parenEnd braceStart braceEnd headPart paramsPart bodyPart tokens typeName name params zealParams |
	s := aChunk trimBoth.
	parenStart := s indexOf: $(.
	parenEnd := s indexOf: $) ifAbsent: [ 0 ].
	braceStart := s indexOf: ${ ifAbsent: [ 0 ].
	braceEnd := s size.
	((parenStart > 0 and: [ parenEnd > parenStart ])
		and: [ (braceStart > parenEnd) and: [ s last = $} ] ])
		ifFalse: [ ^ '(angel-raw ' , (self zealStringLiteralFor: aChunk) , ')' ].
	headPart := (s copyFrom: 1 to: parenStart - 1) trimBoth.
	paramsPart := (s copyFrom: parenStart + 1 to: parenEnd - 1) trimBoth.
	bodyPart := (s copyFrom: braceStart + 1 to: braceEnd - 1) trimBoth.
	tokens := (headPart substrings: ' ') reject: [ :t | t isEmpty ].
	tokens size < 2 ifTrue: [ ^ '(angel-raw ' , (self zealStringLiteralFor: aChunk) , ')' ].
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
		, '    (angel-raw ' , (self zealStringLiteralFor: bodyPart) , '))'
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
AngelZealCompiler class >> extractMetadataFor: zealSource [
	"Inspect zealSource (a top-level Zeal form) and return a Dictionary of
	 metadata: kind, name, returns, params. Best-effort; missing fields stay nil."
	| ast top exprs head nameNode meta name returns paramsList |
	meta := Dictionary new.
	ast := [ ZealParser parse: zealSource ] on: Error do: [ :e | nil ].
	(ast notNil and: [ ast expressions notEmpty ]) ifFalse: [ ^ meta ].
	top := ast expressions first.
	(top isKindOf: ZealListNode) ifFalse: [ ^ meta ].
	exprs := top expressions.
	exprs isEmpty ifTrue: [ ^ meta ].
	(exprs first isKindOf: ZealSymbolNode) ifFalse: [ ^ meta ].
	head := exprs first value value.
	meta at: #kind put: head.

	"Name (and return type) are usually the second element."
	exprs size >= 2 ifTrue: [
		nameNode := exprs second.
		(nameNode isKindOf: ZealColonChainNode)
			ifTrue: [
				| resolved |
				resolved := ZealColonChainResolver resolve: nameNode value value.
				name := resolved at: #name.
				returns := resolved at: #type ]
			ifFalse: [
				((nameNode isKindOf: ZealSymbolNode) and: [ nameNode value value isString ])
					ifTrue: [ name := nameNode value value ] ] ].
	name ifNotNil: [ meta at: #name put: name ].
	returns ifNotNil: [ meta at: #returns put: returns ].

	"Parameter vector for defn: the next element after the name."
	(head = 'defn' and: [ exprs size >= 3 and: [ exprs third isKindOf: ZealVectorNode ] ]) ifTrue: [
		paramsList := exprs third expressions collect: [ :p | p value value ].
		meta at: #params put: (', ' join: paramsList) ].

	"For defclass / defstruct, capture the parent type if present."
	((head = 'defclass' or: [ head = 'defstruct' ])
		and: [ nameNode isKindOf: ZealColonChainNode ])
		ifTrue: [ meta at: #parent put: returns ].

	^ meta
]

{ #category : 'api' }
AngelZealCompiler class >> formatLineRange: fromLine to: toLine [
	"`5-7` style range string used in zeal-lines / target-lines metadata."
	fromLine = toLine ifTrue: [ ^ fromLine printString ].
	^ fromLine printString , '-' , toLine printString
]

{ #category : 'api' }
AngelZealCompiler class >> metaKeyName: aSymbol [
	"camelCase symbol → kebab-case string for metadata serialization."
	| s |
	s := aSymbol asString.
	^ String streamContents: [:out |
		s do: [:ch |
			(ch isLetter and: [ ch isUppercase ])
				ifTrue: [ out nextPut: $-. out nextPut: ch asLowercase ]
				ifFalse: [ out nextPut: ch ] ] ]
]

{ #category : 'api' }
AngelZealCompiler class >> orderedMetaKeys: aMetaDict [
	"Return the metadata keys that will actually be emitted, in canonical
	 order — used by compileFileFromSources: to predict the header size."
	^ #(#kind #name #returns #params #parent #zealLines #targetLines #file)
		select: [ :k | aMetaDict includesKey: k ]
]

{ #category : 'api' }
AngelZealCompiler class >> parseSections: targetFileContent [
	"Walk a target-language file by line, grouping `// @zeal ... // @end` headers
	 with the target code that follows. Each section dict has:
	   #zealSource — verbatim Zeal source (header-stripped)
	   #targetCode — target-language code that follows the header
	   #lineStart  — 1-based line of the section's @zeal marker
	   #lineEnd    — 1-based line of the section's last target line
	   #zealLineStart, #zealLineEnd     — 1-based Zeal-source range in the file
	   #targetLineStart, #targetLineEnd — 1-based target-code range in the file
	   #metadata   — Dictionary of any `// @meta key: value` entries"
	| lines size sections i headerStart zealLines targetLines meta zealStart zealEnd targetStart targetEnd |
	lines := targetFileContent lines.
	size := lines size.
	sections := OrderedCollection new.
	i := 1.
	[ i <= size ] whileTrue: [
		((lines at: i) trimRight = self zealHeaderMarker)
			ifTrue: [
				headerStart := i.
				zealLines := OrderedCollection new.
				meta := Dictionary new.
				zealStart := nil. zealEnd := nil.
				i := i + 1.
				[ i <= size and: [ (lines at: i) trimRight ~= self zealHeaderEnd ] ] whileTrue: [
					| line |
					line := lines at: i.
					(line beginsWith: self zealMetaPrefix)
						ifTrue: [
							| body colon key val |
							body := line copyFrom: self zealMetaPrefix size + 1 to: line size.
							colon := body indexOf: $:.
							colon > 0 ifTrue: [
								key := (body copyFrom: 1 to: colon - 1) trimBoth asSymbol.
								val := (body copyFrom: colon + 1 to: body size) trimBoth.
								meta at: key put: val ] ]
						ifFalse: [
							| stripped |
							stripped := (line beginsWith: self zealCommentPrefix)
								ifTrue: [ line copyFrom: self zealCommentPrefix size + 1 to: line size ]
								ifFalse: [
									(line trimRight = '//') ifTrue: [ '' ] ifFalse: [ line ] ].
							zealStart ifNil: [ zealStart := i ].
							zealEnd := i.
							zealLines add: stripped ].
					i := i + 1 ].
				i := i + 1. "skip @end"
				targetLines := OrderedCollection new.
				targetStart := nil. targetEnd := nil.
				[ i <= size and: [ (lines at: i) trimRight ~= self zealHeaderMarker ] ] whileTrue: [
					targetStart ifNil: [ targetStart := i ].
					targetEnd := i.
					targetLines add: (lines at: i).
					i := i + 1 ].
				[ targetLines notEmpty and: [ targetLines last trimBoth isEmpty ] ]
					whileTrue: [ targetLines removeLast. targetEnd := targetEnd - 1 ].
				sections add: (Dictionary new
					at: #zealSource put: (String lf join: zealLines);
					at: #targetCode put: (String lf join: targetLines);
					at: #lineStart put: headerStart;
					at: #lineEnd put: i - 1;
					at: #zealLineStart put: (zealStart ifNil: [ headerStart + 1 ]);
					at: #zealLineEnd put: (zealEnd ifNil: [ headerStart + 1 ]);
					at: #targetLineStart put: (targetStart ifNil: [ i ]);
					at: #targetLineEnd put: (targetEnd ifNil: [ i ]);
					at: #metadata put: meta;
					yourself) ]
			ifFalse: [ i := i + 1 ] ].
	^ sections
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
AngelZealCompiler class >> zealCommentPrefix [
	"Comment prefix used per-line inside the @zeal header in AngelScript files."
	^ '// '
]

{ #category : 'api' }
AngelZealCompiler class >> zealHeaderEnd [
	^ '// @end'
]

{ #category : 'api' }
AngelZealCompiler class >> zealHeaderFor: zealSource [
	"Build the `// @zeal ... // @end` comment block embedding zealSource verbatim,
	 one source line per `// `-prefixed line."
	| stream lf |
	stream := WriteStream on: String new.
	lf := String lf.
	stream nextPutAll: self zealHeaderMarker; nextPutAll: lf.
	zealSource lines do: [:line |
		stream nextPutAll: self zealCommentPrefix; nextPutAll: line; nextPutAll: lf ].
	stream nextPutAll: self zealHeaderEnd; nextPutAll: lf.
	^ stream contents
]

{ #category : 'api' }
AngelZealCompiler class >> zealHeaderFor: zealSource metadata: aMetaDict [
	"Build a `// @zeal ... // @end` block carrying both metadata and the
	 verbatim Zeal source. Each metadata entry is a `// @meta key: value`
	 line; the source follows on `// `-prefixed lines."
	| stream lf |
	stream := WriteStream on: String new.
	lf := String lf.
	stream nextPutAll: self zealHeaderMarker; nextPutAll: lf.
	(self orderedMetaKeys: aMetaDict) do: [ :k |
		| val |
		val := aMetaDict at: k.
		stream nextPutAll: self zealMetaPrefix.
		stream nextPutAll: (self metaKeyName: k); nextPutAll: ': '.
		stream nextPutAll: (val isString ifTrue: [ val ] ifFalse: [ val printString ]).
		stream nextPutAll: lf ].
	zealSource lines do: [:line |
		stream nextPutAll: self zealCommentPrefix; nextPutAll: line; nextPutAll: lf ].
	stream nextPutAll: self zealHeaderEnd; nextPutAll: lf.
	^ stream contents
]

{ #category : 'api' }
AngelZealCompiler class >> zealHeaderMarker [
	^ '// @zeal'
]

{ #category : 'api' }
AngelZealCompiler class >> zealMetaPrefix [
	"Per-line prefix for metadata entries inside the @zeal header.
	 Lines starting with this are key:value pairs about the definition;
	 every other `// ` line in the header is part of the Zeal source."
	^ '// @meta '
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
