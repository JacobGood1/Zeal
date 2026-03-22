Class {
	#name : 'VerseScanner',
	#superclass : 'SmaCCScanner',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated-initialization' }
VerseScanner class >> initializeKeywordMap [
	keywordMap := Dictionary new.
	#(#(32 'and' 22) #(32 'array' 26) #(32 'break' 14) #(32 'class' 15) #(32 'else' 10) #(32 'enum' 17) #(32 'false' 25) #(32 'for' 11) #(32 'if' 9) #(32 'interface' 18) #(32 'loop' 12) #(32 'map' 27) #(32 'module' 19) #(32 'not' 21) #(32 'or' 23) #(32 'return' 13) #(32 'set' 8) #(32 'struct' 16) #(32 'subtype' 30) #(32 'true' 24) #(32 'type' 29) #(32 'using' 20) #(32 'var' 7) #(32 'where' 28))
		do: [ :each | 
			(keywordMap at: each first ifAbsentPut: [ Dictionary new ])
				at: (each at: 2)
				put: each last ].
	^ keywordMap
]

{ #category : 'generated' }
VerseScanner >> emptySymbolTokenId [
	^ 102
]

{ #category : 'generated' }
VerseScanner >> errorTokenId [
	^ 103
]

{ #category : 'generated' }
VerseScanner >> scan1 [
	[ self step.
	currentCharacter == $" ifTrue: [ ^ self recordAndReportMatch: #(5) ].
	currentCharacter == $\
		ifTrue: [ self step.
			^ self scan1 ].
	true ] whileTrue
]

{ #category : 'generated' }
VerseScanner >> scan2 [
	[ self recordMatch: #(3).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan3 ].
	currentCharacter isDigit ] whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scan3 [
	self step.
	currentCharacter isDigit
		ifTrue: [ [ self recordMatch: #(2).
			self step.
			currentCharacter isDigit ] whileTrue.
			('Ee' includes: currentCharacter)
				ifTrue: [ self step.
					currentCharacter isDigit
						ifTrue: [ [ self recordMatch: #(2).
							self step.
							currentCharacter isDigit ] whileTrue.
							^ self reportLastMatch ].
					('+-' includes: currentCharacter)
						ifTrue: [ self step.
							currentCharacter isDigit
								ifTrue: [ [ self recordMatch: #(2).
									self step.
									currentCharacter isDigit ] whileTrue ] ] ] ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForToken [
	self step.
	currentCharacter == $" ifTrue: [ ^ self scan1 ].
	currentCharacter == $' ifTrue: [ ^ self scanForTokenX11 ].
	currentCharacter == $( ifTrue: [ ^ self recordAndReportMatch: #(41) ].
	^ self scanForTokenX13
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX1 [
	self recordMatch: #(3).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan3 ].
	currentCharacter == $x
		ifTrue: [ self step.
			(currentCharacter isDigit
				or: [ (currentCharacter between: $A and: $F)
						or: [ currentCharacter between: $a and: $f ] ])
				ifTrue: [ [ self recordMatch: #(4).
					self step.
					currentCharacter isDigit
						or: [ (currentCharacter between: $A and: $F)
								or: [ currentCharacter between: $a and: $f ] ] ] whileTrue ].
			^ self reportLastMatch ].
	currentCharacter isDigit ifTrue: [ ^ self scan2 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX10 [
	self recordMatch: #(53).
	self step.
	currentCharacter == $= ifTrue: [ ^ self recordAndReportMatch: #(39) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX11 [
	self step.
	currentCharacter ~~ $'
		ifTrue: [ self step.
			currentCharacter == $' ifTrue: [ ^ self recordAndReportMatch: #(6) ] ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX12 [
	currentCharacter == $? ifTrue: [ ^ self recordAndReportMatch: #(57) ].
	currentCharacter == $@ ifTrue: [ ^ self recordAndReportMatch: #(31) ].
	currentCharacter == $[ ifTrue: [ ^ self recordAndReportMatch: #(43) ].
	currentCharacter == $] ifTrue: [ ^ self recordAndReportMatch: #(44) ].
	currentCharacter == ${ ifTrue: [ ^ self recordAndReportMatch: #(45) ].
	currentCharacter == $} ifTrue: [ ^ self recordAndReportMatch: #(46) ].
	currentCharacter isDigit ifTrue: [ ^ self scan2 ].
	(currentCharacter isSeparator or: [ currentCharacter == Character pageUp ])
		ifTrue: [ ^ self scanForTokenX5 ].
	((currentCharacter between: $A and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ self scanForTokenX2 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX13 [
	currentCharacter == $) ifTrue: [ ^ self recordAndReportMatch: #(42) ].
	currentCharacter == $* ifTrue: [ ^ self recordAndReportMatch: #(55) ].
	currentCharacter == $+ ifTrue: [ ^ self scanForTokenX10 ].
	currentCharacter == $, ifTrue: [ ^ self recordAndReportMatch: #(50) ].
	currentCharacter == $- ifTrue: [ ^ self scanForTokenX4 ].
	currentCharacter == $. ifTrue: [ ^ self scanForTokenX9 ].
	currentCharacter == $/ ifTrue: [ ^ self recordAndReportMatch: #(56) ].
	currentCharacter == $0 ifTrue: [ ^ self scanForTokenX1 ].
	currentCharacter == $: ifTrue: [ ^ self scanForTokenX8 ].
	currentCharacter == $< ifTrue: [ ^ self scanForTokenX3 ].
	currentCharacter == $= ifTrue: [ ^ self scanForTokenX7 ].
	currentCharacter == $> ifTrue: [ ^ self scanForTokenX6 ].
	^ self scanForTokenX12
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX2 [
	[ self recordMatch: #(32).
	self step.
	(currentCharacter between: $0 and: $9)
		or: [ (currentCharacter between: $A and: $Z)
				or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ]
		whileTrue
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX3 [
	self recordMatch: #(47).
	self step.
	currentCharacter == $= ifTrue: [ ^ self recordAndReportMatch: #(36) ].
	currentCharacter == $> ifTrue: [ ^ self recordAndReportMatch: #(38) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX4 [
	self recordMatch: #(54).
	self step.
	currentCharacter == $= ifTrue: [ ^ self recordAndReportMatch: #(40) ].
	currentCharacter isDigit ifTrue: [ ^ self scan2 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX5 [
	[ self recordMatch: #(1).
	self step.
	currentCharacter isSeparator or: [ currentCharacter == Character pageUp ] ]
		whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX6 [
	self recordMatch: #(48).
	self step.
	currentCharacter == $= ifTrue: [ ^ self recordAndReportMatch: #(37) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX7 [
	self recordMatch: #(52).
	self step.
	currentCharacter == $> ifTrue: [ ^ self recordAndReportMatch: #(34) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX8 [
	self recordMatch: #(49).
	self step.
	currentCharacter == $= ifTrue: [ ^ self recordAndReportMatch: #(33) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> scanForTokenX9 [
	self recordMatch: #(51).
	self step.
	currentCharacter == $. ifTrue: [ ^ self recordAndReportMatch: #(35) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
VerseScanner >> tokenActions [
	^ #(#whitespace)
]
