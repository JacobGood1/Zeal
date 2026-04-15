Class {
	#name : 'GodotZealCompileResult',
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
GodotZealCompileResult >> definitionName [
	^ definitionName
]

{ #category : 'accessing' }
GodotZealCompileResult >> definitionName: aName [
	definitionName := aName
]

{ #category : 'accessing' }
GodotZealCompileResult >> gdPath [
	^ gdPath
]

{ #category : 'accessing' }
GodotZealCompileResult >> gdPath: aPath [
	gdPath := aPath
]

{ #category : 'accessing' }
GodotZealCompileResult >> generated [
	^ generated
]

{ #category : 'accessing' }
GodotZealCompileResult >> generated: aString [
	generated := aString
]

{ #category : 'gt-views' }
GodotZealCompileResult >> gtCompiledFor: aView [
	<gtView>
	^ aView textEditor
		title: 'GDScript';
		priority: 20;
		styler: GDScriptTextStyler new;
		text: [ generated ifNil: [ '' ] ];
		actionUpdateButton
]

{ #category : 'gt-views' }
GodotZealCompileResult >> gtMetaFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
GodotZealCompileResult >> gtPrintFor: aView [
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
GodotZealCompileResult >> gtRawFor: aView [
	"Hide the inherited Raw view — this object is meant to show only its
	 GDZeal source and GDScript views."
	<gtView>
	^ aView empty
]

{ #category : 'gt-views' }
GodotZealCompileResult >> gtSourceFor: aView [
	<gtView>
	^ aView textEditor
		title: 'GDZeal source';
		priority: 10;
		styler: GodotZealTextStyler new;
		text: [ source ifNil: [ '' ] ];
		actionUpdateButton
]

{ #category : 'accessing' }
GodotZealCompileResult >> source [
	^ source
]

{ #category : 'accessing' }
GodotZealCompileResult >> source: aString [
	source := aString
]
