Class {
	#name : #GTWikiSitemapSnapshot,
	#superclass : #Object,
	#instVars : [
		'takenAt',
		'pages',
		'raw'
	],
	#category : #'GT-WikiWatcher'
}

{ #category : #'instance creation' }
GTWikiSitemapSnapshot class >> fromJson: aJson [
	| snap norm items |
	snap := self new.
	snap takenAt: DateAndTime now.
	norm := (aJson isArray
		ifTrue: [ aJson ]
		ifFalse: [
			(aJson at: #sitemap ifAbsent: [
				aJson at: 'sitemap' ifAbsent: [
					(aJson at: #pages ifAbsent: [
						aJson at: 'pages' ifAbsent: [ #() ] ]) ] ]) ]) asOrderedCollection.
	items := Dictionary new.
	norm do: [ :each |
		| slug title dateVal dateObj entry |
		slug := each at: #slug ifAbsent: [ each at: 'slug' ifAbsent: [ nil ] ].
		slug ifNotNil: [
			title := each at: #title ifAbsent: [ each at: 'title' ifAbsent: [ slug ] ].
			dateVal := each at: #date ifAbsent: [ each at: 'date' ifAbsent: [ nil ] ].
			dateObj := ((dateVal isNil) or: [ dateVal = '' ])
				ifTrue: [ nil ]
				ifFalse: [
					dateVal isNumber
						ifTrue: [
							| seconds |
							seconds := dateVal > 10000000000 ifTrue: [ dateVal / 1000 ] ifFalse: [ dateVal ].
							DateAndTime fromUnixTime: seconds ]
						ifFalse: [
							(dateVal respondsTo: #readStream)
								ifTrue: [ [ DateAndTime readFrom: dateVal readStream ] on: Error do: [ nil ] ]
								ifFalse: [ nil ] ] ].
			entry := Dictionary new
				at: #slug put: slug;
				at: #title put: title;
				at: #date put: dateObj;
				yourself.
			items at: slug put: entry ] ].
	snap pages: items.
	snap raw: aJson.
	^ snap
]

{ #category : #accessing }
GTWikiSitemapSnapshot >> pages [
	^ pages ifNil: [ pages := Dictionary new ]
]

{ #category : #accessing }
GTWikiSitemapSnapshot >> pages: aDict [
	pages := aDict
]

{ #category : #accessing }
GTWikiSitemapSnapshot >> raw [
	^ raw
]

{ #category : #accessing }
GTWikiSitemapSnapshot >> raw: aJson [
	raw := aJson
]

{ #category : #printing }
GTWikiSitemapSnapshot >> summaryString [
	^ String streamContents: [ :s |
		s nextPutAll: (takenAt ifNil: [ '—' ]) asString;
		  nextPutAll: ' — ';
		  nextPutAll: pages size asString;
		  nextPutAll: ' pages' ]
]

{ #category : #accessing }
GTWikiSitemapSnapshot >> takenAt [
	^ takenAt
]

{ #category : #accessing }
GTWikiSitemapSnapshot >> takenAt: aDateAndTime [
	takenAt := aDateAndTime
]
