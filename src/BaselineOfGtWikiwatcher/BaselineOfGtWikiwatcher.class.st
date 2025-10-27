Class {
	#name : #BaselineOfGtWikiwatcher,
	#superclass : #BaselineOf,
	#category : #BaselineOfGtWikiwatcher
}

{ #category : #baseline }
BaselineOfGtWikiwatcher >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'GtWikiwatcher'
		]
]
