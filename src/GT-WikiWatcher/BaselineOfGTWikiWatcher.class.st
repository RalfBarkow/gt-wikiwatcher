Class {
	#name : #BaselineOfGTWikiWatcher,
	#superclass : #BaselineOf,
	#category : #'GT-WikiWatcher'
}

{ #category : #'as yet unclassified' }
BaselineOfGTWikiWatcher >> baseline: spec [
	<baseline>
	spec for: #common do: [
		"Core package"
		spec package: 'GT-WikiWatcher'.

		"Groups"
		spec group: 'core'    with: #('GT-WikiWatcher').
		spec group: 'default' with: #('core') ].

]
