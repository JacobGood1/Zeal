Class {
	#name : 'ZealBrowser',
	#superclass : 'BlElement',
	#instVars : [
		'project',
		'treeElement',
		'detailElement',
		'selectedNode'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'opening' }
ZealBrowser class >> open [
	"Open Zeal launcher with themed folder picker."
	| space root titleLabel sampleBtn fileSelector |
	space := BlSpace new.
	space title: 'Zeal // Project Launcher'.
	space extent: 700@550.
	
	root := BlElement new.
	root layout: BlLinearLayout vertical.
	root constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	root background: ZealTheme backgroundColor.
	root padding: (BlInsets all: 20).
	
	titleLabel := BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme cursorColor; fontSize: 24; bold);
		text: 'ZEAL // PROJECT LAUNCHER'.
	root addChild: titleLabel.
	
	root addChild: (BlElement new constraintsDo: [:c | c horizontal matchParent. c vertical exact: 12 ]).
	
	sampleBtn := BrButton new
		aptitude: BrGlamorousButtonWithLabelAptitude;
		label: 'Open Sample Project';
		action: [ space close. self openSample ];
		margin: (BlInsets bottom: 16).
	root addChild: sampleBtn.
	
	root addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Select a UEFN project folder:';
		margin: (BlInsets bottom: 8)).
	
	fileSelector := ZealFileSelector new.
	fileSelector folder: FileLocator home asFileReference.
	fileSelector fileFilterBlock: [ :entry | entry isDirectory or: [ entry basename endsWith: '.verse' ] ].
	fileSelector okAction: [ :selected :btn |
		| ref |
		ref := selected asFileReference.
		ref isDirectory
			ifTrue: [ space close. self openFolder: ref fullName ]
			ifFalse: [ space close. self openFolder: ref parent fullName ] ].
	fileSelector buttonLabel: 'Scan Project'.
	fileSelector constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	fileSelector background: (ZealTheme backgroundColor lighter).
	root addChild: fileSelector.
	
	space root addChild: root.
	space show.
	^ space
]

