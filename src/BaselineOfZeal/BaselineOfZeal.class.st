Class {
	#name : 'BaselineOfZeal',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfZeal',
	#package : 'BaselineOfZeal'
}

{ #category : 'loading' }
BaselineOfZeal class >> loadLepiter [
	IceRepository registry  
		detect: [ :aRepository |
			aRepository name = 'Zeal' ]
		ifFound: [ :aRepository | 
			| defaultDatabase currentProperties |
			defaultDatabase := LeDatabasesRegistry defaultLogicalDatabase.
			currentProperties := defaultDatabase properties.
			currentProperties addRegisteredDirectory: aRepository repositoryDirectory / 'lepiter'.
			defaultDatabase reload ]
		ifNone: [
			self inform: 'Zeal repository not found.' ]
]

{ #category : 'baselines' }
BaselineOfZeal >> baseline: spec [
	<baseline>
	
	^ spec for: #common do: [
		spec package: 'Claude-MCP'.
		spec package: 'MyGtMcp' with: [ spec requires: #('Claude-MCP') ].
		spec package: 'Zeal' with: [ spec requires: #('MyGtMcp') ].
		spec postLoadDoIt: #postLoad
	]
]

{ #category : 'loading' }
BaselineOfZeal >> postLoad [
	self class loadLepiter
]
