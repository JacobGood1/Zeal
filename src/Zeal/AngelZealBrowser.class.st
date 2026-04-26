Class {
	#name : 'AngelZealBrowser',
	#superclass : 'ZealBrowser',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealBrowser class >> openFolder: aPathString [
	"Open the AngelZeal browser on a folder."
	| project browser space pager |
	project := AngelZealProject new scanFolder: aPathString asFileReference.
	browser := self new.
	browser project: project.
	pager := GtPager createWrappedOn: browser.
	pager background: ZealTheme backgroundColor.
	space := BlSpace new.
	space title: 'AngelZeal // ' , project name.
	space extent: 1200 @ 800.
	space root background: ZealTheme backgroundColor.
	space root addChild: pager.
	space show.
	^ browser
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectCompiler [
	^ AngelZealCompiler
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectDefinitionNodeClass [
	^ AngelZealDefinitionNode
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectFileNodeClass [
	^ AngelZealFileNode
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectInferType: aNode [
	^ AngelZealTypeInferencer default inferTypeFor: aNode
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectProjectClass [
	^ AngelZealProject
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectTargetExtension [
	^ '.as'
]

{ #category : 'dialect-hooks' }
AngelZealBrowser >> dialectTargetLabel [
	^ 'AngelScript'
]

{ #category : 'api' }
AngelZealBrowser >> themeClass [
	^ AngelZealTheme
]
