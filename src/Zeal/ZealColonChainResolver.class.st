Class {
	#name : 'ZealColonChainResolver',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'classification' }
ZealColonChainResolver class >> declarationSpecifiers [
	^ #('public' 'private' 'protected' 'internal' 'abstract' 'concrete' 'final' 'unique' 'native' 'native_callable')
]

{ #category : 'classification' }
ZealColonChainResolver class >> isDeclarationSpecifier: aString [
	^ self declarationSpecifiers includes: aString
]

{ #category : 'classification' }
ZealColonChainResolver class >> isSignatureSpecifier: aString [
	^ self signatureSpecifiers includes: aString
]

{ #category : 'classification' }
ZealColonChainResolver class >> isSpecifier: aString [
	^ (self declarationSpecifiers includes: aString) or: [
		(self signatureSpecifiers includes: aString) or: [
			self memberSpecifiers includes: aString ] ]
]

{ #category : 'classification' }
ZealColonChainResolver class >> memberSpecifiers [
	^ #('override' 'constructor' 'localizes')
]

{ #category : 'resolving' }
ZealColonChainResolver class >> resolve: aString [
	| segments name specifiers annotations type |
	segments := aString splitOn: $:.
	name := segments first.
	specifiers := OrderedCollection new.
	annotations := OrderedCollection new.
	type := nil.
	segments allButFirst do: [:seg |
		(seg beginsWith: '@')
			ifTrue: [ annotations add: seg ]
			ifFalse: [ (self isSpecifier: seg)
				ifTrue: [ specifiers add: seg ]
				ifFalse: [ type := seg ] ] ].
	^ Dictionary new
		at: #name put: name;
		at: #type put: type;
		at: #specifiers put: specifiers asArray;
		at: #annotations put: annotations asArray;
		yourself
]

{ #category : 'classification' }
ZealColonChainResolver class >> signatureSpecifiers [
	^ #('suspends' 'decides' 'transacts' 'varies' 'computes' 'converges')
]
