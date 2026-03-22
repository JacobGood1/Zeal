Trait {
	#name : 'TZealStruct',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealStruct >> definitionKind [ ^ #struct
]

{ #category : 'accessing' }
TZealStruct >> fields [ ^ self zealNode fields
]

{ #category : 'testing' }
TZealStruct >> isStruct [ ^ true
]
