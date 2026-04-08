Class {
	#name : 'GDScriptTheme',
	#superclass : 'Object',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'colors' }
GDScriptTheme class >> backgroundColor [
	^ GDZealTheme backgroundColor
]

{ #category : 'colors' }
GDScriptTheme class >> commentColor [
	^ Color fromHexString: 'A1A1BA'
]

{ #category : 'colors' }
GDScriptTheme class >> decoratorColor [
	"@export, @onready, @tool, @rpc, ..."
	^ Color fromHexString: 'F1FA8C'
]

{ #category : 'colors' }
GDScriptTheme class >> foregroundColor [
	^ GDZealTheme foregroundColor
]

{ #category : 'colors' }
GDScriptTheme class >> functionColor [
	"Function names in declarations and call sites"
	^ Color fromHexString: '50FA7B'
]

{ #category : 'highlighting' }
GDScriptTheme class >> highlight: aString [
	"Tokenize and colorize GDScript source, return a BlRopedText with attributes."
	| text i size |
	text := aString asRopedText.
	text foreground: self foregroundColor.
	i := 1.
	size := aString size.
	[ i <= size ] whileTrue: [
		i := self highlightTokenAt: i in: aString text: text size: size ].
	^ text
]

{ #category : 'highlighting' }
GDScriptTheme class >> highlightTokenAt: i in: aString text: text size: size [
	"Highlight one token starting at i, return next position."
	| ch start j word |
	ch := aString at: i.
	"Comments: hash to end of line"
	ch = $# ifTrue: [
		start := i. j := i.
		[ j <= size and: [ (aString at: j) ~= Character cr and: [ (aString at: j) ~= Character lf ] ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self commentColor.
		^ j ].
	"String literals: double or single quoted"
	(ch = $" or: [ ch = $' ]) ifTrue: [
		| quote |
		quote := ch.
		start := i. j := i + 1.
		[ j <= size and: [ (aString at: j) ~= quote ] ] whileTrue: [
			(aString at: j) = $\ ifTrue: [ j := j + 1 ]. j := j + 1 ].
		j <= size ifTrue: [ j := j + 1 ].
		(text from: start to: (j - 1 min: size)) foreground: self stringColor.
		^ j ].
	"Decorators: at-sign followed by identifier"
	ch = $@ ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ c = $_ ] ] ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self decoratorColor.
		^ j ].
	"Numbers: int, float, hex"
	(ch isDigit or: [ ch = $- and: [ i + 1 <= size and: [ (aString at: i + 1) isDigit ] ] ]) ifTrue: [
		start := i. j := i + 1.
		[ j <= size and: [ (aString at: j) isDigit or: [ '.xabcdefABCDEF_' includes: (aString at: j) ] ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self numberColor.
		^ j ].
	"Parens, brackets, braces"
	('()[]{}' includes: ch) ifTrue: [
		(text from: i to: i) foreground: self parenColor. ^ i + 1 ].
	"Identifiers, keywords, types"
	(ch isLetter or: [ ch = $_ ]) ifTrue: [
		start := i. j := i.
		[ j <= size and: [ | c | c := aString at: j. c isLetter or: [ c isDigit or: [ c = $_ ] ] ] ] whileTrue: [ j := j + 1 ].
		word := aString copyFrom: start to: j - 1.
		(self keywords includes: word) ifTrue: [
			(text from: start to: j - 1) foreground: self keywordColor. ^ j ].
		(self types includes: word) ifTrue: [
			(text from: start to: j - 1) foreground: self typeColor. ^ j ].
		"Function call or declaration: identifier followed by open paren"
		(j <= size and: [ (aString at: j) = $( ]) ifTrue: [
			(text from: start to: j - 1) foreground: self functionColor. ^ j ].
		^ j ].
	"Operator chars"
	('+-*/<>=!%&|^~' includes: ch) ifTrue: [
		start := i. j := i.
		[ j <= size and: [ '+-*/<>=!%&|^~' includes: (aString at: j) ] ] whileTrue: [ j := j + 1 ].
		(text from: start to: j - 1) foreground: self operatorColor.
		^ j ].
	^ i + 1
]

{ #category : 'colors' }
GDScriptTheme class >> keywordColor [
	"Control flow + declarations: func, var, if, etc."
	^ Color fromHexString: 'FF79C6'
]

{ #category : 'tokens' }
GDScriptTheme class >> keywords [
	"GDScript reserved words and control-flow keywords."
	^ #('and' 'as' 'assert' 'await' 'break' 'breakpoint' 'class' 'class_name' 'const'
	    'continue' 'elif' 'else' 'enum' 'extends' 'false' 'for' 'func' 'if' 'in' 'is'
	    'master' 'mastersync' 'match' 'namespace' 'not' 'null' 'or' 'pass' 'preload'
	    'puppet' 'puppetsync' 'remote' 'remotesync' 'return' 'self' 'setget' 'signal'
	    'static' 'super' 'true' 'var' 'when' 'while' 'yield')
]

{ #category : 'colors' }
GDScriptTheme class >> numberColor [
	^ Color fromHexString: 'ACDBFF'
]

{ #category : 'colors' }
GDScriptTheme class >> operatorColor [
	^ Color fromHexString: 'FF79C6'
]

{ #category : 'colors' }
GDScriptTheme class >> parenColor [
	^ Color fromHexString: '9580FF'
]

{ #category : 'colors' }
GDScriptTheme class >> stringColor [
	^ Color fromHexString: '94FFCD'
]

{ #category : 'colors' }
GDScriptTheme class >> typeColor [
	"Built-in types and class names: int, float, Array, Vector2, ..."
	^ Color fromHexString: '8BE9FD'
]

{ #category : 'tokens' }
GDScriptTheme class >> types [
	"Built-in GDScript and common Godot types."
	^ #('void' 'bool' 'int' 'float' 'String' 'StringName' 'NodePath' 'Variant'
	    'Array' 'Dictionary' 'PackedByteArray' 'PackedInt32Array' 'PackedInt64Array'
	    'PackedFloat32Array' 'PackedFloat64Array' 'PackedStringArray'
	    'PackedVector2Array' 'PackedVector3Array' 'PackedColorArray'
	    'Vector2' 'Vector2i' 'Vector3' 'Vector3i' 'Vector4' 'Vector4i'
	    'Rect2' 'Rect2i' 'Transform2D' 'Transform3D' 'Plane' 'Quaternion' 'AABB'
	    'Basis' 'Color' 'RID' 'Object' 'Callable' 'Signal'
	    'Node' 'Node2D' 'Node3D' 'Control' 'Resource' 'Reference' 'RefCounted'
	    'Sprite2D' 'Area2D' 'CollisionShape2D' 'Camera2D' 'CharacterBody2D'
	    'RigidBody2D' 'StaticBody2D' 'Tween' 'Timer' 'Label' 'Button' 'Texture2D'
	    'Component' 'Entity' 'System' 'Observer' 'QueryBuilder')
]
