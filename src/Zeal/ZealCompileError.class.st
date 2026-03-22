Class {
	#name : 'ZealCompileError',
	#superclass : 'ZealNode',
	#instVars : [
		'message',
		'source'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'compiling' }
ZealCompileError >> compileToVerse [
	^ 'ERROR: ' , message
]

{ #category : 'compiling' }
ZealCompileError >> compileToVerse: stream indent: level [
	stream nextPutAll: '/* ERROR: '; nextPutAll: message; nextPutAll: ' */'
]

{ #category : 'views' }
ZealCompileError >> gtErrorFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Error';
		text: [ message ]
]

{ #category : 'accessing' }
ZealCompileError >> message [ ^ message
]

{ #category : 'accessing' }
ZealCompileError >> message: s [ message := s
]

{ #category : 'printing' }
ZealCompileError >> printOn: aStream [
	aStream nextPutAll: 'ZealError: '; nextPutAll: message
]

{ #category : 'accessing' }
ZealCompileError >> source [ ^ source
]

{ #category : 'accessing' }
ZealCompileError >> source: s [ source := s
]
