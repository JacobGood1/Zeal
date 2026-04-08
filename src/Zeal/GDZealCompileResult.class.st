Class {
	#name : 'GDZealCompileResult',
	#superclass : 'Object',
	#instVars : [
		'definitionName',
		'source',
		'generated',
		'gdPath'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
GDZealCompileResult >> definitionName [
	^ definitionName
]

{ #category : 'accessing' }
GDZealCompileResult >> definitionName: aName [
	definitionName := aName
]

{ #category : 'accessing' }
GDZealCompileResult >> gdPath [
	^ gdPath
]

{ #category : 'accessing' }
GDZealCompileResult >> gdPath: aPath [
	gdPath := aPath
]

{ #category : 'accessing' }
GDZealCompileResult >> generated [
	^ generated
]

{ #category : 'accessing' }
GDZealCompileResult >> generated: aString [
	generated := aString
]

{ #category : 'gt-views' }
GDZealCompileResult >> gtCompiledFor: aView [
	<gtView>
	^ aView textEditor
		title: 'GDScript';
		priority: 20;
		text: [ generated ifNil: [ '' ] ];
		actionUpdateButton
]

{ #category : 'gt-views' }
GDZealCompileResult >> gtMetaFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
GDZealCompileResult >> gtPrintFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
GDZealCompileResult >> gtRawFor: aView [
	"Hide the inherited Raw view — this object is meant to show only its
	 GDZeal source and GDScript views."
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
GDZealCompileResult >> gtSourceFor: aView [
	<gtView>
	^ aView textEditor
		title: 'GDZeal source';
		priority: 10;
		styler: GDZealTextStyler new;
		text: [ source ifNil: [ '' ] ];
		actionUpdateButton
]

{ #category : 'accessing' }
GDZealCompileResult >> source [
	^ source
]

{ #category : 'accessing' }
GDZealCompileResult >> source: aString [
	source := aString
]
