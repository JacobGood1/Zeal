Class {
	#name : 'BaselineOfMyGtMcp',
	#superclass : 'BaselineOf',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'loading' }
BaselineOfMyGtMcp class >> loadLepiter [
	IceRepository registry  
		detect: [ :aRepository |
			aRepository name = 'MyGtMcp' ]
		ifFound: [ :aRepository | 
			| defaultDatabase currentProperties |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			currentProperties := defaultDatabase properties.
			currentProperties addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [
			self inform: 'Repository not found.' ]
]

{ #category : 'baseline' }
BaselineOfMyGtMcp >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'MyGtMcp'.
			spec package: 'Claude-MCP'
		]
]
