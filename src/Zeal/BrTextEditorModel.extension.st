Extension { #name : 'BrTextEditorModel' }

{ #category : '*Zeal' }
BrTextEditorModel >> deleter [
	"Extension: return ZealTextEditorDeleter which handles fn (lambda) token
	 deletion as a single unit, then delegates to super for everything else."
	^ ZealTextEditorDeleter new editor: self
]
