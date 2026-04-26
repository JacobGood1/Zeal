Class {
	#name : 'AngelZealProject',
	#superclass : 'Object',
	#instVars : [
		'name',
		'path',
		'rootFolder'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealProject >> buildTree [
	"Walk the project rootFolder and produce an AngelZealFolderNode tree mirroring
	 the filesystem. Each .as file becomes an AngelZealFileNode whose children
	 are AngelZealDefinitionNodes (one per `// @zeal` section). Definitions can
	 be reconstructed entirely from the file's metadata + Zeal source."
	| root |
	root := AngelZealFolderNode new fileRef: rootFolder.
	self populateFolderNode: root from: rootFolder.
	^ root
]

{ #category : 'api' }
AngelZealProject >> childrenOf: aFolder [
	"Folders + .as files. There are no .zeal files on disk — Zeal exists only
	 in `// @zeal` comment headers inside .as files and in the compiler."
	| dirs files children |
	children := [ aFolder children ] on: Error do: [ :e | #() ].
	dirs := (children select: [ :f | f isDirectory ])
		asSortedCollection: [ :a :b | a basename asLowercase < b basename asLowercase ].
	files := (children select: [ :f | f isFile and: [ f extension = 'as' ] ])
		asSortedCollection: [ :a :b | a basename asLowercase < b basename asLowercase ].
	^ (dirs asOrderedCollection) , (files asOrderedCollection)
]

{ #category : 'api' }
AngelZealProject >> name [
	^ name
]

{ #category : 'api' }
AngelZealProject >> name: aString [
	name := aString
]

{ #category : 'api' }
AngelZealProject >> nameOfForm: aFormSource [
	"Return the bare name of a top-level Zeal form, or nil. Mirrors the
	 same helper on AngelZealBrowser so the project can build trees
	 independently."
	| ast top exprs nameNode |
	ast := [ ZealParser parse: aFormSource ] on: Error do: [ :e | ^ nil ].
	(ast notNil and: [ ast expressions notEmpty ]) ifFalse: [ ^ nil ].
	top := ast expressions first.
	(top isKindOf: ZealListNode) ifFalse: [ ^ nil ].
	exprs := top expressions.
	exprs size < 2 ifTrue: [ ^ nil ].
	nameNode := exprs second.
	(nameNode isKindOf: ZealColonChainNode) ifTrue: [
		^ (ZealColonChainResolver resolve: nameNode value value) at: #name ].
	(nameNode isKindOf: ZealSymbolNode) ifTrue: [ ^ nameNode value value ].
	^ nil
]

{ #category : 'api' }
AngelZealProject >> path [
	^ path
]

{ #category : 'api' }
AngelZealProject >> path: aString [
	path := aString
]

{ #category : 'api' }
AngelZealProject >> populateFileNode: aFileNode [
	"Read aFileNode's underlying file, parse @zeal sections, and add one
	 AngelZealDefinitionNode per section. Files without headers get a single
	 placeholder node holding the raw target code."
	| content sections |
	content := [ aFileNode fileRef contents ] on: Error do: [ :e | '' ].
	sections := AngelZealCompiler parseSections: content.
	sections do: [ :section |
		| defNode |
		defNode := AngelZealDefinitionNode new
			zealSource: (section at: #zealSource);
			targetCode: (section at: #targetCode);
			metadata: (section at: #metadata);
			yourself.
		"Fall back to nameOfForm: if metadata didn't carry a name."
		defNode name ifNil: [
			defNode name: (self nameOfForm: defNode zealSource) ].
		aFileNode addChild: defNode ]
]

{ #category : 'api' }
AngelZealProject >> populateFolderNode: aFolderNode from: aDir [
	"Recurse into aDir, adding subfolders and .as files (as nodes) under
	 aFolderNode. Each .as file gets its definitions populated as children."
	| entries |
	entries := self childrenOf: aDir.
	entries do: [ :entry |
		entry isDirectory ifTrue: [
			| sub |
			sub := AngelZealFolderNode new fileRef: entry.
			aFolderNode addChild: sub.
			self populateFolderNode: sub from: entry ]
		ifFalse: [
			| fileNode |
			fileNode := AngelZealFileNode new fileRef: entry.
			aFolderNode addChild: fileNode.
			self populateFileNode: fileNode ] ]
]

{ #category : 'api' }
AngelZealProject >> rootFolder [
	^ rootFolder
]

{ #category : 'api' }
AngelZealProject >> scanFolder: aFileReference [
	"Attach the project to a root directory. No eager file enumeration — the
	 browser's tree walks the filesystem lazily via children."
	| ref |
	ref := aFileReference asFileReference.
	path := ref fullName.
	name := ref basename.
	rootFolder := ref.
	^ self
]
