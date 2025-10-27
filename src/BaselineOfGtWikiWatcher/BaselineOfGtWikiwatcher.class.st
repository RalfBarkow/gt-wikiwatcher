Class {
	#name : #BaselineOfGtWikiWatcher,
	#superclass : #BaselineOf,
	#category : #BaselineOfGtWikiWatcher
}

{ #category : #baseline }
BaselineOfGtWikiWatcher >> baseline: spec [
  <baseline>
  spec for: #common do: [

    "External dependency: provides class `Wiki` used by GtWikiSitemapWatcher>>sitemapFile"
    spec package: 'Federated-Wiki' with: [
      spec repository: 'github://RalfBarkow/fedwiki-smalltalk:main/src' ].

    "This repo"
    spec package: 'GtWikiWatcher' with: [
      spec requires: #('Federated-Wiki') ].

    "Groups"
    spec group: 'core'    with: #('GtWikiWatcher').
    spec group: 'default' with: #('core').
    spec group: 'dev'     with: #('default') ].
]
