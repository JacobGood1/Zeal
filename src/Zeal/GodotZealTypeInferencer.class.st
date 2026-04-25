Class {
	#name : 'GodotZealTypeInferencer',
	#superclass : 'ZealTypeInferencer',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
GodotZealTypeInferencer >> knownTypes [
	"Godot built-in / variant types."
	^ self primitiveTypes ,
		#('Vector2' 'Vector3' 'Vector2i' 'Vector3i' 'Vector4' 'Vector4i'
		  'Color' 'Rect2' 'Rect2i' 'Transform2D' 'Transform3D' 'Quaternion'
		  'Plane' 'AABB' 'Basis' 'Projection'
		  'NodePath' 'StringName' 'PackedScene' 'Resource'
		  'Object' 'RefCounted' 'Node' 'Node2D' 'Node3D' 'Control'
		  'Variant' 'Callable' 'Signal' 'Dictionary' 'Array')
]
