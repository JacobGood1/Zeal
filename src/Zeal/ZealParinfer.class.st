Class {
	#name : 'ZealParinfer',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'private' }
ZealParinfer class >> appendClosers: closerString toLastNonBlankIn: result [
	"Append closers to the last non-blank line in result"
	| idx |
	idx := result size.
	[ idx > 0 and: [ (result at: idx) isEmpty ] ] whileTrue: [ idx := idx - 1 ].
	idx > 0 ifTrue: [
		result at: idx put: (result at: idx) , closerString ]
]

{ #category : 'structural' }
ZealParinfer class >> barfForward: aString at: cursorPos [
	"Barf: push last expression out of the form containing cursor.
	 Same line as opener: insert closer before last expr.
	 Different line from opener: closer goes at end of line above, barfed expr aligned with opener."
	| pairs containing closer lastStart closerChar openerPos openerLine lastExprLine |
	pairs := self parenPairsIn: aString.
	
	containing := (pairs select: [:p | p key <= cursorPos and: [p value >= cursorPos]])
		sorted: [:a :b | (a value - a key) < (b value - b key)].
	containing isEmpty ifTrue: [ ^ aString ].
	
	closer := containing first value.
	openerPos := containing first key.
	closerChar := aString at: closer + 1.
	
	lastStart := self startOfExpressionBefore: closer in: aString.
	lastStart ifNil: [ ^ aString ].
	(lastStart <= (openerPos + 1)) ifTrue: [ ^ aString ].
	
	openerLine := self lineNumberAt: openerPos in: aString.
	lastExprLine := self lineNumberAt: lastStart in: aString.
	
	lastExprLine > openerLine
		ifTrue: [ ^ self barfForwardMultiline: aString closer: closer lastStart: lastStart openerPos: openerPos ]
		ifFalse: [ ^ (aString first: lastStart) trimRight , closerChar asString , ' ' , (aString copyFrom: lastStart + 1 to: closer) trimLeft , (aString allButFirst: closer + 1) ]
]

{ #category : 'structural' }
ZealParinfer class >> barfForwardMultiline: aString closer: closer lastStart: lastStart openerPos: openerPos [
	"Barf across lines: move closer to end of line before last expr, 
	 reindent barfed expr to opener's indent column."
	| closerChar openerLine openerCol lines lastExprLineNum closerLineNum |
	closerChar := aString at: closer + 1.
	openerLine := self lineNumberAt: openerPos in: aString.
	openerCol := self indentOf: (aString lines at: openerLine).
	lastExprLineNum := self lineNumberAt: lastStart in: aString.
	closerLineNum := self lineNumberAt: closer in: aString.
	
	lines := aString lines asOrderedCollection.
	
	"Step 1: Remove the closer character from the closer's line"
	closerLineNum = lastExprLineNum ifTrue: [
		"Closer is on same line as last expr — just trim trailing closer"
		| ln |
		ln := lines at: closerLineNum.
		lines at: closerLineNum put: ln trimRight allButLast ]
	ifFalse: [
		"Closer is on a different line from last expr (rare)"
		| ln |
		ln := lines at: closerLineNum.
		lines at: closerLineNum put: (ln copyReplaceAll: closerChar asString with: '') ].
	
	"Step 2: Add closer to the end of the line BEFORE the last expression"
	lines at: lastExprLineNum - 1 put: (lines at: lastExprLineNum - 1) trimRight , closerChar asString.
	
	"Step 3: Reindent the barfed expression line(s) to opener column"
	lastExprLineNum to: closerLineNum do: [:li |
		li <= lines size ifTrue: [
			lines at: li put: (String new: openerCol withAll: $ ) , (lines at: li) trimLeft ] ].
	
	^ (self lineSeparatorOf: aString) join: lines
]

{ #category : 'helpers' }
ZealParinfer class >> closerFor: anOpener [
	anOpener = $( ifTrue: [ ^ $) ].
	anOpener = $[ ifTrue: [ ^ $] ].
	anOpener = ${ ifTrue: [ ^ $} ].
	^ $)
]

{ #category : 'structural' }
ZealParinfer class >> elementsInForm: aString from: formStart to: formEnd [
	"Return elements directly inside the form"
	| elements i inStr depth eStart |
	elements := OrderedCollection new.
	i := formStart + 1. inStr := false. depth := 0. eStart := 0.
	[ i < formEnd ] whileTrue: [
		| ch skip |
		ch := aString at: i. skip := false.
		ch = $" ifTrue: [
			inStr ifFalse: [ eStart = 0 ifTrue: [ eStart := i ] ].
			inStr := inStr not.
			(inStr not and: [depth = 0]) ifTrue: [ elements add: eStart -> i. eStart := 0 ].
			skip := true ].
		(skip not and: [inStr]) ifTrue: [ skip := true ].
		(skip not and: [depth > 0]) ifTrue: [
			(#($( $[ ${) includes: ch) ifTrue: [ depth := depth + 1 ].
			(#($) $] $}) includes: ch) ifTrue: [ 
				depth := depth - 1. 
				(depth = 0 and: [eStart > 0]) ifTrue: [ elements add: eStart -> i. eStart := 0 ] ].
			skip := true ].
		(skip not and: [(#($( $[ ${) includes: ch)]) ifTrue: [
			eStart := i. depth := depth + 1. skip := true ].
		(skip not and: [ch isSeparator]) ifTrue: [
			eStart > 0 ifTrue: [ elements add: eStart -> (i - 1). eStart := 0 ]. skip := true ].
		(skip not) ifTrue: [ eStart = 0 ifTrue: [ eStart := i ] ].
		i := i + 1 ].
	(eStart > 0 and: [depth = 0]) ifTrue: [ elements add: eStart -> (formEnd - 1) ].
	^ elements
]

{ #category : 'structural' }
ZealParinfer class >> endOfExpressionAfter: pos in: aString [
	"Find end (1-based) of the next expression after 0-based pos. Skip whitespace first."
	| i ch inStr depth |
	i := pos + 1.
	
	[ i <= aString size and: [ self isWhitespace: (aString at: i) ] ] whileTrue: [ i := i + 1 ].
	i > aString size ifTrue: [ ^ nil ].
	
	ch := aString at: i.
	ch = $" ifTrue: [
		i := i + 1.
		[ i <= aString size and: [ (aString at: i) ~= $" ] ] whileTrue: [ i := i + 1 ].
		^ i ].
	(#($( $[ ${) includes: ch) ifTrue: [
		depth := 1. inStr := false. i := i + 1.
		[ i <= aString size and: [ depth > 0 ] ] whileTrue: [
			ch := aString at: i.
			ch = $" ifTrue: [ inStr := inStr not ]
			ifFalse: [ inStr ifFalse: [
				(#($( $[ ${) includes: ch) ifTrue: [ depth := depth + 1 ].
				(#($) $] $}) includes: ch) ifTrue: [ depth := depth - 1 ] ] ].
			i := i + 1 ].
		^ i - 1 ].
	[ i <= aString size and: [ 
		| c | c := aString at: i.
		((self isWhitespace: c) or: [ #($( $) $[ $] ${ $} $") includes: c ]) not
	] ] whileTrue: [ i := i + 1 ].
	^ i - 1
]

{ #category : 'structural' }
ZealParinfer class >> firstArgColumnAt: openerPos in: aString [
	"Find the column (0-based) of the first argument in a form starting at openerPos (0-based).
	 Returns the column within the opener's line."
	| openerOneBased lineStart i |
	openerOneBased := openerPos + 1.
	
	"Find start of the line containing the opener (1-based)"
	lineStart := openerOneBased.
	[ lineStart > 1 and: [ 
		| c | c := aString at: lineStart - 1.
		c ~= Character lf and: [c ~= Character cr] ] ] whileTrue: [ lineStart := lineStart - 1 ].
	
	"Scan past the opener and form name"
	i := openerOneBased + 1.
	[ i <= aString size and: [ 
		| c | c := aString at: i.
		c isLetter or: [c isDigit or: [c = $-]]
	] ] whileTrue: [ i := i + 1 ].
	[ i <= aString size and: [ (aString at: i) = $  ] ] whileTrue: [ i := i + 1 ].
	
	^ i - lineStart
]

{ #category : 'api' }
ZealParinfer class >> format: aString [
	"Reformat Zeal code: normalize indentation based on paren nesting, then run parinfer.
	 Each line indented to (nesting depth * 4). Lines starting with closers dedent first."
	| lines result depth inString indentSize |
	lines := aString lines.
	result := OrderedCollection new.
	depth := 0.
	indentSize := 4.
	
	lines do: [:line |
		| trimmed firstNonSpace adjustedDepth formatted |
		trimmed := line trimBoth.
		trimmed isEmpty ifTrue: [ result add: '' ]
		ifFalse: [
			"If line starts with a closer, dedent before writing"
			firstNonSpace := trimmed first.
			adjustedDepth := depth.
			(#($) $] $}) includes: firstNonSpace) ifTrue: [
				adjustedDepth := (depth - 1) max: 0 ].
			
			"Build reformatted line"
			formatted := (String new: adjustedDepth * indentSize withAll: $ ) , trimmed.
			result add: formatted.
			
			"Update depth by scanning the line"
			inString := false.
			1 to: trimmed size do: [:i |
				| ch |
				ch := trimmed at: i.
				ch = $" ifTrue: [ inString := inString not ]
				ifFalse: [ inString ifFalse: [
					(#($( $[ ${) includes: ch) ifTrue: [ depth := depth + 1 ].
					(#($) $] $}) includes: ch) ifTrue: [ depth := (depth - 1) max: 0 ] ] ] ] ] ].
	
	"Run parinfer on the reformatted code"
	^ self indentMode: ((self lineSeparatorOf: aString) join: result)
]

{ #category : 'api' }
ZealParinfer class >> indentMode: aString [
	"Parinfer indent mode: strip all trailing closers, re-infer from indentation.
	 Uses opener COLUMN position for closure detection (not line indent)."
	| lines result parenStack finalClosers |
	lines := aString lines.
	result := OrderedCollection new.
	parenStack := OrderedCollection new.
	
	lines do: [:line |
		| indent closers lineContent inString processed trailStart ch |
		lineContent := line trimRight.
		
		"Blank lines: preserve, don't affect paren stack"
		lineContent isEmpty ifTrue: [ result add: '' ]
		ifFalse: [
		indent := self indentOf: lineContent.
		
		"Close parens from stack whose opener column >= this line's indent"
		closers := ''.
		[ parenStack notEmpty and: [parenStack last value >= indent] ] whileTrue: [
			closers := closers , (self closerFor: parenStack removeLast key) asString ].
		closers notEmpty ifTrue: [
			self appendClosers: closers toLastNonBlankIn: result ].
		
		"Find trail start: walk backward from end, skip closers and whitespace"
		trailStart := lineContent size + 1.
		[ trailStart > 1 and: [
			| c |
			c := lineContent at: trailStart - 1.
			(#($) $] $}) includes: c) or: [c isSeparator]
		] ] whileTrue: [ trailStart := trailStart - 1 ].
		
		"Process line: strip ALL trailing closers, keep non-trailing closers"
		processed := WriteStream on: String new.
		inString := false.
		1 to: lineContent size do: [:i |
			ch := lineContent at: i.
			i >= trailStart ifTrue: [
				"Trailing region: strip closers, keep whitespace"
				(#($) $] $}) includes: ch) ifFalse: [ processed nextPut: ch ] ]
			ifFalse: [
				ch = $" ifTrue: [ inString := inString not. processed nextPut: ch ]
				ifFalse: [ inString ifTrue: [ processed nextPut: ch ]
				ifFalse: [
					(#($( $[ ${) includes: ch) ifTrue: [ 
						parenStack add: ch -> (i - 1). "Store opener COLUMN (0-based)"
						processed nextPut: ch ]
					ifFalse: [ (#($) $] $}) includes: ch) ifTrue: [
						(parenStack notEmpty and: [(self closerFor: parenStack last key) = ch])
							ifTrue: [ parenStack removeLast. processed nextPut: ch ]
							ifFalse: [ "Mismatched — drop" ] ]
					ifFalse: [ processed nextPut: ch ] ] ] ] ] ].
		
		result add: processed contents ] ].
	
	"Close any remaining open parens at end of file"
	finalClosers := ''.
	[ parenStack notEmpty ] whileTrue: [
		finalClosers := finalClosers , (self closerFor: parenStack removeLast key) asString ].
	finalClosers notEmpty ifTrue: [
		self appendClosers: finalClosers toLastNonBlankIn: result ].
	
	^ (self lineSeparatorOf: aString) join: result
]

{ #category : 'helpers' }
ZealParinfer class >> indentOf: aLine [
	| count |
	count := 0.
	aLine do: [:ch |
		ch = Character space ifTrue: [ count := count + 1 ].
		ch = Character tab ifTrue: [ count := count + 2 ].
		(ch = Character space or: [ch = Character tab]) ifFalse: [ ^ count ] ].
	^ count
]

{ #category : 'structural' }
ZealParinfer class >> isWhitespace: aChar [
	^ aChar isSeparator or: [ aChar asciiValue <= 13 ]
]

{ #category : 'structural' }
ZealParinfer class >> lineNumberAt: pos in: aString [
	"Return 1-based line number for 0-based position pos"
	| count |
	count := 1.
	1 to: (pos min: aString size) do: [:i |
		| c |
		c := aString at: i.
		(c = Character lf or: [c = Character cr]) ifTrue: [ count := count + 1 ] ].
	^ count
]

{ #category : 'private' }
ZealParinfer class >> lineSeparatorOf: aString [
	"Detect the line separator used in aString (CR, LF, or CRLF)"
	(aString includes: Character lf) ifTrue: [ ^ Character lf asString ].
	^ Character cr asString
]

{ #category : 'structural' }
ZealParinfer class >> parenPairsIn: aString [
	"Return collection of openIndex -> closeIndex (0-based) for all matched paren pairs"
	| pairs stack inString |
	pairs := OrderedCollection new.
	stack := OrderedCollection new.
	inString := false.
	0 to: aString size - 1 do: [:i |
		| ch |
		ch := aString at: i + 1.
		ch = $" ifTrue: [ inString := inString not ]
		ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
			(#($) $] $}) includes: ch) ifTrue: [
				stack notEmpty ifTrue: [ pairs add: stack removeLast -> i ] ] ] ] ].
	^ pairs
]

{ #category : 'structural' }
ZealParinfer class >> reindentLine: lineNum to: targetCol in: aString [
	"Set the indent of 1-based lineNum to targetCol spaces"
	| lines separator |
	lines := aString lines asOrderedCollection.
	(lineNum < 1 or: [lineNum > lines size]) ifTrue: [ ^ aString ].
	lines at: lineNum put: (String new: targetCol withAll: $ ) , (lines at: lineNum) trimLeft.
	"Detect line separator used in the string"
	separator := (aString includes: Character lf) ifTrue: [ Character lf asString ] ifFalse: [ Character cr asString ].
	^ separator join: lines
]

{ #category : 'structural' }
ZealParinfer class >> siblingFormsAt: cursorPos in: aString [
	"Find sibling forms at the same nesting level as the cursor"
	| stack inString pairs innermost parentOpen parentClose siblings depth formStart |
	pairs := OrderedCollection new.
	stack := OrderedCollection new.
	inString := false.
	1 to: aString size do: [:i |
		| ch |
		ch := aString at: i.
		ch = $" ifTrue: [ inString := inString not ]
		ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
			(#($) $] $}) includes: ch) ifTrue: [
				stack notEmpty ifTrue: [ pairs add: stack removeLast -> i ] ] ] ] ].
	
	innermost := nil.
	pairs do: [:pair |
		(pair key <= cursorPos and: [pair value >= cursorPos]) ifTrue: [
			(innermost isNil or: [(pair value - pair key) < (innermost value - innermost key)])
				ifTrue: [ innermost := pair ] ] ].
	innermost ifNil: [ ^ self topLevelForms: aString ].
	
	parentOpen := nil. parentClose := nil.
	pairs do: [:pair |
		(pair key < innermost key and: [pair value > innermost value]) ifTrue: [
			(parentOpen isNil or: [(pair value - pair key) < (parentClose - parentOpen)])
				ifTrue: [ parentOpen := pair key. parentClose := pair value ] ] ].
	parentOpen ifNil: [ ^ self topLevelForms: aString ].
	
	siblings := OrderedCollection new.
	depth := 0. formStart := 0. inString := false.
	parentOpen + 1 to: parentClose - 1 do: [:i |
		| ch |
		ch := aString at: i.
		ch = $" ifTrue: [ inString := inString not ]
		ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [
				depth = 0 ifTrue: [ formStart := i ].
				depth := depth + 1 ].
			(#($) $] $}) includes: ch) ifTrue: [
				depth := depth - 1.
				depth = 0 ifTrue: [ siblings add: formStart -> i ] ] ] ] ].
	^ siblings
]

{ #category : 'structural' }
ZealParinfer class >> slurpForward: aString at: cursorPos [
	"Slurp: pull next expression into the form containing cursor.
	 When slurping across lines, indent the slurped expression to align with first arg."
	| pairs containing closer nextEnd closerChar openerPos result closerLine nextExprLine targetCol |
	pairs := self parenPairsIn: aString.
	
	containing := (pairs select: [:p | p key <= cursorPos and: [p value >= cursorPos]])
		sorted: [:a :b | (a value - a key) < (b value - b key)].
	containing isEmpty ifTrue: [ ^ aString ].
	
	closer := containing first value.
	openerPos := containing first key.
	closerChar := aString at: closer + 1.
	
	nextEnd := self endOfExpressionAfter: closer + 1 in: aString.
	nextEnd ifNil: [ ^ aString ].
	
	result := (aString first: closer) , (aString copyFrom: closer + 2 to: nextEnd) , closerChar asString , (aString allButFirst: nextEnd).
	
	closerLine := self lineNumberAt: closer in: aString.
	nextExprLine := self lineNumberAt: closer + 2 in: aString.
	nextExprLine > closerLine ifTrue: [
		targetCol := self firstArgColumnAt: openerPos in: aString.
		result := self reindentLine: nextExprLine to: targetCol in: result ].
	
	^ result
]

{ #category : 'api' }
ZealParinfer class >> smartIndentColumn: aString forLine: lineIndex [
	"Calculate the target indent column for lineIndex (1-based) based on
	 the last unclosed opener from lines above. Trailing closers are ignored
	 (parinfer will strip them). Returns a 0-based column number."
	| lines parenStack inString |
	lines := aString lines.
	parenStack := OrderedCollection new. "Each entry: column (0-based)"
	inString := false.
	
	1 to: (lineIndex - 1 min: lines size) do: [:li |
		| line trailStart |
		line := (lines at: li) trimRight.
		
		"Find trailing closer boundary (same logic as indentMode:)"
		trailStart := line size + 1.
		[ trailStart > 1 and: [
			| c |
			c := line at: trailStart - 1.
			(#($) $] $}) includes: c) or: [c isSeparator]
		] ] whileTrue: [ trailStart := trailStart - 1 ].
		
		"Process chars, ignoring trailing closers"
		inString := false.
		1 to: line size do: [:ci |
			| ch |
			ch := line at: ci.
			ch = $" ifTrue: [ inString := inString not ]
			ifFalse: [ inString ifFalse: [
				ci < trailStart ifTrue: [
					(#($( $[ ${) includes: ch) ifTrue: [ parenStack add: (ci - 1) "0-based col" ]
					ifFalse: [ (#($) $] $}) includes: ch) ifTrue: [
						parenStack notEmpty ifTrue: [ parenStack removeLast ] ] ] ] ] ] ] ].
	
	^ parenStack notEmpty
		ifTrue: [ parenStack last + 1 ]
		ifFalse: [ 0 ]
]

{ #category : 'structural' }
ZealParinfer class >> startOfExpressionBefore: pos in: aString [
	"Find start (0-based) of the expression before 0-based pos. Skip whitespace backward."
	| i ch inStr depth |
	i := pos.
	[ i > 0 and: [ self isWhitespace: (aString at: i) ] ] whileTrue: [ i := i - 1 ].
	i <= 0 ifTrue: [ ^ nil ].
	
	ch := aString at: i.
	ch = $" ifTrue: [
		i := i - 1.
		[ i > 0 and: [ (aString at: i) ~= $" ] ] whileTrue: [ i := i - 1 ].
		^ i - 1 ].
	(#($) $] $}) includes: ch) ifTrue: [
		depth := 1. inStr := false. i := i - 1.
		[ i > 0 and: [ depth > 0 ] ] whileTrue: [
			ch := aString at: i.
			ch = $" ifTrue: [ inStr := inStr not ]
			ifFalse: [ inStr ifFalse: [
				(#($) $] $}) includes: ch) ifTrue: [ depth := depth + 1 ].
				(#($( $[ ${) includes: ch) ifTrue: [ depth := depth - 1 ] ] ].
			i := i - 1 ].
		^ i ].
	[ i > 0 and: [
		| c | c := aString at: i.
		((self isWhitespace: c) or: [ #($( $) $[ $] ${ $} $") includes: c ]) not
	] ] whileTrue: [ i := i - 1 ].
	^ i
]

{ #category : 'helpers' }
ZealParinfer class >> stripTrailingClosers: aLine [
	"Remove trailing ), ], } from end of line (outside strings)"
	| i inString |
	aLine isEmpty ifTrue: [ ^ aLine ].
	"Find the last non-closer position"
	i := aLine size.
	[ i > 0 and: [#($) $] $}) includes: (aLine at: i)] ] whileTrue: [ i := i - 1 ].
	"But verify these closers are not inside a string"
	inString := false.
	1 to: i do: [:j | (aLine at: j) = $" ifTrue: [ inString := inString not ] ].
	inString ifTrue: [ ^ aLine ]. "closers are inside a string, keep them"
	^ aLine copyFrom: 1 to: i
]

{ #category : 'api' }
ZealParinfer class >> structuralRangesAt: cursorPos in: aString [
	"Return selection ranges expanding outward from cursorPos.
	 Ranges: word, string contents, full string, inner form, outer form, ..., whole file."
	| ranges parenPairs stack inString wordStart wordEnd containingPairs stringRanges strStart delimiters |
	ranges := OrderedCollection new.
	delimiters := #($( $) $[ $] ${ $} $").
	
	"1. Find all matching paren pairs and string ranges"
	parenPairs := OrderedCollection new.
	stringRanges := OrderedCollection new.
	stack := OrderedCollection new.
	inString := false.
	strStart := 0.
	0 to: aString size - 1 do: [:i |
		| ch |
		ch := aString at: i + 1.
		ch = $" ifTrue: [
			inString
				ifTrue: [ stringRanges add: strStart -> i. inString := false ]
				ifFalse: [ strStart := i. inString := true ] ]
		ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
			(#($) $] $}) includes: ch) ifTrue: [
				stack notEmpty ifTrue: [ parenPairs add: stack removeLast -> i ] ] ] ] ].
	
	"2. Find word at cursor (delimited by whitespace, parens, and quotes)"
	wordStart := cursorPos.
	wordEnd := cursorPos.
	[ wordStart > 0 and: [ 
		| c | c := aString at: wordStart.
		(c isSeparator or: [ delimiters includes: c ]) not
	] ] whileTrue: [ wordStart := wordStart - 1 ].
	[ wordEnd < aString size and: [
		| c | c := aString at: wordEnd + 1.
		(c isSeparator or: [ delimiters includes: c ]) not
	] ] whileTrue: [ wordEnd := wordEnd + 1 ].
	(wordEnd > wordStart) ifTrue: [ ranges add: wordStart -> wordEnd ].
	
	"3. Find containing string (if cursor is inside one)"
	stringRanges do: [:sr |
		(sr key <= cursorPos and: [ sr value >= cursorPos ]) ifTrue: [
			| innerStart innerEnd outerStart outerEnd |
			innerStart := sr key + 1.
			innerEnd := sr value.
			outerStart := sr key.
			outerEnd := sr value + 1.
			"String contents (between quotes)"
			(ranges isEmpty or: [ (innerEnd - innerStart) > (ranges last value - ranges last key) ])
				ifTrue: [ ranges add: innerStart -> innerEnd ].
			"Full string (including quotes)"
			(ranges isEmpty or: [ (outerEnd - outerStart) > (ranges last value - ranges last key) ])
				ifTrue: [ ranges add: outerStart -> outerEnd ] ] ].
	
	"4. Find containing paren pairs, innermost to outermost"
	containingPairs := (parenPairs select: [:pair | 
		pair key <= cursorPos and: [ pair value >= cursorPos ] ])
		sorted: [:a :b | (a value - a key) < (b value - b key)].
	
	containingPairs do: [:pair |
		| innerStart innerEnd outerStart outerEnd |
		innerStart := pair key + 1.
		innerEnd := pair value.
		outerStart := pair key.
		outerEnd := pair value + 1.
		(ranges isEmpty or: [ (innerEnd - innerStart) > (ranges last value - ranges last key) ])
			ifTrue: [ ranges add: innerStart -> innerEnd ].
		(ranges isEmpty or: [ (outerEnd - outerStart) > (ranges last value - ranges last key) ])
			ifTrue: [ ranges add: outerStart -> outerEnd ] ].
	
	"5. Whole file as final range"
	(ranges isEmpty or: [ ranges last ~= (0 -> aString size) ])
		ifTrue: [ ranges add: 0 -> aString size ].
	
	^ ranges
]

{ #category : 'structural' }
ZealParinfer class >> swapFormDown: aString at: cursorPos [
	"Swap the element at cursor with the one after it"
	| stack inString pairs innermost elements currentIdx current below belowText currentText beforeCurrent betweenText afterBelow |
	pairs := OrderedCollection new. stack := OrderedCollection new. inString := false.
	1 to: aString size do: [:i | | ch | ch := aString at: i.
		ch = $" ifTrue: [ inString := inString not ] ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
			(#($) $] $}) includes: ch) ifTrue: [ stack notEmpty ifTrue: [ pairs add: stack removeLast -> i ] ] ] ] ].
	innermost := nil.
	pairs do: [:pair | (pair key < cursorPos and: [pair value > cursorPos]) ifTrue: [
		(innermost isNil or: [(pair value - pair key) < (innermost value - innermost key)]) ifTrue: [ innermost := pair ] ] ].
	innermost ifNil: [ ^ aString ].
	elements := self elementsInForm: aString from: innermost key to: innermost value.
	elements size < 2 ifTrue: [ ^ aString ].
	currentIdx := 0.
	elements doWithIndex: [:e :idx | (e key <= cursorPos and: [e value >= cursorPos]) ifTrue: [ currentIdx := idx ] ].
	(currentIdx = 0 or: [currentIdx >= elements size]) ifTrue: [ ^ aString ].
	current := elements at: currentIdx. below := elements at: currentIdx + 1.
	belowText := aString copyFrom: below key to: below value.
	currentText := aString copyFrom: current key to: current value.
	beforeCurrent := aString copyFrom: 1 to: current key - 1.
	betweenText := aString copyFrom: current value + 1 to: below key - 1.
	afterBelow := aString allButFirst: below value.
	^ beforeCurrent , belowText , betweenText , currentText , afterBelow
]

{ #category : 'structural' }
ZealParinfer class >> swapFormUp: aString at: cursorPos [
	"Swap the element at cursor with the one before it"
	| stack inString pairs innermost elements currentIdx current above aboveText currentText beforeAbove betweenText afterCurrent |
	pairs := OrderedCollection new. stack := OrderedCollection new. inString := false.
	1 to: aString size do: [:i | | ch | ch := aString at: i.
		ch = $" ifTrue: [ inString := inString not ] ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ stack add: i ].
			(#($) $] $}) includes: ch) ifTrue: [ stack notEmpty ifTrue: [ pairs add: stack removeLast -> i ] ] ] ] ].
	innermost := nil.
	pairs do: [:pair | (pair key < cursorPos and: [pair value > cursorPos]) ifTrue: [
		(innermost isNil or: [(pair value - pair key) < (innermost value - innermost key)]) ifTrue: [ innermost := pair ] ] ].
	innermost ifNil: [ ^ aString ].
	elements := self elementsInForm: aString from: innermost key to: innermost value.
	elements size < 2 ifTrue: [ ^ aString ].
	currentIdx := 0.
	elements doWithIndex: [:e :idx | (e key <= cursorPos and: [e value >= cursorPos]) ifTrue: [ currentIdx := idx ] ].
	currentIdx <= 1 ifTrue: [ ^ aString ].
	current := elements at: currentIdx. above := elements at: currentIdx - 1.
	aboveText := aString copyFrom: above key to: above value.
	currentText := aString copyFrom: current key to: current value.
	beforeAbove := aString copyFrom: 1 to: above key - 1.
	betweenText := aString copyFrom: above value + 1 to: current key - 1.
	afterCurrent := aString allButFirst: current value.
	^ beforeAbove , currentText , betweenText , aboveText , afterCurrent
]

{ #category : 'structural' }
ZealParinfer class >> topLevelForms: aString [
	"Return ordered collection of start->end (1-based) for each top-level form"
	| forms depth inString formStart |
	forms := OrderedCollection new.
	depth := 0. inString := false. formStart := 0.
	1 to: aString size do: [:i |
		| ch |
		ch := aString at: i.
		ch = $" ifTrue: [ inString := inString not ]
		ifFalse: [ inString ifFalse: [
			(#($( $[ ${) includes: ch) ifTrue: [ 
				depth = 0 ifTrue: [ formStart := i ].
				depth := depth + 1 ].
			(#($) $] $}) includes: ch) ifTrue: [
				depth := depth - 1.
				depth = 0 ifTrue: [ forms add: formStart -> i ] ] ] ] ].
	^ forms
]
