Class {
	#name : 'ZealDefinitionClass',
	#superclass : 'Object',
	#instVars : [
		'zealNode'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ZealDefinitionClass >> body [ ^ nil
]

{ #category : 'compiling' }
ZealDefinitionClass >> compileToVerse [ ^ zealNode compileToVerse
]

{ #category : 'accessing' }
ZealDefinitionClass >> definitionKind [ ^ #unknown
]

{ #category : 'accessing' }
ZealDefinitionClass >> definitions [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> effects [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> fields [ ^ nil
]

{ #category : 'views' }
ZealDefinitionClass >> gtVerseFor: aView [
	<gtView>
	^ aView textEditor
		title: 'Verse';
		text: [ self compileToVerse ]
]

{ #category : 'accessing' }
ZealDefinitionClass >> interfaces [ ^ nil
]

{ #category : 'testing' }
ZealDefinitionClass >> isEnum [ ^ false
]

{ #category : 'testing' }
ZealDefinitionClass >> isFunction [ ^ false
]

{ #category : 'testing' }
ZealDefinitionClass >> isInterface [ ^ false
]

{ #category : 'testing' }
ZealDefinitionClass >> isModule [ ^ false
]

{ #category : 'accessing' }
ZealDefinitionClass >> isMutable [ ^ nil
]

{ #category : 'testing' }
ZealDefinitionClass >> isNamespace [ ^ false
]

{ #category : 'testing' }
ZealDefinitionClass >> isStruct [ ^ false
]

{ #category : 'testing' }
ZealDefinitionClass >> isVariable [ ^ false
]

{ #category : 'testing' }
ZealDefinitionClass >> isVerseClass [ ^ false
]

{ #category : 'accessing' }
ZealDefinitionClass >> methods [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> name [ ^ zealNode name
]

{ #category : 'accessing' }
ZealDefinitionClass >> parameters [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> parents [ ^ nil
]

{ #category : 'printing' }
ZealDefinitionClass >> printOn: aStream [
	aStream nextPutAll: self class name.
	aStream nextPutAll: '('.
	aStream nextPutAll: self name asString.
	aStream nextPutAll: ')'
]

{ #category : 'accessing' }
ZealDefinitionClass >> superclassName [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> usings [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> value [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> values [ ^ nil
]

{ #category : 'accessing' }
ZealDefinitionClass >> zealNode [ ^ zealNode
]

{ #category : 'accessing' }
ZealDefinitionClass >> zealNode: aNode [ zealNode := aNode
]
