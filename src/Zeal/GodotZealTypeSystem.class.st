Class {
	#name : 'GodotZealTypeSystem',
	#superclass : 'Object',
	#instVars : [
		'project',
		'resolver',
		'builtinTypes',
		'classDbCache',
		'projectTypes'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
GodotZealTypeSystem class >> forProject: aProject [
	^ self new project: aProject
]

{ #category : 'accessing' }
GodotZealTypeSystem >> builtinTypes [
	^ builtinTypes
]

{ #category : 'initialization' }
GodotZealTypeSystem >> initBuiltinTypes [
	"Register Godot variant types with their constants, properties, and methods.
	 Each type is a Dictionary with keys: #constants #properties #methods
	 Each member is name -> return type string."
	| v2 v3 v2i v3i color rect2 transform2d basis transform3d |
	
	v2 := Dictionary new
		at: #constants put: (Dictionary new
			at: 'ZERO' put: 'Vector2'; at: 'ONE' put: 'Vector2';
			at: 'UP' put: 'Vector2'; at: 'DOWN' put: 'Vector2';
			at: 'LEFT' put: 'Vector2'; at: 'RIGHT' put: 'Vector2';
			at: 'INF' put: 'Vector2'; yourself);
		at: #properties put: (Dictionary new
			at: 'x' put: 'float'; at: 'y' put: 'float'; yourself);
		at: #methods put: (Dictionary new
			at: 'abs' put: 'Vector2'; at: 'angle' put: 'float';
			at: 'angle_to' put: 'float'; at: 'angle_to_point' put: 'float';
			at: 'aspect' put: 'float'; at: 'bounce' put: 'Vector2';
			at: 'ceil' put: 'Vector2'; at: 'clamp' put: 'Vector2';
			at: 'cross' put: 'float'; at: 'direction_to' put: 'Vector2';
			at: 'distance_squared_to' put: 'float'; at: 'distance_to' put: 'float';
			at: 'dot' put: 'float'; at: 'floor' put: 'Vector2';
			at: 'is_normalized' put: 'bool'; at: 'is_zero_approx' put: 'bool';
			at: 'length' put: 'float'; at: 'length_squared' put: 'float';
			at: 'lerp' put: 'Vector2'; at: 'move_toward' put: 'Vector2';
			at: 'normalized' put: 'Vector2'; at: 'reflect' put: 'Vector2';
			at: 'rotated' put: 'Vector2'; at: 'round' put: 'Vector2';
			at: 'sign' put: 'Vector2'; at: 'slerp' put: 'Vector2';
			at: 'snapped' put: 'Vector2'; yourself);
		yourself.
	
	v3 := Dictionary new
		at: #constants put: (Dictionary new
			at: 'ZERO' put: 'Vector3'; at: 'ONE' put: 'Vector3';
			at: 'UP' put: 'Vector3'; at: 'DOWN' put: 'Vector3';
			at: 'LEFT' put: 'Vector3'; at: 'RIGHT' put: 'Vector3';
			at: 'FORWARD' put: 'Vector3'; at: 'BACK' put: 'Vector3';
			at: 'INF' put: 'Vector3'; yourself);
		at: #properties put: (Dictionary new
			at: 'x' put: 'float'; at: 'y' put: 'float'; at: 'z' put: 'float'; yourself);
		at: #methods put: (Dictionary new
			at: 'abs' put: 'Vector3'; at: 'ceil' put: 'Vector3';
			at: 'cross' put: 'Vector3'; at: 'direction_to' put: 'Vector3';
			at: 'distance_to' put: 'float'; at: 'dot' put: 'float';
			at: 'floor' put: 'Vector3'; at: 'length' put: 'float';
			at: 'length_squared' put: 'float'; at: 'lerp' put: 'Vector3';
			at: 'move_toward' put: 'Vector3'; at: 'normalized' put: 'Vector3';
			at: 'rotated' put: 'Vector3'; at: 'round' put: 'Vector3';
			at: 'sign' put: 'Vector3'; at: 'snapped' put: 'Vector3'; yourself);
		yourself.
	
	v2i := Dictionary new
		at: #constants put: (Dictionary new
			at: 'ZERO' put: 'Vector2i'; at: 'ONE' put: 'Vector2i';
			at: 'UP' put: 'Vector2i'; at: 'DOWN' put: 'Vector2i';
			at: 'LEFT' put: 'Vector2i'; at: 'RIGHT' put: 'Vector2i'; yourself);
		at: #properties put: (Dictionary new at: 'x' put: 'int'; at: 'y' put: 'int'; yourself);
		at: #methods put: (Dictionary new
			at: 'abs' put: 'Vector2i'; at: 'length' put: 'float';
			at: 'length_squared' put: 'int'; at: 'sign' put: 'Vector2i'; yourself);
		yourself.
	
	color := Dictionary new
		at: #constants put: (Dictionary new
			at: 'WHITE' put: 'Color'; at: 'BLACK' put: 'Color';
			at: 'RED' put: 'Color'; at: 'GREEN' put: 'Color';
			at: 'BLUE' put: 'Color'; at: 'TRANSPARENT' put: 'Color'; yourself);
		at: #properties put: (Dictionary new
			at: 'r' put: 'float'; at: 'g' put: 'float'; at: 'b' put: 'float'; at: 'a' put: 'float'; yourself);
		at: #methods put: (Dictionary new
			at: 'darkened' put: 'Color'; at: 'lightened' put: 'Color';
			at: 'lerp' put: 'Color'; at: 'inverted' put: 'Color'; yourself);
		yourself.

	builtinTypes
		at: 'Vector2' put: v2;
		at: 'Vector3' put: v3;
		at: 'Vector2i' put: v2i;
		at: 'Color' put: color.
	
	"Add aliases for @name syntax (lowercase)"
	builtinTypes at: 'vector2' put: v2.
	builtinTypes at: 'vector3' put: v3.
	builtinTypes at: 'vector2i' put: v2i.
	builtinTypes at: 'color' put: color
]

