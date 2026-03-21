Class {
	#name : 'ZealScanner',
	#superclass : 'SmaCCScanner',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
ZealScanner >> emptySymbolTokenId [
	^ 27
]

{ #category : 'generated' }
ZealScanner >> errorTokenId [
	^ 28
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
ZealScanner >> scan2 [
	self recordMatch: #(9).
	self step.
	currentCharacter isDigit ifTrue: [ ^ self scan3 ].
	(('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(9).
			self step.
			('!&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $?)
										or: [ (currentCharacter between: $A and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan3 [
	[ self recordMatch: #(4 9).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan4 ].
	currentCharacter isDigit ] whileTrue.
	(('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(9).
			self step.
			('!&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $?)
										or: [ (currentCharacter between: $A and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan4 [
	self recordMatch: #(9).
	self step.
	currentCharacter isDigit ifTrue: [ ^ self scan5 ].
	(('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(9).
			self step.
			('!&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $?)
										or: [ (currentCharacter between: $A and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan5 [
	[ self recordMatch: #(3 9).
	self step.
	currentCharacter isDigit ] whileTrue.
	('Ee' includes: currentCharacter)
		ifTrue: [ self recordMatch: #(9).
			self step.
			currentCharacter isDigit ifTrue: [ ^ self scan6 ].
			('+-' includes: currentCharacter)
				ifTrue: [ self recordMatch: #(9).
					self step.
					currentCharacter isDigit ifTrue: [ ^ self scan6 ].
					(('!&' includes: currentCharacter)
						or: [ (currentCharacter between: $* and: $+)
								or: [ (currentCharacter between: $- and: $/)
										or: [ (currentCharacter between: $< and: $?)
												or: [ (currentCharacter between: $A and: $Z)
														or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ])
						ifTrue: [ [ self recordMatch: #(9).
							self step.
							('!&' includes: currentCharacter)
								or: [ (currentCharacter between: $* and: $+)
										or: [ (currentCharacter between: $- and: $9)
												or: [ (currentCharacter between: $< and: $?)
														or: [ (currentCharacter between: $A and: $Z)
																or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
								whileTrue ].
					^ self reportLastMatch ].
			(('!&*' includes: currentCharacter)
				or: [ (currentCharacter between: $. and: $/)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ])
				ifTrue: [ [ self recordMatch: #(9).
					self step.
					('!&' includes: currentCharacter)
						or: [ (currentCharacter between: $* and: $+)
								or: [ (currentCharacter between: $- and: $9)
										or: [ (currentCharacter between: $< and: $?)
												or: [ (currentCharacter between: $A and: $Z)
														or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
						whileTrue ].
			^ self reportLastMatch ].
	(('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(9).
			self step.
			('!&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $?)
										or: [ (currentCharacter between: $A and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan6 [
	[ self recordMatch: #(3 9).
	self step.
	currentCharacter isDigit ] whileTrue.
	(('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $/)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ])
		ifTrue: [ [ self recordMatch: #(9).
			self step.
			('!&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $?)
										or: [ (currentCharacter between: $A and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan7 [
	self step.
	currentCharacter == $.
		ifTrue: [ self step.
			currentCharacter isDigit
				ifTrue: [ [ self recordMatch: #(7).
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
ZealScanner >> scan8 [
	[ self recordMatch: #(4).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan7 ].
	currentCharacter isDigit ] whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scan9 [
	self step.
	((currentCharacter between: $? and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ [ self recordMatch: #(8).
			self step.
			currentCharacter == $: ifTrue: [ ^ self scan9 ].
			currentCharacter == $-
				or: [ (currentCharacter between: $0 and: $9)
						or: [ currentCharacter == $?
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ]
				whileTrue ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForToken [
	self step.
	currentCharacter == $" ifTrue: [ ^ self scan1 ].
	currentCharacter == $( ifTrue: [ ^ self recordAndReportMatch: #(11) ].
	currentCharacter == $) ifTrue: [ ^ self recordAndReportMatch: #(12) ].
	currentCharacter == $- ifTrue: [ ^ self scan2 ].
	currentCharacter == $0 ifTrue: [ ^ self scanForTokenX3 ].
	currentCharacter == $: ifTrue: [ ^ self scanForTokenX4 ].
	currentCharacter == $; ifTrue: [ ^ self scanForTokenX5 ].
	currentCharacter == $[ ifTrue: [ ^ self recordAndReportMatch: #(13) ].
	currentCharacter == $] ifTrue: [ ^ self recordAndReportMatch: #(14) ].
	^ self scanForTokenX7
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX1 [
	[ self recordMatch: #(9).
	self step.
	currentCharacter == $: ifTrue: [ ^ self scan9 ].
	(('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $. and: $/)
						or: [ currentCharacter between: $< and: $? ] ] ])
		ifTrue: [ [ self recordMatch: #(9).
			self step.
			('!&' includes: currentCharacter)
				or: [ (currentCharacter between: $* and: $+)
						or: [ (currentCharacter between: $- and: $9)
								or: [ (currentCharacter between: $< and: $?)
										or: [ (currentCharacter between: $A and: $Z)
												or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
				whileTrue.
			^ self reportLastMatch ].
	(currentCharacter between: $- and: $9)
		or: [ (currentCharacter between: $A and: $Z)
				or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ]
		whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX2 [
	[ self recordMatch: #(9).
	self step.
	('!&' includes: currentCharacter)
		or: [ (currentCharacter between: $* and: $+)
				or: [ (currentCharacter between: $- and: $9)
						or: [ (currentCharacter between: $< and: $?)
								or: [ (currentCharacter between: $A and: $Z)
										or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ] ] ] ] ] ]
		whileTrue
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX3 [
	self recordMatch: #(4).
	self step.
	currentCharacter == $. ifTrue: [ ^ self scan7 ].
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
	currentCharacter isDigit ifTrue: [ ^ self scan8 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX4 [
	self step.
	((currentCharacter between: $A and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ [ self recordMatch: #(10).
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
	[ self recordMatch: #(1).
	self step.
	currentCharacter isSeparator or: [ currentCharacter == Character pageUp ] ]
		whileTrue.
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> scanForTokenX7 [
	currentCharacter == ${ ifTrue: [ ^ self recordAndReportMatch: #(15) ].
	currentCharacter == $} ifTrue: [ ^ self recordAndReportMatch: #(16) ].
	currentCharacter isDigit ifTrue: [ ^ self scan8 ].
	(currentCharacter isSeparator or: [ currentCharacter == Character pageUp ])
		ifTrue: [ ^ self scanForTokenX6 ].
	((currentCharacter between: $A and: $Z)
		or: [ currentCharacter == $_ or: [ currentCharacter between: $a and: $z ] ])
		ifTrue: [ ^ self scanForTokenX1 ].
	((currentCharacter between: $! and: $#)
		or: [ currentCharacter == $&
				or: [ (currentCharacter between: $* and: $+)
						or: [ currentCharacter between: $. and: $@ ] ] ])
		ifTrue: [ self scanForTokenX2 ].
	^ self reportLastMatch
]

{ #category : 'generated' }
ZealScanner >> tokenActions [
	^ #(#whitespace #comment)
]
