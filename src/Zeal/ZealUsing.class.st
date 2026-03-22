Class {
	#name : 'ZealUsing',
	#superclass : 'ZealNode',
	#instVars : [
		'path'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealUsing >> compileToVerse: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: 'using { '; nextPutAll: path; nextPutAll: ' }'
]

{ #category : 'compiling' }
ZealUsing >> compileToZeal: stream indent: level [
	self emitIndent: level on: stream.
	stream nextPutAll: '(using ' , path , ')'
]

{ #category : 'accessing' }
ZealUsing >> path [ ^ path
]

{ #category : 'accessing' }
ZealUsing >> path: s [ path := s
]
