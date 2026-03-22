Trait {
	#name : 'TZealFunction',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealFunction >> body [ ^ self zealNode body
]

{ #category : 'accessing' }
TZealFunction >> definitionKind [ ^ #function
]

{ #category : 'accessing' }
TZealFunction >> effects [ ^ self zealNode effects
]

{ #category : 'testing' }
TZealFunction >> isFunction [ ^ true
]

{ #category : 'accessing' }
TZealFunction >> parameters [ ^ self zealNode parameters
]
