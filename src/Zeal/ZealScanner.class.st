Class {
	#name : 'ZealScanner',
	#superclass : 'SmaCCScanner',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealScanner >> emptySymbolTokenId [
	^ 28
]

{ #category : 'generated' }
ZealScanner >> errorTokenId [
	^ 29
]

{ #category : 'generated' }
ZealScanner >> scan1 [
	[ self step.
	currentCharacter == $" ifTrue: [ ^ self recordAndReportMatch: #(6) ].
	currentCharacter == $\
		ifTrue: [ self step.
			^ self scan1 ].
	true ] whileTrue
]

{ #category : 'generated' }
ZealScanner >> scan10 [
	self step.
	currentCharacter == $[
		ifTrue: [ self step.
			currentCharacter == $]
				ifTrue: [ self step.
					((currentCharacter between: $A and: $Z)
						or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
						ifTrue: [ ^ self scan11 ] ].
			^ self reportLastMatch ].
	((currentCharacter between: $? and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ ^ self scan11 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan11 [
	[ self recordMatch: #(9).
	self step.
	currentCharacter == $: ifTrue: [ ^ self scan10 ].
	currentCharacter == $-
		or: [ (currentCharacter between: $0 and: $9)
				or: [ currentCharacter == $?
						or: [ (currentCharacter between: $A and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
		whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan2 [
	self step.
	currentCharacter == $' ifTrue: [ ^ self recordAndReportMatch: #(7) ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan3 [
	self recordMatch: #(10).
	self step.
	currentCharacter isDigit ifTrue: [ ^ self scan4 ].
	(('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(10).
			self step.
			('!#&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan4 [
	[ self recordMatch: #(4 10).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan5 ].
	currentCharacter isDigit ] whileTrue.
	(('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(10).
			self step.
			('!#&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan5 [
	self recordMatch: #(10).
	self step.
	currentCharacter isDigit ifTrue: [ ^ self scan6 ].
	(('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(10).
			self step.
			('!#&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan6 [
	[ self recordMatch: #(3 10).
	self step.
	currentCharacter isDigit ] whileTrue.
	('Ee' includes: currentCharacter)
		ifTrue: [ self recordMatch: #(10).
			self step.
			currentCharacter isDigit ifTrue: [ ^ self scan7 ].
			('+-' includes: currentCharacter)
				ifTrue: [ self recordMatch: #(10).
					self step.
					currentCharacter isDigit ifTrue: [ ^ self scan7 ].
					(('!#&' includes: currentCharacter)
						or: [ (currentCharacter between: $* and: $+)
								or: [ (currentCharacter between: $- and: $/)
										or: [ (currentCharacter between: $< and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
						ifTrue: [ [ self recordMatch: #(10).
							self step.
							('!#&' includes: currentCharacter)
								or: [ (currentCharacter between: $* and: $+)
										or: [ (currentCharacter between: $- and: $9)
												or: [ (currentCharacter between: $< and: $Z)
														or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
								whileTrue ].
					^ self reportLastMatch ].
			(('!#&*' includes: currentCharacter)
				or: [ (currentCharacter between: $. and: $/)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ])
				ifTrue: [ [ self recordMatch: #(10).
					self step.
					('!#&' includes: currentCharacter)
						or: [ (currentCharacter between: $* and: $+)
								or: [ (currentCharacter between: $- and: $9)
										or: [ (currentCharacter between: $< and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
						whileTrue ].
			^ self reportLastMatch ].
	(('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(10).
			self step.
			('!#&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan7 [
	[ self recordMatch: #(3 10).
	self step.
	currentCharacter isDigit ] whileTrue.
	(('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(10).
			self step.
			('!#&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan8 [
	self step.
	currentCharacter == $.
		ifTrue: [ self step.
			currentCharacter isDigit
				ifTrue: [ [ self recordMatch: #(8).
					self step.
					currentCharacter isDigit ] whileTrue ].
			^ self reportLastMatch ].
	currentCharacter isDigit
		ifTrue: [ [ self recordMatch: #(3).
			self step.
			currentCharacter isDigit ] whileTrue.
			('Ee' includes: currentCharacter)
				ifTrue: [ self step.
					currentCharacter isDigit
						ifTrue: [ [ self recordMatch: #(3).
							self step.
							currentCharacter isDigit ] whileTrue.
							^ self reportLastMatch ].
					('+-' includes: currentCharacter)
						ifTrue: [ self step.
							currentCharacter isDigit
								ifTrue: [ [ self recordMatch: #(3).
									self step.
									currentCharacter isDigit ] whileTrue ] ] ] ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan9 [
	[ self recordMatch: #(4).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan8 ].
	currentCharacter isDigit ] whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForToken [
	self step.
	currentCharacter == $" ifTrue: [ ^ self scan1 ].
	currentCharacter == $' ifTrue: [ ^ self scanForTokenX6 ].
	currentCharacter == $( ifTrue: [ ^ self recordAndReportMatch: #(12) ].
	currentCharacter == $) ifTrue: [ ^ self recordAndReportMatch: #(13) ].
	currentCharacter == $- ifTrue: [ ^ self scan3 ].
	currentCharacter == $0 ifTrue: [ ^ self scanForTokenX2 ].
	currentCharacter == $: ifTrue: [ ^ self scanForTokenX4 ].
	currentCharacter == $; ifTrue: [ ^ self scanForTokenX5 ].
	currentCharacter == $[ ifTrue: [ ^ self recordAndReportMatch: #(14) ].
	currentCharacter == $] ifTrue: [ ^ self recordAndReportMatch: #(15) ].
	^ self scanForTokenX8
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX1 [
	[ self recordMatch: #(10).
	self step.
	currentCharacter == $: ifTrue: [ ^ self scan10 ].
	currentCharacter == $-
		or: [ (currentCharacter between: $0 and: $9)
				or: [ (currentCharacter between: $A and: $Z)
						or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ]
		whileTrue.
	(('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $. and: $/)
						or: [ currentCharacter between: $< and: $@ ] ] ])
		ifTrue: [ [ self recordMatch: #(10).
			self step.
			('!#&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX2 [
	self recordMatch: #(4).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan8 ].
	currentCharacter == $x
		ifTrue: [ self step.
			(currentCharacter isDigit
				or: [ (currentCharacter between: $A and: $F)
						or: [ currentCharacter between: $a and: $f ] ])
				ifTrue: [ [ self recordMatch: #(5).
					self step.
					currentCharacter isDigit
						or: [ (currentCharacter between: $A and: $F)
								or: [ currentCharacter between: $a and: $f ] ] ] whileTrue ].
			^ self reportLastMatch ].
	currentCharacter isDigit ifTrue: [ ^ self scan9 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX3 [
	[ self recordMatch: #(10).
	self step.
	('!#&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $9)
						or: [ (currentCharacter between: $< and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
		whileTrue
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX4 [
	self step.
	((currentCharacter between: $A and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ [ self recordMatch: #(11).
			self step.
			currentCharacter == $-
				or: [ (currentCharacter between: $0 and: $9)
						or: [ (currentCharacter between: $A and: $Z)
								or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX5 [
	[ self recordMatch: #(2).
	self step.
	currentCharacter <= Character tab
		or: [ (currentCharacter between: Character pageUp and: Character newPage)
				or: [ currentCharacter >= (Character value: 14) ] ] ] whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX6 [
	self step.
	currentCharacter == $\
		ifTrue: [ self step.
			^ self scan2 ].
	(currentCharacter <= $& or: [ currentCharacter >= $( ])
		ifTrue: [ ^ self scan2 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX7 [
	[ self recordMatch: #(1).
	self step.
	currentCharacter isSeparator or: [ currentCharacter == Character pageUp ] ]
		whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX8 [
	currentCharacter == ${ ifTrue: [ ^ self recordAndReportMatch: #(16) ].
	currentCharacter == $} ifTrue: [ ^ self recordAndReportMatch: #(17) ].
	currentCharacter isDigit ifTrue: [ ^ self scan9 ].
	(currentCharacter isSeparator or: [ currentCharacter == Character pageUp ])
		ifTrue: [ ^ self scanForTokenX7 ].
	((currentCharacter between: $A and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ ^ self scanForTokenX1 ].
	((currentCharacter between: $! and: $#)
		or: [ (currentCharacter between: $& and: $+)
				or: [ currentCharacter between: $. and: $@ ] ])
		ifTrue: [ self scanForTokenX3 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> tokenActions [
	^ #(#whitespace #comment)
]
