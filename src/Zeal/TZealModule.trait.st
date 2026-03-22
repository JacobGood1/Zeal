Trait {
	#name : 'TZealModule',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealModule >> definitionKind [ ^ #module
]

{ #category : 'accessing' }
TZealModule >> definitions [ ^ self zealNode definitions
]

{ #category : 'testing' }
TZealModule >> isModule [ ^ true
]

{ #category : 'accessing' }
TZealModule >> usings [ ^ self zealNode usings
]
