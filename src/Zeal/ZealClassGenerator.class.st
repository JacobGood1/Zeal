Class {
	#name : 'ZealClassGenerator',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'naming' }
ZealClassGenerator class >> classNameFor: aZealNode module: mod namespace: ns [
	"Generate class name: Zeal_ModuleName_Namespace_Definition
	 e.g., Zeal_LearnVerse_Console_ConsoleDevice"
	| modulePart nsPart defPart |
	modulePart := self toPascalCase: mod name.
	nsPart := self toPascalCase: ns name.
	defPart := self toPascalCase: aZealNode name.
	^ 'Zeal_' , modulePart , '_' , nsPart , '_' , defPart
]

{ #category : 'naming' }
ZealClassGenerator class >> classNameFor: aZealNode namespace: nsName [
	"Generate a Smalltalk class name from namespace + definition name.
	 e.g., namespace 'utils', name 'GatherWordsBySpaces' -> 'Zv_Utils_GatherWordsBySpaces'"
	| safeName safeNs |
	safeNs := self toPascalCase: nsName.
	safeName := self toPascalCase: aZealNode name.
	^ 'Zv_' , safeNs , '_' , safeName
]

{ #category : 'generating' }
ZealClassGenerator class >> ensureClass: className superclass: superclass trait: aTrait package: packageName [
	"Create or update a class with optional trait."

	| cls |
	cls := Smalltalk
			at: className asSymbol
			ifAbsent: [ aTrait
					ifNotNil: [ superclass classInstaller
							make: [ :builder | 
								builder
									superclass: superclass;
									name: className asSymbol;
									slotsFromString: '';
									sharedVariablesFromString: '';
									traitComposition: aTrait;
									package: packageName;
									environment: superclass environment ] ]
					ifNil: [ superclass
							subclass: className asSymbol
							instanceVariableNames: ''
							classVariableNames: ''
							package: packageName ] ].
	^ cls
]

{ #category : 'generating' }
ZealClassGenerator class >> generateClass: aZealNode module: mod namespace: ns package: packageName [
	"Generate a Smalltalk class for a top-level Zeal definition."
	| className cls |
	(aZealNode respondsTo: #name) ifFalse: [ ^ nil ].
	aZealNode name ifNil: [ ^ nil ].
	className := self classNameFor: aZealNode module: mod namespace: ns.
	
	cls := Smalltalk at: className asSymbol ifAbsent: [
		ZealDefinitionClass subclass: className asSymbol
			instanceVariableNames: ''
			classVariableNames: ''
			package: packageName ].
	
	cls class compile: ('zealSource
	^ ' , aZealNode compileToVerse printString) classified: 'zeal'.
	cls class compile: ('definitionKind
	^ ' , (self kindOf: aZealNode) printString) classified: 'zeal'.
	cls class compile: ('namespace
	^ ' , ns name printString) classified: 'zeal'.
	cls class compile: ('moduleName
	^ ' , mod name printString) classified: 'zeal'.
	cls class compile: ('default
	^ self new zealNode: (ZealCompiler fromVerse: self zealSource)') classified: 'instance creation'.
	
	^ cls
]

{ #category : 'generating' }
ZealClassGenerator class >> generateClass: aZealNode namespace: nsName package: packageName [
	"Generate a Smalltalk class for a top-level Zeal definition."
	| className cls instance |
	(aZealNode respondsTo: #name) ifFalse: [ ^ nil ].
	aZealNode name ifNil: [ ^ nil ].
	className := self classNameFor: aZealNode namespace: nsName.
	
	"Create or update the class"
	cls := Smalltalk at: className asSymbol ifAbsent: [
		ZealDefinitionClass subclass: className asSymbol
			instanceVariableNames: ''
			classVariableNames: ''
			package: packageName ].
	
	"Store the Zeal source as a class-side method"
	cls class compile: ('zealSource
	^ ' , aZealNode compileToVerse printString) classified: 'zeal'.
	
	"Store the definition kind"
	cls class compile: ('definitionKind
	^ ' , (self kindOf: aZealNode) printString) classified: 'zeal'.
	
	"Store the namespace"
	cls class compile: ('namespace
	^ ' , nsName printString) classified: 'zeal'.
	
	"Create a default instance with the node"
	instance := cls new zealNode: aZealNode.
	cls class compile: ('default
	^ self new zealNode: (ZealCompiler fromVerse: self zealSource)') classified: 'instance creation'.
	
	^ cls
]

{ #category : 'generating' }
ZealClassGenerator class >> generateDef: aZealNode parent: parentClass package: packageName [
	"Generate a definition class with the appropriate trait."
	| className trait cls |
	(aZealNode respondsTo: #name) ifFalse: [ ^ nil ].
	aZealNode name ifNil: [ ^ nil ].
	
	className := parentClass name , '_' , (self toPascalCase: aZealNode name).
	trait := self traitFor: aZealNode.
	
	cls := self ensureClass: className superclass: parentClass trait: trait package: packageName.
	
	cls class compile: ('zealSource
	^ ' , aZealNode compileToVerse printString) classified: 'zeal'.
	
	cls class compile: 'default
	| result |
	result := ZealCompiler fromVerse: self zealSource.
	(result isKindOf: Collection) ifTrue: [ result := result first ].
	^ self new zealNode: result' classified: 'instance creation'.
	
	^ cls
]

{ #category : 'generating' }
ZealClassGenerator class >> generateFromProject: aZealProject [
	"Generate a class hierarchy mirroring the project structure.
	 Project -> Module -> Namespace -> Definitions (with traits)"
	| packageName projectClass generated |
	packageName := 'ZealProject-' , (aZealProject name copyReplaceAll: ' ' with: '').
	
	"Create project root class"
	projectClass := self ensureClass: ('Zeal_' , (self toPascalCase: aZealProject name))
		superclass: ZealDefinitionClass
		trait: nil
		package: packageName.
	
	generated := OrderedCollection new.
	generated add: projectClass.
	
	aZealProject modules do: [:mod |
		| moduleClass |
		moduleClass := self ensureClass: (projectClass name , '_' , (self toPascalCase: mod name))
			superclass: projectClass
			trait: TZealModule
			package: packageName.
		generated add: moduleClass.
		
		mod definitions do: [:ns |
			(ns isKindOf: ZealModule) ifTrue: [
				| nsClass |
				nsClass := self ensureClass: (moduleClass name , '_' , (self toPascalCase: ns name))
					superclass: moduleClass
					trait: TZealNamespace
					package: packageName.
				generated add: nsClass.
				
				ns definitions do: [:def |
					(def isKindOf: ZealCompileError) ifFalse: [
						| defClass |
						defClass := self generateDef: def parent: nsClass package: packageName.
						defClass ifNotNil: [ generated add: defClass ] ] ] ] ] ].
	^ generated
]

{ #category : 'naming' }
ZealClassGenerator class >> kindOf: aZealNode [
	(aZealNode isKindOf: ZealFunction) ifTrue: [ ^ #function ].
	(aZealNode isKindOf: ZealClass) ifTrue: [ ^ #class ].
	(aZealNode isKindOf: ZealStruct) ifTrue: [ ^ #struct ].
	(aZealNode isKindOf: ZealEnum) ifTrue: [ ^ #enum ].
	(aZealNode isKindOf: ZealInterface) ifTrue: [ ^ #interface ].
	(aZealNode isKindOf: ZealVariable) ifTrue: [ ^ #variable ].
	(aZealNode isKindOf: ZealModule) ifTrue: [ ^ #module ].
	^ #unknown
]

{ #category : 'naming' }
ZealClassGenerator class >> toPascalCase: aString [
	^ String streamContents: [:s |
		| capitalize |
		capitalize := true.
		aString do: [:ch |
			(ch = $- or: [ch = $_]) 
				ifTrue: [ capitalize := true ]
				ifFalse: [
					capitalize
						ifTrue: [ s nextPut: ch asUppercase. capitalize := false ]
						ifFalse: [ s nextPut: ch ] ] ] ]
]

{ #category : 'naming' }
ZealClassGenerator class >> traitFor: aZealNode [
	(aZealNode isKindOf: ZealFunction) ifTrue: [ ^ TZealFunction ].
	(aZealNode isKindOf: ZealClass) ifTrue: [ ^ TZealClass ].
	(aZealNode isKindOf: ZealStruct) ifTrue: [ ^ TZealStruct ].
	(aZealNode isKindOf: ZealEnum) ifTrue: [ ^ TZealEnum ].
	(aZealNode isKindOf: ZealInterface) ifTrue: [ ^ TZealInterface ].
	(aZealNode isKindOf: ZealVariable) ifTrue: [ ^ TZealVariable ].
	(aZealNode isKindOf: ZealModule) ifTrue: [ ^ TZealModule ].
	^ nil
]
