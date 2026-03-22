Class {
	#name : 'VersePreprocessor',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'helpers' }
VersePreprocessor class >> indentOf: aLine [
	"Count leading spaces (tabs = 4 spaces)."
	| count |
	count := 0.
	aLine do: [:ch |
		ch = Character space ifTrue: [ count := count + 1 ].
		ch = Character tab ifTrue: [ count := count + 4 ].
		(ch = Character space or: [ ch = Character tab ]) ifFalse: [ ^ count ] ].
	^ count
]

{ #category : 'helpers' }
VersePreprocessor class >> indentString: level [
	^ String new: level withAll: Character space
]

{ #category : 'helpers' }
VersePreprocessor class >> nextNonEmptyIndent: lines from: startIndex [
	"Find the indentation of the next non-empty, non-comment line."
	startIndex to: lines size do: [:i |
		| line stripped |
		line := lines at: i.
		stripped := line trimBoth.
		(stripped notEmpty and: [ (stripped beginsWith: '#') not ])
			ifTrue: [ ^ self indentOf: line ] ].
	^ 0
]

{ #category : 'processing' }
VersePreprocessor class >> process: aString [
	"Convert colon-block indentation syntax to brace-block syntax. Normalizes line endings to LF."
	| cleaned normalized lines result indentStack i lf |
	lf := String with: Character lf.
	normalized := aString copyReplaceAll: (String with: Character cr with: Character lf) with: lf.
	normalized := normalized copyReplaceAll: (String with: Character cr) with: lf.
	cleaned := self stripComments: normalized.
	lines := cleaned lines.
	result := OrderedCollection new.
	indentStack := OrderedCollection new.
	indentStack add: {0. 0}.
	
	i := 1.
	[ i <= lines size ] whileTrue: [
		| line stripped indent |
		line := lines at: i.
		stripped := line trimBoth.
		
		stripped isEmpty
			ifTrue: [ result add: ''. i := i + 1 ]
			ifFalse: [
				indent := self indentOf: line.
				[ indentStack last second > indent and: [ indentStack size > 1 ] ] whileTrue: [
					| closed |
					closed := indentStack removeLast.
					result add: (self indentString: closed first) , '}'.
					result add: '' ].
				(stripped size > 1 and: [ (stripped last = $:) and: [ (stripped endsWith: ':=') not ] ])
					ifTrue: [
						| nextIndent |
						nextIndent := (i < lines size) ifTrue: [ self nextNonEmptyIndent: lines from: i + 1 ] ifFalse: [ 0 ].
						nextIndent > indent 
							ifTrue: [ result add: (line trimRight allButLast , ' {').
								indentStack add: {indent. nextIndent} ]
							ifFalse: [ result add: (line trimRight allButLast , ' {}') ] ]
				ifFalse: [ (stripped last = $= and: [ i < lines size ]) ifTrue: [
						| nextIndent |
						nextIndent := self nextNonEmptyIndent: lines from: i + 1.
						nextIndent > indent
							ifTrue: [ result add: line , ' {'.
								indentStack add: {indent. nextIndent} ]
							ifFalse: [ result add: line ] ]
				ifFalse: [ result add: line ] ].
				i := i + 1 ] ].
	
	[ indentStack size > 1 ] whileTrue: [
		| closed |
		closed := indentStack removeLast.
		result add: (self indentString: closed first) , '}'.
		result add: '' ].
	
	^ lf join: result
]

{ #category : 'processing' }
VersePreprocessor class >> stripComments: aString [
	"Remove # comments but preserve # inside strings. Uses LF line endings."
	| lf |
	lf := String with: Character lf.
	^ lf join: (aString lines collect: [:line |
		| result inString i |
		result := WriteStream on: String new.
		inString := false.
		i := 1.
		[ i <= line size ] whileTrue: [
			| ch |
			ch := line at: i.
			ch = $" ifTrue: [ 
				inString := inString not.
				result nextPut: ch ]
			ifFalse: [ ch = $\ ifTrue: [
				result nextPut: ch.
				i := i + 1.
				i <= line size ifTrue: [ result nextPut: (line at: i) ] ]
			ifFalse: [ (ch = $# and: [ inString not ]) ifTrue: [
				i := line size ]
			ifFalse: [
				result nextPut: ch ] ] ].
			i := i + 1 ].
		result contents trimRight ])
]
