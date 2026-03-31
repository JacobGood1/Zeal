Class {
	#name : 'ZealModuleCompletionStrategy',
	#superclass : 'GtCompletionStrategy',
	#instVars : [
		'project',
		'candidates'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'private' }
ZealModuleCompletionStrategy >> buildCandidates [
	"Collect module paths from local modules and external digest files.
	 Local sub-modules are listed without the root module prefix."
	| result |
	result := OrderedCollection new.
	project ifNil: [ ^ result ].
	
	"Local modules — skip root, show sub-modules directly"
	project modules do: [:mod |
		mod definitions do: [:d |
			(d isKindOf: ZealModule) ifTrue: [
				result add: d name.
				self collectSubModules: d prefix: d name into: result ] ] ].
	
	"External module paths from digest files"
	self collectDigestModulePaths: result.
	
	^ result asSet asOrderedCollection sorted
]

{ #category : 'private' }
ZealModuleCompletionStrategy >> candidates [
	^ candidates ifNil: [ candidates := self buildCandidates ]
]

{ #category : 'private' }
ZealModuleCompletionStrategy >> collectDigestModulePaths: result [
	"Scan digest files for module declarations and using paths"
	| verseProjectPath |
	verseProjectPath := ('C:\Users\Jacob Goodson\AppData\Local\UnrealEditorFortnite\Saved\VerseProject' asFileReference / project name).
	verseProjectPath exists ifFalse: [ ^ self ].
	
	verseProjectPath directories do: [:dir |
		| digestFile |
		digestFile := dir files detect: [:f | f basename endsWith: '.digest.verse'] ifNone: [nil].
		digestFile ifNotNil: [
			[ self extractModulePaths: digestFile contents into: result ]
				on: Error do: [:e | ] ] ]
]

{ #category : 'private' }
ZealModuleCompletionStrategy >> collectSubModules: aModule prefix: aPrefix into: result [
	"Recursively collect nested module paths"
	(aModule respondsTo: #definitions) ifFalse: [ ^ self ].
	aModule definitions do: [:d |
		(d isKindOf: ZealModule) ifTrue: [
			| path |
			path := aPrefix, '/', d name.
			result add: path.
			self collectSubModules: d prefix: path into: result ] ]
]

{ #category : 'completion' }
ZealModuleCompletionStrategy >> completionPrefixAt: anInteger in: aText [
	"Extract prefix — handle module paths with / and . separators"
	| text i start |
	text := aText asString.
	i := anInteger.
	[ i > 0 and: [
		| c |
		c := text at: i.
		c isLetter or: [c isDigit or: [c = $- or: [c = $_ or: [c = $/ or: [c = $.]]]]]
	] ] whileTrue: [ i := i - 1 ].
	start := i + 1.
	start > anInteger ifTrue: [ ^ '' ].
	^ text copyFrom: start to: anInteger
]

{ #category : 'completion' }
ZealModuleCompletionStrategy >> completionResultFor: aText at: positionInteger requested: aBoolean [
	| prefix matches stream completionColor |
	prefix := self completionPrefixAt: positionInteger in: aText.
	(prefix isEmpty and: [ aBoolean not ]) ifTrue: [ ^ GtCompletionResult empty ].
	
	completionColor := ZealTheme symbolColor.
	
	matches := self candidates
		select: [:path | prefix isEmpty or: [ path asLowercase beginsWith: prefix asLowercase ] ]
		thenCollect: [:path |
			| action |
			action := GtInsertTextCompletionAction
				labeled: (path asRopedText foreground: completionColor)
				completion: (path allButFirst: prefix size)
				position: positionInteger
				from: positionInteger - prefix size + 1.
			action ].
	
	matches isEmpty ifTrue: [ ^ GtCompletionResult empty ].
	stream := matches asAsyncStream.
	^ GtStreamedCompletionResult new stream: stream
]

{ #category : 'private' }
ZealModuleCompletionStrategy >> extractModulePaths: content into: result [
	"Extract module paths from digest content.
	 Handles:
	   # Module import path: /Fortnite.com/UI
	   (/Fortnite.com:)UI<public> := module:
	   using {/Verse.org/Random}
	   Random<public> := module:  (nested inside Verse module)"
	| lines indentStack |
	lines := content lines.
	indentStack := OrderedCollection new.
	
	lines do: [:rawLine |
		| stripped indent |
		stripped := rawLine trimLeft.
		indent := rawLine size - stripped size.
		stripped := stripped trimBoth.
		
		"Extract from '# Module import path: /Path/Here'"
		(stripped beginsWith: '# Module import path: /') ifTrue: [
			result add: (stripped allButFirst: '# Module import path: ' size) ].
		
		"Extract from 'using {/Path/Here}'"
		(stripped beginsWith: 'using {/') ifTrue: [
			| path |
			path := stripped allButFirst: 'using {' size.
			(path endsWith: '}') ifTrue: [ path := path allButLast ].
			result add: path ] ]
]

{ #category : 'testing' }
ZealModuleCompletionStrategy >> hasCompletionEntryFor: aString [
	^ true
]

{ #category : 'accessing' }
ZealModuleCompletionStrategy >> project: aProject [
	project := aProject.
	candidates := nil
]
