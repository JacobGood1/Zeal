Class {
	#name : 'VerseBlockNode',
	#superclass : 'VerseProgramNode',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseBlockNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitBlock: self
]
