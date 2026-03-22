Class {
	#name : 'VerseIdentNode',
	#superclass : 'VerseProgramNode',
	#instVars : [
		'value'
	],
	#category : 'Zeal-VerseParser',
	#package : 'Zeal',
	#tag : 'VerseParser'
}

{ #category : 'generated' }
VerseIdentNode >> acceptVisitor: aProgramVisitor [
	^ aProgramVisitor visitIdent: self
]

{ #category : 'generated' }
VerseIdentNode >> tokenVariables [
	^ #(#value)
]

{ #category : 'generated' }
VerseIdentNode >> value [
	^ value
]

{ #category : 'generated' }
VerseIdentNode >> value: aSmaCCToken [
	value := aSmaCCToken
]
