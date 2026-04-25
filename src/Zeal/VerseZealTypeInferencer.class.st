Class {
	#name : 'VerseZealTypeInferencer',
	#superclass : 'ZealTypeInferencer',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
VerseZealTypeInferencer >> knownTypes [
	"Verse / UEFN built-in types and the standard simulation types."
	^ self primitiveTypes ,
		#('agent' 'creative_object' 'creative_object_interface'
		  'fort_character' 'player' 'team' 'session'
		  'transform' 'vector3' 'vector2' 'rotation' 'color'
		  'message' 'comparable' 'subscribable')
]
