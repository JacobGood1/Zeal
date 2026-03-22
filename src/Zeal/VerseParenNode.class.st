Class {
	#name : 'VerseParenNode',
	#superclass : 'VerseProgramNode',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseParenNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitParen: self
]
