Class {
	#name : 'ZealIdentifierMungerExamples',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'examples' }
ZealIdentifierMungerExamples >> angelIdentifierAppliesPascalCase [
	"Angel's identifierFor: chains munge + PascalCase: `even?` → `Even`,
	 `set-state!` → `SetState`."
	<gtExample>
	| gen |
	gen := AngelZealCodeGenerator new.
	self assert: (gen identifierFor: 'even?') equals: 'Even' label: 'angel: even? → Even'.
	self assert: (gen identifierFor: 'set-state!') equals: 'SetState' label: 'angel: set-state! → SetState'.
	self assert: (gen identifierFor: 'plain-name') equals: 'PlainName' label: 'angel: plain-name → PlainName'.
	^ gen
]

{ #category : 'helpers' }
ZealIdentifierMungerExamples >> assert: actual equals: expected label: label [
	actual = expected ifTrue: [ ^ self ].
	^ self error: label , ' — expected ' , expected printString
		, ' but got ' , actual printString
]

{ #category : 'examples' }
ZealIdentifierMungerExamples >> bangSuffixDropped [
	"`swap!` → `swap` — mutator suffix is stripped before case conversion."
	<gtExample>
	| gen |
	gen := AngelZealCodeGenerator new.
	self assert: (gen mungeForIdentifier: 'swap!') equals: 'swap' label: 'munge drops trailing !'.
	self assert: (gen mungeForIdentifier: 'set-state!') equals: 'set-state' label: 'munge drops ! from kebab name'.
	^ gen
]

{ #category : 'examples' }
ZealIdentifierMungerExamples >> godotIdentifierAppliesSnakeCase [
	"Godot overrides caseStyleFor: to snake_case while inheriting the
	 munger from base — so `even?` → `even`, `set-state!` → `set_state`."
	<gtExample>
	| gen |
	gen := GodotZealCodeGenerator new.
	self assert: (gen identifierFor: 'even?') equals: 'even' label: 'godot: even? → even'.
	self assert: (gen identifierFor: 'set-state!') equals: 'set_state' label: 'godot: set-state! → set_state'.
	self assert: (gen identifierFor: 'plain-name') equals: 'plain_name' label: 'godot: plain-name → plain_name'.
	^ gen
]

{ #category : 'examples' }
ZealIdentifierMungerExamples >> hyphensSurviveMunging [
	"Hyphens are kept by the munger; the case-conversion step (toPascalCase:
	 / toSnakeCase:) handles them as word boundaries."
	<gtExample>
	| gen |
	gen := AngelZealCodeGenerator new.
	self assert: (gen mungeForIdentifier: 'foo-bar-baz') equals: 'foo-bar-baz'
		label: 'munge keeps hyphens'.
	^ gen
]

{ #category : 'examples' }
ZealIdentifierMungerExamples >> questionSuffixDropped [
	"`even?` → `even` — predicate suffix is stripped before case conversion."
	<gtExample>
	| gen |
	gen := AngelZealCodeGenerator new.
	self assert: (gen mungeForIdentifier: 'even?') equals: 'even' label: 'munge drops trailing ?'.
	self assert: (gen mungeForIdentifier: 'pred-foo?') equals: 'pred-foo' label: 'munge drops ? from kebab name'.
	^ gen
]
