Class {
	#name : 'ZealCompletionStrategy',
	#superclass : 'GtCompletionStrategy',
	#instVars : [
		'project',
		'candidates',
		'lastCall'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'private' }
ZealCompletionStrategy >> buildCandidates [
	"Build completion candidates from project + external modules"
	| result |
	result := Dictionary new.
	project ifNil: [ ^ result ].
	
	ZealTheme specialForms do: [:sf | result at: sf put: 'special form' ].
	
	project modules do: [:mod |
		mod definitions do: [:ns |
			(ns respondsTo: #name) ifTrue: [ 
				ns name ifNotNil: [ result at: (self toKebab: ns name) put: 'namespace' ] ].
			(ns respondsTo: #definitions) ifTrue: [
				ns definitions do: [:d |
					((d respondsTo: #name) and: [d name notNil]) ifTrue: [
						result at: (self toKebab: d name) put: (d class name copyReplaceAll: 'Zeal' with: '').
						((d respondsTo: #methods) and: [d methods notNil]) ifTrue: [
							d methods do: [:m | 
								((m respondsTo: #name) and: [m name notNil]) ifTrue: [
									result at: (self toKebab: m name) put: ('method on ' , (self toKebab: d name)) ] ] ].
						((d respondsTo: #fields) and: [d fields notNil]) ifTrue: [
							d fields do: [:f |
								((f respondsTo: #name) and: [f name notNil]) ifTrue: [
									result at: (self toKebab: f name) put: ('field on ' , (self toKebab: d name)) ] ] ] ] ] ] ] ].
	
	project externalModules do: [:mod |
		mod definitions do: [:d |
			((d respondsTo: #name) and: [d name notNil]) ifTrue: [
				result at: (self toKebab: d name) put: (mod name , ' ' , (d class name copyReplaceAll: 'Zeal' with: '')).
				((d respondsTo: #methods) and: [d methods notNil]) ifTrue: [
					d methods do: [:m |
						((m respondsTo: #name) and: [m name notNil]) ifTrue: [
							result at: (self toKebab: m name) put: (mod name , ' method') ] ] ] ] ] ].
	
	^ result
]

{ #category : 'private' }
ZealCompletionStrategy >> candidates [
	^ candidates ifNil: [ candidates := self buildCandidates ]
]

{ #category : 'completion' }
ZealCompletionStrategy >> completionPrefixAt: anInteger in: aText [
	"Extract the word being typed at the cursor position"
	| text i start |
	text := aText asString.
	i := anInteger.
	[ i > 0 and: [
		| c |
		c := text at: i.
		c isLetter or: [c isDigit or: [c = $- or: [c = $/ or: [c = $_ or: [c = $:]]]]]
	] ] whileTrue: [ i := i - 1 ].
	start := i + 1.
	start > anInteger ifTrue: [ ^ '' ].
	^ text copyFrom: start to: anInteger
]

{ #category : 'completion' }
ZealCompletionStrategy >> completionResultFor: aText at: positionInteger requested: aBoolean [
	"Return type-aware completion results with pink-tinted labels"
	| prefix matches stream completionColor |
	prefix := self completionPrefixAt: positionInteger in: aText.
	(prefix isEmpty and: [aBoolean not]) ifTrue: [ ^ GtCompletionResult empty ].
	prefix size < 2 ifTrue: [ aBoolean ifFalse: [ ^ GtCompletionResult empty ] ].
	completionColor := Color fromHexString: 'E8A0BF'.
	
	(prefix includes: $/) ifTrue: [
		^ self memberCompletionFor: aText at: positionInteger prefix: prefix requested: aBoolean ].
	
	matches := self candidates associations
		select: [:assoc |
			(assoc key beginsWith: prefix) or: [self isSubsequence: prefix of: assoc key] ]
		thenCollect: [:assoc |
			| action |
			action := GtInsertTextCompletionAction
				labeled: (self labelFor: assoc key withSearch: prefix)
				completion: (assoc key allButFirst: prefix size)
				position: positionInteger
				from: positionInteger - prefix size + 1.
			action displayText foreground: completionColor.
			action ].
	
	matches isEmpty ifTrue: [ ^ GtCompletionResult empty ].
	stream := matches asAsyncStream.
	^ GtStreamedCompletionResult new stream: stream
]

{ #category : 'private' }
ZealCompletionStrategy >> findTypeOf: varName in: aText [
	"Scan text for type declarations of varName. Also checks all class fields in the project."
	| text searchName i |
	text := (aText respondsTo: #asString) ifTrue: [aText asString] ifFalse: [aText printString].
	searchName := varName asLowercase.
	
	"Search in the text itself"
	i := 1.
	[ i := text asLowercase findString: searchName startingAt: i.
	  i > 0 ] whileTrue: [
		| afterName typeStart typeEnd typeName |
		afterName := i + searchName size.
		(afterName <= text size and: [(text at: afterName) = $:]) ifTrue: [
			typeStart := afterName + 1.
			typeEnd := typeStart.
			[ typeEnd <= text size and: [
				| c | c := text at: typeEnd.
				c isLetter or: [c isDigit or: [c = $_ or: [c = $-]]]
			] ] whileTrue: [ typeEnd := typeEnd + 1 ].
			typeName := text copyFrom: typeStart to: typeEnd - 1.
			typeName notEmpty ifTrue: [ ^ typeName ] ].
		i := i + 1 ].
	
	"Search all class/interface fields in the project"
	project modules do: [:mod |
		mod definitions do: [:ns |
			(ns respondsTo: #definitions) ifTrue: [
				ns definitions do: [:d |
					((d respondsTo: #fields) and: [d fields notNil]) ifTrue: [
						d fields do: [:f |
							((f respondsTo: #name) and: [f name notNil]) ifTrue: [
								(f name asLowercase = searchName and: [f type notNil]) ifTrue: [ ^ f type ] ] ] ] ] ] ] ].
	^ nil
]

{ #category : 'completion' }
ZealCompletionStrategy >> hasCompletionsAt: anInteger in: aText [
	^ true
]

{ #category : 'accessing' }
ZealCompletionStrategy >> lastCall [
	^ lastCall
]

{ #category : 'completion' }
ZealCompletionStrategy >> memberCompletionFor: aText at: positionInteger prefix: fullPrefix requested: aBoolean [
	"Type-aware member completion — only shows members of the resolved type, no fallback"
	| objName memberPrefix typeName members matches stream completionColor |
	completionColor := Color fromHexString: 'E8A0BF'.
	objName := fullPrefix copyUpToLast: $/.
	memberPrefix := fullPrefix copyAfterLast: $/.
	
	typeName := self findTypeOf: objName in: aText.
	typeName ifNil: [ ^ GtCompletionResult empty ].
	
	members := self membersOfClass: typeName.
	matches := (members select: [:assoc | 
		memberPrefix isEmpty or: [(assoc key beginsWith: memberPrefix) or: [self isSubsequence: memberPrefix of: assoc key]] ]) collect: [:assoc |
			| action |
			action := GtInsertTextCompletionAction
				labeled: (self labelFor: assoc key withSearch: memberPrefix)
				completion: (assoc key allButFirst: memberPrefix size)
				position: positionInteger
				from: positionInteger - memberPrefix size + 1.
			action displayText foreground: completionColor.
			action ].
	
	matches isEmpty ifTrue: [ ^ GtCompletionResult empty ].
	stream := matches asAsyncStream.
	^ GtStreamedCompletionResult new stream: stream
]

{ #category : 'private' }
ZealCompletionStrategy >> membersOfClass: className [
	"Get all methods and fields of a class/interface and its supers/parents"
	| resolver cls result visited queue |
	resolver := ZealTypeResolver forProject: project.
	result := OrderedCollection new.
	visited := Set new.
	queue := OrderedCollection new.
	cls := resolver findClass: (className copyReplaceAll: '-' with: '_').
	cls ifNotNil: [ queue add: cls ].
	
	[ queue notEmpty ] whileTrue: [
		cls := queue removeFirst.
		(visited includes: cls name) ifFalse: [
			visited add: cls name.
			(cls respondsTo: #methods) ifTrue: [
				cls methods do: [:m | 
					((m respondsTo: #name) and: [m name notNil]) ifTrue: [
						result add: (self toKebab: m name) -> ('method' , (m type ifNotNil: [:t | ':' , t] ifNil: [''])) ] ] ].
			(cls respondsTo: #fields) ifTrue: [
				cls fields do: [:f |
					((f respondsTo: #name) and: [f name notNil]) ifTrue: [
						result add: (self toKebab: f name) -> ('field' , (f type ifNotNil: [:t | ':' , t] ifNil: [''])) ] ] ].
			"Follow superclass"
			(cls respondsTo: #superclass) ifTrue: [
				cls superclass ifNotNil: [:sc |
					| next |
					next := resolver findClass: (sc copyReplaceAll: '-' with: '_').
					next ifNotNil: [ queue add: next ] ] ].
			"Follow interfaces"
			(cls respondsTo: #interfaces) ifTrue: [
				cls interfaces ifNotNil: [:ifaces |
					ifaces do: [:i |
						| next |
						next := resolver findClass: (i copyReplaceAll: '-' with: '_').
						next ifNotNil: [ queue add: next ] ] ] ].
			"Follow parents (for interfaces)"
			(cls respondsTo: #parents) ifTrue: [
				cls parents ifNotNil: [:ps |
					ps do: [:p |
						| next |
						next := resolver findClass: (p copyReplaceAll: '-' with: '_').
						next ifNotNil: [ queue add: next ] ] ] ] ] ].
	^ result
]

{ #category : 'accessing' }
ZealCompletionStrategy >> project: aProject [
	project := aProject.
	candidates := nil
]

{ #category : 'private' }
ZealCompletionStrategy >> toKebab: aString [
	"Convert PascalCase/snake_case to kebab-case"
	| result |
	result := WriteStream on: String new.
	aString do: [:ch |
		ch = $_ ifTrue: [ result nextPut: $- ]
		ifFalse: [ (ch isUppercase and: [result position > 0]) 
			ifTrue: [ result nextPut: $-; nextPut: ch asLowercase ]
			ifFalse: [ result nextPut: ch asLowercase ] ] ].
	^ result contents
]
