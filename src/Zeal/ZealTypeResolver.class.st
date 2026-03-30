Class {
	#name : 'ZealTypeResolver',
	#superclass : 'Object',
	#instVars : [
		'project',
		'scopes',
		'typeCache',
		'classCache',
		'functionCache',
		'dependencies',
		'dependents',
		'currentTrack'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
ZealTypeResolver class >> forProject: aZealProject [
	^ self new project: aZealProject
]

{ #category : 'tracking' }
ZealTypeResolver >> cachedType: cacheKey ifAbsent: aBlock [
	| previousTrack result deps |
	typeCache at: cacheKey ifPresent: [:type | ^ type ].
	previousTrack := currentTrack.
	currentTrack := Set new.
	result := aBlock value.
	deps := currentTrack.
	currentTrack := previousTrack.
	result ifNotNil: [
		typeCache at: cacheKey put: result.
		dependencies at: cacheKey put: deps.
		deps do: [:dep |
			(dependents at: dep ifAbsentPut: [ Set new ]) add: cacheKey ] ].
	previousTrack ifNotNil: [ previousTrack addAll: deps ].
	^ result
]

{ #category : 'accessing' }
ZealTypeResolver >> classCache [ ^ classCache
]

{ #category : 'lookup' }
ZealTypeResolver >> findClass: aName [
	"Find class/struct/interface by name — searches all levels"
	| kebab snake |
	classCache at: aName ifPresent: [:v | ^ v].
	self trackDependency: aName.
	project ifNil: [ ^ nil ].
	kebab := aName copyReplaceAll: '_' with: '-'.
	snake := aName copyReplaceAll: '-' with: '_'.
	project modules do: [:mod |
		self searchModule: mod forClass: aName kebab: kebab snake: snake ifFound: [:d | classCache at: aName put: d. ^ d ] ].
	project externalModules do: [:mod |
		mod definitions do: [:d |
			((d isKindOf: ZealClass) or: [(d isKindOf: ZealStruct) or: [d isKindOf: ZealInterface]]) ifTrue: [
				(d name = aName or: [d name = kebab or: [d name = snake]])
					ifTrue: [ classCache at: aName put: d. ^ d ] ] ] ].
	^ nil
]

{ #category : 'lookup' }
ZealTypeResolver >> findFunction: aName [
	"Find function by name — searches all levels, case-insensitive"
	functionCache at: aName ifPresent: [:v | ^ v].
	self trackDependency: aName.
	project ifNil: [ ^ nil ].
	project modules do: [:mod |
		self searchModule: mod forFunction: aName ifFound: [:d | functionCache at: aName put: d. ^ d ] ].
	project externalModules do: [:mod |
		mod definitions do: [:d |
			((d isKindOf: ZealFunction) and: [d name asLowercase = aName asLowercase])
				ifTrue: [ functionCache at: aName put: d. ^ d ] ] ].
	^ nil
]

{ #category : 'lookup' }
ZealTypeResolver >> findMethod: methodName inClass: className [
	"Find a method by name in a class (searches class and superclasses)"
	| cls |
	cls := self findClass: className.
	[ cls notNil ] whileTrue: [
		cls methods do: [:m |
			m name = methodName ifTrue: [ ^ m ] ].
		cls superclass ifNotNil: [:sc | 
			cls := self findClass: sc name ]
		ifNil: [ cls := nil ] ].
	^ nil
]

{ #category : 'lookup' }
ZealTypeResolver >> findMethodAnywhere: methodName [
	"Find a method by name across all classes — searches all module levels"
	| lowerName |
	lowerName := methodName asLowercase.
	project ifNil: [ ^ nil ].
	project modules do: [:mod |
		| result |
		result := self searchModuleForMethod: mod name: lowerName.
		result ifNotNil: [ ^ result ] ].
	project externalModules do: [:mod |
		mod definitions do: [:d |
			(d respondsTo: #methods) ifTrue: [
				d methods do: [:m |
					m name asLowercase = lowerName ifTrue: [ ^ m ] ] ] ] ].
	^ nil
]

{ #category : 'accessing' }
ZealTypeResolver >> functionCache [ ^ functionCache
]

{ #category : 'initialization' }
ZealTypeResolver >> initialize [
	super initialize.
	scopes := OrderedCollection new.
	typeCache := Dictionary new.
	classCache := Dictionary new.
	functionCache := Dictionary new.
	dependencies := Dictionary new.
	dependents := Dictionary new.
	currentTrack := nil
]

{ #category : 'tracking' }
ZealTypeResolver >> invalidate: aDefinitionName [
	"Invalidate all cached data related to this definition. Cascades."
	| keysToInvalidate |
	"Clear from direct caches"
	classCache removeKey: aDefinitionName ifAbsent: [].
	functionCache removeKey: aDefinitionName ifAbsent: [].
	"Cascade through type cache dependencies"
	keysToInvalidate := (dependents removeKey: aDefinitionName ifAbsent: [ #() ]) asArray.
	keysToInvalidate do: [:key |
		typeCache removeKey: key ifAbsent: [].
		dependencies removeKey: key ifAbsent: [].
		self invalidate: key ]
]

{ #category : 'tracking' }
ZealTypeResolver >> invalidateAll [
	typeCache removeAll.
	classCache removeAll.
	functionCache removeAll.
	dependencies removeAll.
	dependents removeAll
]

{ #category : 'tracking' }
ZealTypeResolver >> onClassRemoved: ann [
	| cls |
	cls := ann classRemoved.
	(cls name beginsWith: 'Zeal_') ifFalse: [ ^ self ].
	self invalidateAll
]

{ #category : 'tracking' }
ZealTypeResolver >> onMethodChanged: ann [
	| cls parts defName |
	cls := ann methodClass.
	(cls name beginsWith: 'Zeal_') ifFalse: [ ^ self ].
	(#(zealSource verseSource) includes: ann selector) ifFalse: [ ^ self ].
	parts := cls name splitOn: $_.
	defName := parts last.
	self invalidate: defName
]

{ #category : 'scoping' }
ZealTypeResolver >> popScope [
	scopes removeLast
]

{ #category : 'accessing' }
ZealTypeResolver >> project [
	^ project
]

{ #category : 'accessing' }
ZealTypeResolver >> project: aProject [
	project := aProject
]

{ #category : 'scoping' }
ZealTypeResolver >> pushScope: aDictionary [
	"Push a new scope (name -> type mappings)"
	scopes add: aDictionary
]

{ #category : 'scoping' }
ZealTypeResolver >> pushScopeForFunction: aZealFunction [
	"Push parameter types + any class fields if inside a class"
	| scope |
	scope := Dictionary new.
	aZealFunction parameters do: [:p |
		p type ifNotNil: [ scope at: p name put: p type ] ].
	"If inside a class, add fields"
	aZealFunction owningClass ifNotNil: [:cls |
		cls fields do: [:f | f type ifNotNil: [ scope at: f name put: f type ] ] ].
	self pushScope: scope
]

{ #category : 'scoping' }
ZealTypeResolver >> pushScopeForNamespace: aZealModule [
	"Push all top-level definitions in a namespace"
	| scope |
	scope := Dictionary new.
	aZealModule definitions do: [:d |
		(d respondsTo: #name) ifTrue: [
			d name ifNotNil: [
				(d respondsTo: #type) ifTrue: [ d type ifNotNil: [ scope at: d name put: d type ] ].
				"Classes/structs/enums register as their own type"
				((d isKindOf: ZealClass) or: [(d isKindOf: ZealStruct) or: [d isKindOf: ZealEnum]]) ifTrue: [
					scope at: d name put: d name ] ] ] ].
	self pushScope: scope
]

{ #category : 'lookup' }
ZealTypeResolver >> searchModule: aModule forClass: aName kebab: kebab snake: snake ifFound: aBlock [
	"Recursively search module and sub-modules for a class/struct/interface"
	aModule definitions do: [:d |
		((d isKindOf: ZealClass) or: [(d isKindOf: ZealStruct) or: [d isKindOf: ZealInterface]]) ifTrue: [
			(d name = aName or: [d name = kebab or: [d name = snake]])
				ifTrue: [ aBlock value: d ] ].
		(d isKindOf: ZealModule) ifTrue: [
			self searchModule: d forClass: aName kebab: kebab snake: snake ifFound: aBlock ] ]
]

{ #category : 'lookup' }
ZealTypeResolver >> searchModule: aModule forFunction: aName ifFound: aBlock [
	"Recursively search for a function — matches PascalCase, kebab-case, or case-insensitive"
	| lower kebab |
	lower := aName asLowercase.
	kebab := aName copyReplaceAll: '_' with: '-'.
	aModule definitions do: [:d |
		((d isKindOf: ZealFunction) and: [
			d name asLowercase = lower or: [
			d name = aName or: [
			d name = kebab or: [
			(d name copyReplaceAll: '-' with: '') = (aName copyReplaceAll: '-' with: '') asLowercase ]]]]) 
				ifTrue: [ aBlock value: d ].
		(d isKindOf: ZealModule) ifTrue: [
			self searchModule: d forFunction: aName ifFound: aBlock ] ]
]

{ #category : 'lookup' }
ZealTypeResolver >> searchModuleForMethod: aModule name: lowerName [
	"Recursively search for a method in all classes within a module"
	aModule definitions do: [:d |
		(d respondsTo: #methods) ifTrue: [
			d methods do: [:m |
				(m name asLowercase = lowerName) ifTrue: [ ^ m ] ] ].
		(d isKindOf: ZealModule) ifTrue: [
			| result |
			result := self searchModuleForMethod: d name: lowerName.
			result ifNotNil: [ ^ result ] ] ].
	^ nil
]

{ #category : 'tracking' }
ZealTypeResolver >> subscribeToChanges [
	"Subscribe to system announcements to auto-invalidate cache when definitions change"
	SystemAnnouncer uniqueInstance weak
		when: MethodModified send: #onMethodChanged: to: self;
		when: ClassRemoved send: #onClassRemoved: to: self
]

{ #category : 'tracking' }
ZealTypeResolver >> trackDependency: aDefinitionName [
	"Record that the current resolution depends on this definition"
	currentTrack ifNotNil: [
		currentTrack add: aDefinitionName.
		(dependents at: aDefinitionName ifAbsentPut: [ Set new ]) add: currentTrack ]
]

{ #category : 'accessing' }
ZealTypeResolver >> typeCache [ ^ typeCache
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfArray: anArray [
	| elemType |
	anArray elements isEmpty ifTrue: [ ^ '[]any' ].
	elemType := self typeOfExpression: anArray elements first.
	elemType ifNil: [ ^ '[]any' ].
	^ '[]' , elemType
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfCall: aCall [
	| func |
	aCall functionName = '.' ifTrue: [ ^ self typeOfMemberAccess: aCall ].
	aCall functionName = '[]' ifTrue: [ ^ self typeOfIndexAccess: aCall ].
	func := self findFunction: aCall functionName.
	func ifNotNil: [ ^ func type ].
	^ nil
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfExpression: aZealNode [
	| cacheKey |
	cacheKey := aZealNode identityHash printString.
	^ self cachedType: cacheKey ifAbsent: [
		(aZealNode isKindOf: ZealLiteral) ifTrue: [ self typeOfLiteral: aZealNode ]
		ifFalse: [ (aZealNode isKindOf: ZealSymbolRef) ifTrue: [ self typeOfName: aZealNode name ]
		ifFalse: [ (aZealNode isKindOf: ZealOperator) ifTrue: [ self typeOfOperator: aZealNode ]
		ifFalse: [ (aZealNode isKindOf: ZealFunctionCall) ifTrue: [ self typeOfCall: aZealNode ]
		ifFalse: [ (aZealNode isKindOf: ZealArray) ifTrue: [ self typeOfArray: aZealNode ]
		ifFalse: [ nil ] ] ] ] ] ]
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfIndexAccess: aCall [
	"arr[0] — the element type of the array"
	| recvType |
	recvType := self typeOfExpression: aCall arguments first.
	recvType ifNil: [ ^ nil ].
	"[]type -> type (strip array prefix)"
	(recvType beginsWith: '[]') ifTrue: [ ^ recvType allButFirst: 2 ].
	"string[n] -> char"
	recvType = 'string' ifTrue: [ ^ 'char' ].
	^ nil
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfLiteral: aLiteral [
	aLiteral literalType = #integer ifTrue: [ ^ 'int' ].
	aLiteral literalType = #float ifTrue: [ ^ 'float' ].
	aLiteral literalType = #string ifTrue: [ ^ 'string' ].
	aLiteral literalType = #char ifTrue: [ ^ 'char' ].
	aLiteral literalType = #boolean ifTrue: [ ^ 'logic' ].
	aLiteral literalType = #range ifTrue: [ ^ 'int' ]. "range produces ints"
	^ nil
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfMemberAccess: aCall [
	"obj.member — look up member type on the receiver's class"
	| recvType memberName cls method field |
	recvType := self typeOfExpression: aCall arguments first.
	recvType ifNil: [ ^ nil ].
	memberName := (aCall arguments size >= 2 and: [aCall arguments second isKindOf: ZealSymbolRef])
		ifTrue: [ aCall arguments second name ] ifFalse: [ ^ nil ].
	cls := self findClass: recvType.
	cls ifNil: [ ^ nil ].
	"Check methods"
	method := cls methods detect: [:m | m name = memberName] ifNone: [nil].
	method ifNotNil: [ ^ method type ].
	"Check fields"
	field := cls fields detect: [:f | f name = memberName] ifNone: [nil].
	field ifNotNil: [ ^ field type ].
	^ nil
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfName: aName [
	"Look up the type of a name by walking scopes from innermost to outermost"
	scopes reverseDo: [:scope |
		scope at: aName ifPresent: [:type | ^ type ] ].
	^ nil
]

{ #category : 'resolving' }
ZealTypeResolver >> typeOfOperator: anOp [
	"Infer type from operator"
	(#('+' '-' '*' '/') includes: anOp operator) ifTrue: [
		"Arithmetic: result type from first operand"
		^ self typeOfExpression: anOp operands first ].
	(#('=' '<>' '<' '>' '<=' '>=') includes: anOp operator) ifTrue: [ ^ 'logic' ].
	(#('and' 'or' 'not') includes: anOp operator) ifTrue: [ ^ 'logic' ].
	anOp operator = '?' ifTrue: [ ^ self typeOfExpression: anOp operands first ].
	anOp operator = '..' ifTrue: [ ^ 'int' ].
	^ nil
]

{ #category : 'tracking' }
ZealTypeResolver >> unsubscribe [
	SystemAnnouncer uniqueInstance unsubscribe: self
]
