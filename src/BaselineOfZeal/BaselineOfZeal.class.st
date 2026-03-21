Class {
	#name : 'BaselineOfZeal',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfZeal',
	#package : 'BaselineOfZeal'
}

{ #category : 'baseline' }
BaselineOfZeal >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'Zeal'
		]
]