{ #category : 'opening' }
ZealBrowser class >> openFolder: aPathString [
	| project |
	project := ZealProject new scanFolder: aPathString asFileReference.
	^ self openProject: project
]

{ #category : 'opening' }
ZealBrowser class >> openProject: aZealProject [
	| browser space |
	browser := self new.
	browser project: aZealProject.
	space := BlSpace new.
	space title: 'Zeal Browser // ' , aZealProject name.
	space extent: 1100@700.
	space root background: ZealTheme backgroundColor.
	space root layout: BlLinearLayout horizontal.
	space root addChild: browser.
	space show.
	^ browser
]

{ #category : 'opening' }
ZealBrowser class >> openSample [
	"Open a browser with a sample in-memory project for testing."
	| project mod1 mod2 |
	project := ZealProject new name: 'SampleGame'; path: '/SampleGame'.
	
	mod1 := ZealModule new name: 'Core'; kind: #folder; 
		usings: OrderedCollection new; definitions: OrderedCollection new.
	mod1 definitions add: (ZealCompiler compile: '(defstruct vector2 [x:float 0.0] [y:float 0.0])').
	mod1 definitions add: (ZealCompiler compile: '(defenum game-state main-menu playing paused game-over)').
	mod1 definitions add: (ZealCompiler compile: '(defn calculate-score:public:int [base:int bonus:int] (+ base (* bonus 2)))').
	mod1 definitions do: [:d | d parent: mod1].
	mod1 parent: project.
	
	mod2 := ZealModule new name: 'Characters'; kind: #folder;
		usings: OrderedCollection new; definitions: OrderedCollection new.
	mod2 definitions add: (ZealCompiler compile: '(defclass character:concrete (entity) (var health:int 100) (var level:int 1) (defn take-damage:void [amount:int] (set health (Max 0 (- health amount)))) (defn is-alive:decides:void (> health 0)))').
	mod2 definitions add: (ZealCompiler compile: '(defclass player:concrete (character) (var score:int 0) (defn add-score:void [points:int] (set score (+ score points))))').
	mod2 definitions do: [:d | d parent: mod2].
	mod2 parent: project.
	
	project modules add: mod1.
	project modules add: mod2.
	^ self openProject: project
]

{ #category : 'building' }
ZealBrowser >> buildDetail [
	detailElement := BlElement new.
	detailElement layout: BlLinearLayout vertical.
	detailElement constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	detailElement background: ZealTheme backgroundColor.
	detailElement padding: (BlInsets all: 12).
	self showWelcome.
	^ detailElement
]

{ #category : 'building' }
ZealBrowser >> buildTree [
	treeElement := BrSimpleTree new.
	treeElement
		nodeStencil: [ BrLabel new aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme foregroundColor) ];
		nodeDataBinder: [ :label :item | label text: (self labelFor: item) ];
		items: project modules lazy: [ :item | self childrenOf: item ];
		when: BrSelectionChanged do: [:event |
			event indices ifNotEmpty: [:indices |
				treeElement selectedNodeDo: [:treeNode |
					self selectNode: treeNode value ] ] ].
	treeElement background: (ZealTheme backgroundColor lighter).
	treeElement constraintsDo: [:c | c horizontal exact: 280. c vertical matchParent ].
	treeElement padding: (BlInsets all: 8).
	^ treeElement
]

{ #category : 'building' }
ZealBrowser >> buildUI [
	self removeChildren.
	self addChild: self buildTree.
	self addChild: self buildDetail
]

{ #category : 'building' }
ZealBrowser >> childrenOf: item [
	(item isKindOf: ZealModule) ifTrue: [ ^ item definitions ].
	(item isKindOf: ZealClass) ifTrue: [ ^ item fields , item methods ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ item fields ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ item methods ].
	^ #()
]

{ #category : 'actions' }
ZealBrowser >> compileAndSave: zealEditor forNode: aNode [
	| zealSource compiled verseSource namespace filePath genClass |
	zealSource := zealEditor editor text asString.
	
	[ compiled := ZealCompiler compile: zealSource ] on: Error do: [:e |
		self flashEditor: zealEditor color: (Color red alpha: 0.3). ^ self ].
	
	"Generate Verse with zeal comment"
	[ verseSource := compiled compileToVerseWithZealComment: zealSource ] on: Error do: [:e |
		self flashEditor: zealEditor color: (Color red alpha: 0.3). ^ self ].
	
	detailElement childWithId: #verseOutput ifFound: [:ve |
		ve text: (verseSource asRopedText foreground: ZealTheme foregroundColor) ].
	
	aNode rawSource: nil.
	
	genClass := self generatedClassFor: aNode.
	genClass ifNotNil: [
		genClass class compile: ('zealSource
	^ ' , zealSource printString) classified: 'zeal'.
		genClass class compile: ('verseSource
	^ ' , verseSource printString) classified: 'zeal' ].
	
	namespace := aNode module.
	namespace ifNotNil: [
		filePath := self verseFilePathFor: namespace.
		filePath ifNotNil: [ self writeNamespaceToFile: namespace path: filePath ] ].
	
	self flashEditor: zealEditor color: (ZealTheme cursorColor alpha: 0.2)
]

{ #category : 'actions' }
ZealBrowser >> flashEditor: anEditor color: aColor [
	"Flash the editor background briefly to indicate success/failure."
	| original |
	original := anEditor background.
	anEditor background: aColor.
	[ (Delay forMilliseconds: 300) wait.
	  anEditor enqueueTask: (BlTaskAction new action: [ anEditor background: original ]) ] fork
]

{ #category : 'detail' }
ZealBrowser >> generatedClassFor: aNode [
	"Find the generated Smalltalk class for a ZealNode by matching name"
	| name |
	(aNode respondsTo: #name) ifFalse: [ ^ nil ].
	name := aNode name ifNil: [ ^ nil ].
	^ Smalltalk allClassesAndTraits 
		detect: [:c | 
			(c name beginsWith: 'Zeal_') and: [
				c name endsWith: '_' , (ZealClassGenerator toPascalCase: name) ] ]
		ifNone: [ nil ]
]

{ #category : 'initialization' }
ZealBrowser >> initialize [
	super initialize.
	self layout: BlLinearLayout horizontal.
	self constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ].
	self background: ZealTheme backgroundColor
]

{ #category : 'building' }
ZealBrowser >> labelFor: item [
	(item isKindOf: ZealModule) ifTrue: [ 
		item kind = #file ifTrue: [ ^ 'namespace ' , item name ].
		^ item name ].
	(item isKindOf: ZealClass) ifTrue: [ 
		^ 'class ' , item name , (item superclass ifNotNil: [:p | '(' , p , ')'] ifNil: ['']) ].
	(item isKindOf: ZealStruct) ifTrue: [ ^ 'struct ' , item name ].
	(item isKindOf: ZealEnum) ifTrue: [ ^ 'enum ' , item name ].
	(item isKindOf: ZealInterface) ifTrue: [ ^ 'interface ' , item name ].
	(item isKindOf: ZealFunction) ifTrue: [
		^ 'fn ' , item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealVariable) ifTrue: [ 
		^ (item isMutable ifTrue: ['var '] ifFalse: ['val ']) , item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealField) ifTrue: [ 
		^ (item isMutable ifTrue: ['var '] ifFalse: ['']) , item name , (item type ifNotNil: [':' , item type] ifNil: ['']) ].
	(item isKindOf: ZealCompileError) ifTrue: [ ^ '! ' , (item message copyFrom: 1 to: (item message size min: 50)) ].
	^ item printString
]

{ #category : 'accessing' }
ZealBrowser >> project: aZealProject [
	project := aZealProject.
	self buildUI
]

{ #category : 'detail' }
ZealBrowser >> selectNode: aNode [
	| verseText zealText generatedClass zealEditor |
	selectedNode := aNode.
	detailElement removeChildren.
	
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme colonChainColor; fontSize: 18; bold);
		text: (self labelFor: aNode)).
	
	generatedClass := self generatedClassFor: aNode.
	
	"Editable Zeal source"
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme specialFormColor; fontSize: 12);
		text: 'Zeal (Ctrl+S to compile & save):';
		margin: (BlInsets top: 12 left: 0 bottom: 4 right: 0)).
	
	zealText := generatedClass 
		ifNotNil: [ generatedClass zealSource ]
		ifNil: [ [ aNode compileToZeal ] on: Error do: [:e | 'Error: ' , e messageText ] ].
	
	zealEditor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: (zealText asRopedText foreground: ZealTheme stringColor);
		background: (ZealTheme backgroundColor darker);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8).
	zealEditor addShortcut: (BlShortcutWithAction new 
		combination: BlKeyCombination primaryS;
		action: [ self compileAndSave: zealEditor forNode: aNode ]).
	detailElement addChild: zealEditor.
	
	"Read-only Verse output"
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Verse:';
		margin: (BlInsets top: 4 left: 0 bottom: 4 right: 0)).
	
	verseText := generatedClass
		ifNotNil: [ generatedClass verseSource ]
		ifNil: [ [ aNode compileToVerse ] on: Error do: [:e | 'Error: ' , e messageText ] ].
	detailElement addChild: (BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		text: (verseText asRopedText foreground: ZealTheme foregroundColor);
		background: (ZealTheme backgroundColor darker);
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		beReadOnlyWithSelection;
		padding: (BlInsets all: 8);
		margin: (BlInsets bottom: 8);
		id: #verseOutput).
	
	generatedClass ifNotNil: [
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 11);
			text: 'Smalltalk class: ' , generatedClass name;
			margin: (BlInsets top: 4)) ].
	
	(aNode isKindOf: ZealModule) ifTrue: [ self showModuleDetail: aNode ].
	(aNode isKindOf: ZealFunction) ifTrue: [ self showFunctionDetail: aNode ].
	(aNode isKindOf: ZealClass) ifTrue: [ self showClassDetail: aNode ].
	(aNode isKindOf: ZealEnum) ifTrue: [ self showEnumDetail: aNode ]
]

{ #category : 'detail' }
ZealBrowser >> showClassDetail: cls [
	cls superclass ifNotNil: [:p |
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme operatorColor; fontSize: 12);
			text: 'Superclass: ' , p) ].
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Fields: ' , cls fields size printString , '  Methods: ' , cls methods size printString)
]

{ #category : 'detail' }
ZealBrowser >> showEnumDetail: en [
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Values: ' , (en values joinUsing: ', '))
]

{ #category : 'detail' }
ZealBrowser >> showFunctionDetail: func [
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Parameters:').
	func parameters do: [:p |
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme symbolColor);
			text: '  ' , p name , (p type ifNotNil: [':' , p type] ifNil: ['']);
			margin: (BlInsets left: 12)) ]
]

{ #category : 'detail' }
ZealBrowser >> showModuleDetail: mod [
	mod usings notEmpty ifTrue: [
		detailElement addChild: (BrLabel new
			aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
			text: 'Usings:';
			margin: (BlInsets top: 8 bottom: 4)).
		mod usings do: [:u |
			detailElement addChild: (BrLabel new
				aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme keywordColor);
				text: '  ' , u path;
				margin: (BlInsets left: 12)) ] ].
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 12);
		text: 'Definitions: ' , mod definitions size printString , ' (' , (mod definitions select: [:d | d isKindOf: ZealCompileError]) size printString , ' errors)';
		margin: (BlInsets top: 8))
]

{ #category : 'detail' }
ZealBrowser >> showWelcome [
	detailElement removeChildren.
	detailElement addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: ZealTheme commentColor; fontSize: 16);
		text: 'Select a definition to view details')
]

{ #category : 'actions' }
ZealBrowser >> verseFilePathFor: aNamespace [
	"Find the .verse file path for a namespace (ZealModule kind: #file)."
	| dir files |
	((aNamespace isKindOf: ZealModule) and: [aNamespace kind = #file]) ifFalse: [ ^ nil ].
	project ifNil: [ ^ nil ].
	dir := project path asFileReference.
	files := dir allFiles select: [:f | 
		f extension = 'verse' and: [f basenameWithoutExtension = aNamespace name] ].
	files ifEmpty: [ ^ nil ] ifNotEmpty: [ ^ files first fullName ]
]

{ #category : 'actions' }
ZealBrowser >> writeNamespaceToFile: aNamespace path: filePath [
	"Write all definitions in a namespace to the .verse file."
	| stream |
	stream := String new writeStream.
	"Write usings first"
	aNamespace usings do: [:u |
		stream nextPutAll: 'using { '; nextPutAll: u path; nextPutAll: ' }'.
		stream cr ].
	aNamespace usings notEmpty ifTrue: [ stream cr ].
	"Write each definition's verse source"
	aNamespace definitions do: [:d |
		d compileToVerse: stream indent: 0.
		stream cr; cr ].
	filePath asFileReference writeStreamDo: [:ws | ws nextPutAll: stream contents ]
]
