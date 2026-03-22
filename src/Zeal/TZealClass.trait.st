Trait {
	#name : 'TZealClass',
	#traits : 'TZealDefinition',
	#classTraits : 'TZealDefinition classTrait',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
TZealClass >> definitionKind [ ^ #class
]

{ #category : 'accessing' }
TZealClass >> fields [ ^ self zealNode fields
]

{ #category : 'accessing' }
TZealClass >> interfaces [ ^ self zealNode interfaces
]

{ #category : 'testing' }
TZealClass >> isVerseClass [ ^ true
]

{ #category : 'accessing' }
TZealClass >> methods [ ^ self zealNode methods
]

{ #category : 'accessing' }
TZealClass >> superclassName [ ^ self zealNode superclass
]
