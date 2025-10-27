Class {
	#name : #BaselineOfGtWikiwatcher,
	#superclass : #BaselineOf,
	#category : #BaselineOfGtWikiWatcher
}

{ #category : #baseline }
BaselineOfGtWikiwatcher >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'GtWikiWatcher'
		]
]
