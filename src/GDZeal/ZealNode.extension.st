Extension { #name : 'ZealNode' }

{ #category : '*GDZeal' }
ZealNode >> compileToGDScript [
	"Compile this node to GDScript string.
	 Default: use rawSource through GDZealCodeGenerator"
	^ self compileToGDScript: (WriteStream on: String new) indent: 0
]

{ #category : '*GDZeal' }
ZealNode >> compileToGDScript: stream indent: level [
	"Default: emit rawSource or subclass override"
	rawSource ifNotNil: [
		stream nextPutAll: (GDZealCodeGenerator compile: rawSource).
		^ stream ].
	stream nextPutAll: '/* uncompilable: ' , self class name , ' */'.
	^ stream
]

{ #category : '*GDZeal' }
ZealNode >> gdScriptString [
	"Convenience: compile to GDScript and return string"
	^ (self compileToGDScript: (WriteStream on: String new) indent: 0) contents
]
