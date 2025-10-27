Class {
	#name : #GtWikiSitemapDiff,
	#superclass : #Object,
	#instVars : [
		'added',
		'updated',
		'removed'
	],
	#category : #GtWikiWatcher
}

{ #category : #computing }
GtWikiSitemapDiff class >> between: oldSnap and: newSnap [
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
GtWikiSitemapDiff >> added [
	^ added ifNil: [ #() ]
]

{ #category : #accessing }
GtWikiSitemapDiff >> added: aCollection [
	added := aCollection
]

{ #category : #'as yet unclassified' }
GtWikiSitemapDiff >> fingerprint [
	^ { added size. updated size. removed size } hash.
]

{ #category : #'as yet unclassified' }
GtWikiSitemapDiff >> isEmpty [
	^ added isEmpty and: [ updated isEmpty and: [ removed isEmpty ] ].

]

{ #category : #accessing }
GtWikiSitemapDiff >> removed [
	^ removed ifNil: [ #() ]
]

{ #category : #accessing }
GtWikiSitemapDiff >> removed: aCollection [
	removed := aCollection
]

{ #category : #accessing }
GtWikiSitemapDiff >> updated [
	^ updated ifNil: [ #() ]
]

{ #category : #accessing }
GtWikiSitemapDiff >> updated: aCollection [
	updated := aCollection
]
