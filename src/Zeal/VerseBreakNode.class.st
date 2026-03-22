Class {
	#name : 'VerseBreakNode',
	#superclass : 'VerseProgramNode',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseBreakNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitBreak: self
]
