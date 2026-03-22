Trait {
	#name : 'TZealVariable',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealVariable >> definitionKind [ ^ #variable
]

{ #category : 'accessing' }
TZealVariable >> isMutable [ ^ self zealNode isMutable
]

{ #category : 'testing' }
TZealVariable >> isVariable [ ^ true
]

{ #category : 'accessing' }
TZealVariable >> value [ ^ self zealNode value
]
