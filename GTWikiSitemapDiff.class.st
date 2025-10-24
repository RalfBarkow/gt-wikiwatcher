Class {
	#name : #GTWikiSitemapDiff,
	#superclass : #Object,
	#instVars : [
		'added',
		'updated',
		'removed'
	],
	#category : #'GT-WikiWatcher'
}

{ #category : #computing }
GTWikiSitemapDiff class >> between: oldSnap and: newSnap [
	| old new add rem common upd |
	old := oldSnap ifNil: [ GTWikiSitemapSnapshot new pages: Dictionary new; yourself ].
	new := newSnap.
	add := new pages keys asSet copyWithoutAll: old pages keys.
	rem := old pages keys asSet copyWithoutAll: new pages keys.
	common := (new pages keys asSet) intersection: (old pages keys asSet).
	upd := common select: [ :k |
		| o n od nd |
		o := old pages at: k.
		n := new pages at: k.
		od := o at: #date ifAbsent: [ nil ].
		nd := n at: #date ifAbsent: [ nil ].
		od ~= nd ].
	^ self new
		added: add asArray;
		updated: upd asArray;
		removed: rem asArray;
		yourself
]

{ #category : #accessing }
GTWikiSitemapDiff >> added [
	^ added ifNil: [ #() ]
]

{ #category : #accessing }
GTWikiSitemapDiff >> added: aCollection [
	added := aCollection
]

{ #category : #accessing }
GTWikiSitemapDiff >> removed [
	^ removed ifNil: [ #() ]
]

{ #category : #accessing }
GTWikiSitemapDiff >> removed: aCollection [
	removed := aCollection
]

{ #category : #accessing }
GTWikiSitemapDiff >> updated [
	^ updated ifNil: [ #() ]
]

{ #category : #accessing }
GTWikiSitemapDiff >> updated: aCollection [
	updated := aCollection
]
