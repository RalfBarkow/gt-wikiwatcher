Class {
	#name : #BaselineOfGtWikiWatcher,
	#superclass : #BaselineOf,
	#category : #BaselineOfGtWikiWatcher
}

{ #category : #baseline }
BaselineOfGtWikiWatcher >> baseline: spec [
	<baseline>
		^ spec for: #common do: [
			spec package: 'GtWikiWatcher'
		]
]
