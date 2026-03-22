Class {
	#name : 'ZealBreak',
	#superclass : 'ZealExpression',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealBreak >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'break'
]

{ #category : 'compiling' }
ZealBreak >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(break)'
]
