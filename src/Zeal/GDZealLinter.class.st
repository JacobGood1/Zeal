Class {
	#name : 'GDZealLinter',
	#superclass : 'Object',
	#instVars : [
		'typeSystem',
		'diagnostics',
		'source'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
GDZealLinter class >> withTypeSystem: aTypeSystem [
	^ self new typeSystem: aTypeSystem; yourself
]

{ #category : 'linting' }
GDZealLinter >> lintBindingForm: aForm [
	"Extract the bindings vector, build a name→type map, then walk the body validating
	 every slash-chain symbol against the map."
	| exprs bodyForms bindingVec bindings |
	exprs := aForm expressions.
	"Skip head (defsystem/defcosystem) and name (second)"
	exprs size < 3 ifTrue: [ ^ self ].
	bindingVec := exprs at: 3.
	(bindingVec isKindOf: ZealVectorNode) ifFalse: [ ^ self ].
	bindings := self parseBindingVector: bindingVec.
	bodyForms := exprs copyFrom: 4 to: exprs size.
	bodyForms do: [ :form | self walkExpression: form withBindings: bindings ]
]

{ #category : 'linting' }
GDZealLinter >> lintSource: aSourceString [
	"Parse the source and return an OrderedCollection of diagnostic Dictionaries.
	 Each diagnostic has #message, #severity (#error/#warning), #startPos, #stopPos."
	| ast |
	source := aSourceString.
	diagnostics := OrderedCollection new.
	[ ast := ZealParser parse: aSourceString ] on: Error do: [ :e | ^ diagnostics ].
	ast ifNil: [ ^ diagnostics ].
	"Walk top-level forms looking for defsystem/defcosystem"
	(ast respondsTo: #expressions) ifTrue: [
		ast expressions do: [ :form | self lintTopLevel: form ] ].
	^ diagnostics
]

{ #category : 'linting' }
GDZealLinter >> lintTopLevel: aForm [
	"Dispatch on top-level form kind. Only defsystem/defcosystem have bindings, so only
	 those need slash-chain validation. (defcomp doesn't have a body that can reference
	 fields by binding name; def/defn don't either.)"
	| head exprs |
	(aForm isKindOf: ZealListNode) ifFalse: [ ^ self ].
	exprs := aForm expressions.
	exprs isEmpty ifTrue: [ ^ self ].
	head := exprs first value value.
	(head = 'defsystem' or: [ head = 'defcosystem' ]) ifTrue: [
		self lintBindingForm: aForm ]
]

{ #category : 'linting' }
GDZealLinter >> parseBindingVector: aVectorNode [
	"Build a Dictionary of bindingName(String)→typeRef(String) from a defsystem
	 vector like [@health hp:@velocity]. Plain @foo binds 'foo'->'foo'.
	 Colon-chain hp:@velocity binds 'hp'->'velocity'."
	| map |
	map := Dictionary new.
	aVectorNode expressions do: [ :node |
		(node isKindOf: ZealColonChainNode) 
			ifTrue: [
				| chain parts bindingName typeRef |
				chain := node value value.
				parts := chain substrings: ':'.
				parts size >= 2 ifTrue: [
					bindingName := parts first.
					typeRef := parts second.
					(typeRef beginsWith: '@') ifTrue: [ typeRef := typeRef allButFirst ].
					map at: bindingName put: typeRef ] ]
			ifFalse: [
				(node isKindOf: ZealSymbolNode) ifTrue: [
					| ref typeRef |
					ref := node value value.
					typeRef := (ref beginsWith: '@') ifTrue: [ ref allButFirst ] ifFalse: [ ref ].
					map at: typeRef put: typeRef ] ] ].
	^ map
]

{ #category : 'accessing' }
GDZealLinter >> typeSystem: aTypeSystem [
	typeSystem := aTypeSystem
]

{ #category : 'linting' }
GDZealLinter >> validateSlashChain: aSymbolNode in: bindings [
	"For a symbol like 'health/maximu', look up 'health' in the bindings to get its type,
	 then check that 'maximu' is a member of that type. Report a diagnostic if not."
	| sym parts head field type members tok |
	sym := aSymbolNode value value.
	parts := sym substrings: '/'.
	parts size < 2 ifTrue: [ ^ self ].
	head := parts first.
	type := bindings at: head ifAbsent: [ ^ self ].  "unknown binding — not our problem"
	"Walk one level at a time. For now we only validate the first hop (binding/field)."
	field := parts second.
	members := typeSystem membersOf: type.
	members isEmpty ifTrue: [ ^ self ].  "unknown type — bail rather than false-positive"
	(members includesKey: field) ifTrue: [ ^ self ].
	"Found a typo. Build a diagnostic with token position."
	tok := aSymbolNode value.
	"Compute the substring offset of the bad field within the symbol token"
	diagnostics add: (Dictionary new
		at: #message put: 'Unknown field "' , field , '" on ' , type 
			, ' (known: ' , (members keys asSortedCollection asArray printString) , ')';
		at: #severity put: #error;
		at: #startPos put: tok startPosition;
		at: #stopPos put: tok stopPosition;
		yourself)
]

{ #category : 'linting' }
GDZealLinter >> walkExpression: aNode withBindings: bindings [
	"Recurse into list/vector children. For symbol nodes containing '/', validate the
	 chain against the bindings."
	(aNode isKindOf: ZealSymbolNode) ifTrue: [
		| sym |
		sym := aNode value value.
		(sym includes: $/) ifTrue: [
			self validateSlashChain: aNode in: bindings ].
		^ self ].
	((aNode isKindOf: ZealListNode) or: [ aNode isKindOf: ZealVectorNode ]) ifTrue: [
		aNode expressions do: [ :child | self walkExpression: child withBindings: bindings ] ]
]
