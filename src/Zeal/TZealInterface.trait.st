Trait {
	#name : 'TZealInterface',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealInterface >> definitionKind [ ^ #interface
]

{ #category : 'testing' }
TZealInterface >> isInterface [ ^ true
]

{ #category : 'accessing' }
TZealInterface >> methods [ ^ self zealNode methods
]

{ #category : 'accessing' }
TZealInterface >> parents [ ^ self zealNode parents
]
