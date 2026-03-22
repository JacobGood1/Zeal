Class {
	#name : 'VerseTypeTypeNode',
	#superclass : 'VerseProgramNode',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'generated' }
VerseTypeTypeNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitTypeType: self
]
