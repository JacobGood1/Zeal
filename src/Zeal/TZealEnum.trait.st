Trait {
	#name : 'TZealEnum',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealEnum >> definitionKind [ ^ #enum
]

{ #category : 'testing' }
TZealEnum >> isEnum [ ^ true
]

{ #category : 'accessing' }
TZealEnum >> values [ ^ self zealNode values
]
