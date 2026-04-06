Class {
	#name : 'BaselineOfZeal',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfZeal',
	#package : 'BaselineOfZeal'
}

{ #category : 'baselines' }
BaselineOfZeal >> baseline: spec [
	<baseline>
	
	^ spec for: #common do: [
		spec package: 'Claude-MCP'.
		spec package: 'MyGtMcp' with: [ spec requires: #('Claude-MCP') ].
		spec package: 'Zeal' with: [ spec requires: #('MyGtMcp') ]
	]
]
