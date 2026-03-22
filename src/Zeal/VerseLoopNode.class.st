Class {
	#name : 'VerseLoopNode',
	#superclass : 'VerseProgramNode',
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseLoopNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitLoop: self
]
