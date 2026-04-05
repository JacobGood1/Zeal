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
		spec package: 'Zeal'.
		spec package: 'GDZeal' with: [ spec requires: #('Zeal') ]
	]
]