{ #category : 'initialization' }
GodotZealTypeSystem >> initialize [
	super initialize.
	builtinTypes := Dictionary new.
	classDbCache := Dictionary new.
	projectTypes := Dictionary new.
	self initBuiltinTypes
]

{ #category : 'resolution' }
GodotZealTypeSystem >> membersOf: typeName [
	"Return all known members of a type as name→returnType pairs.
	 Merges constants + properties + methods."
	| clean result |
	clean := typeName.
	(clean beginsWith: '@') ifTrue: [ clean := clean allButFirst ].
	result := Dictionary new.
	
	"Builtins"
	builtinTypes at: clean ifPresent: [ :typeInfo |
		(typeInfo at: #constants) keysAndValuesDo: [ :k :v | result at: k put: v ].
		(typeInfo at: #properties) keysAndValuesDo: [ :k :v | result at: k put: v ].
		(typeInfo at: #methods) keysAndValuesDo: [ :k :v | result at: k put: v ] ].
	
	"Project types"
	projectTypes at: clean ifPresent: [ :typeInfo |
		(typeInfo at: #members) keysAndValuesDo: [ :k :v | result at: k put: v ] ].
	
	"Via resolver"
	resolver ifNotNil: [
		| cls |
		cls := resolver findClass: clean.
		cls ifNotNil: [
			cls fields ifNotNil: [ :fields |
				fields do: [ :f | result at: f name put: (f type ifNil: [ 'Variant' ]) ] ].
			cls methods ifNotNil: [ :methods |
				methods do: [ :m | result at: m name put: ((m respondsTo: #returnType) 
					ifTrue: [ m returnType ifNil: [ 'void' ] ] ifFalse: [ 'void' ]) ] ] ] ].
	
	^ result
]

{ #category : 'accessing' }
GodotZealTypeSystem >> project [
	^ project
]

{ #category : 'accessing' }
GodotZealTypeSystem >> project: aProject [
	project := aProject.
	self scanProject
]

{ #category : 'accessing' }
GodotZealTypeSystem >> projectTypes [
	^ projectTypes
]

{ #category : 'scanning' }
GodotZealTypeSystem >> registerDefinition: aZealClass [
	"Register a definition with its type metadata."
	| info members |
	info := Dictionary new.
	info at: #name put: aZealClass name.
	info at: #kind put: (aZealClass annotations 
		ifNotNil: [ :anns | 
			(anns includes: 'gecs_component') ifTrue: [ #component ]
			ifFalse: [ (anns includes: 'gecs_entity') ifTrue: [ #entity ]
			ifFalse: [ (anns includes: 'gecs_system') ifTrue: [ #system ]
			ifFalse: [ (anns includes: 'gecs_observer') ifTrue: [ #observer ]
			ifFalse: [ #class ] ] ] ] ]
		ifNil: [ #class ]).
	info at: #node put: aZealClass.
	
	"Fields → typed members"
	members := Dictionary new.
	aZealClass fields ifNotNil: [ :fields |
		fields do: [ :f |
			members at: f name put: (f type ifNil: [ 'Variant' ]) ] ].
	info at: #members put: members.
	
	"Components for entities"
	(info at: #kind) = #entity ifTrue: [
		info at: #components put: (aZealClass fields 
			ifNotNil: [ :f | f collect: [ :each | each type ifNil: [ each name ] ] ]
			ifNil: [ #() ]) ].
	
	projectTypes at: aZealClass name put: info
]

{ #category : 'scanning' }
GodotZealTypeSystem >> rescan [
	"Re-scan the project after changes"
	self scanProject
]

{ #category : 'resolution' }
GodotZealTypeSystem >> resolveClassRef: aName [
	"Resolve @name to a type name. @vector2 → Vector2, @health → C_Health"
	| clean |
	clean := aName.
	(clean beginsWith: '@') ifTrue: [ clean := clean allButFirst ].
	"Check builtins first (case-insensitive)"
	builtinTypes at: clean ifPresent: [ :info | 
		^ self toPascalCase: clean ].
	"Check project types"
	projectTypes at: clean ifPresent: [ :info | 
		^ 'C_', (self toPascalCase: clean) ].
	"Return PascalCase as fallback"
	^ self toPascalCase: clean
]

{ #category : 'accessing' }
GodotZealTypeSystem >> resolver [
	^ resolver
]

{ #category : 'scanning' }
GodotZealTypeSystem >> scanProject [
	"Scan all project definitions and build type cache.
	 Components → fields with types.
	 Entities → component list.
	 Systems → parameter types."
	projectTypes := Dictionary new.
	project ifNil: [ ^ self ].
	resolver := ZealTypeResolver forProject: project.
	project modules valuesDo: [ :mod |
		mod definitions do: [ :defn |
			(defn isKindOf: ZealClass) ifTrue: [
				self registerDefinition: defn ] ] ]
]

{ #category : 'private' }
GodotZealTypeSystem >> toPascalCase: aString [
	"kebab-name → PascalName, vector2 → Vector2"
	^ '' join: ((aString substrings: '-') collect: [ :s | s capitalized ])
]

{ #category : 'resolution' }
GodotZealTypeSystem >> typeOfExpression: exprString [
	"Resolve the type of a GDZeal expression string.
	 @vector2/RIGHT → Vector2
	 health/current → float
	 @vector2 → Vector2"
	| parts head currentType |
	(exprString includes: $/) ifTrue: [
		parts := exprString substrings: '/'.
		head := parts first.
		"Chain resolution: resolve each part"
		currentType := (head beginsWith: '@')
			ifTrue: [ self resolveClassRef: head ]
			ifFalse: [ head ].
		parts allButFirst do: [ :member |
			| memberType |
			memberType := self typeOfMember: member on: currentType.
			memberType ifNotNil: [ currentType := memberType ] ].
		^ currentType ].
	
	"Bare @ref"
	(exprString beginsWith: '@') ifTrue: [
		^ self resolveClassRef: exprString ].
	
	"Check project types"
	projectTypes at: exprString ifPresent: [ :info |
		^ info at: #name ].
	
	^ nil
]

{ #category : 'resolution' }
GodotZealTypeSystem >> typeOfMember: memberName on: typeName [
	"Resolve the return type of a member access: type/member → return type.
	 Checks constants, properties, methods on builtins and project types."
	| clean info |
	clean := typeName.
	(clean beginsWith: '@') ifTrue: [ clean := clean allButFirst ].
	
	"Check builtins"
	builtinTypes at: clean ifPresent: [ :typeInfo |
		(typeInfo at: #constants) at: memberName ifPresent: [ :t | ^ t ].
		(typeInfo at: #properties) at: memberName ifPresent: [ :t | ^ t ].
		(typeInfo at: #methods) at: memberName ifPresent: [ :t | ^ t ] ].
	
	"Check project types"
	projectTypes at: clean ifPresent: [ :typeInfo |
		(typeInfo at: #members) at: memberName ifPresent: [ :t | ^ t ] ].
	
	"Check via resolver for inherited members"
	resolver ifNotNil: [
		| cls |
		cls := resolver findClass: clean.
		cls ifNotNil: [
			cls fields ifNotNil: [ :fields |
				fields do: [ :f | f name = memberName ifTrue: [ ^ f type ] ] ].
			cls methods ifNotNil: [ :methods |
				methods do: [ :m | m name = memberName ifTrue: [ 
					^ (m respondsTo: #returnType) ifTrue: [ m returnType ] ifFalse: [ nil ] ] ] ] ] ].
	
	^ nil
]
