Class {
	#name : 'AngelZealDefinitionNode',
	#superclass : 'ZealDefinitionNode',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'view-hooks' }
AngelZealDefinitionNode >> targetStyler [
	"Styler used by gtSourceTargetFor: to colorize the compiled target source.
	 Each dialect overrides to return its own BlTextStyler. Returning nil
	 falls back to plain text."
	^ AngelScriptStyler new
]
