Trait {
	#name : 'TZealNamespace',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealNamespace >> definitionKind [ ^ #namespace
]

{ #category : 'testing' }
TZealNamespace >> isNamespace [ ^ true
]
