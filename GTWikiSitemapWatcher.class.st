Class {
	#name : #GTWikiSitemapWatcher,
	#superclass : #Object,
	#instVars : [
		'url',
		'history',
		'lastDiff'
	],
	#category : #'GT-WikiWatcher'
}

{ #category : #'instance creation' }
GTWikiSitemapWatcher class >> httpURL: aString [
	^ self new
		url: aString;
		yourself
]

{ #category : #fetching }
GTWikiSitemapWatcher >> fetchNow [
	| client resp text json snap |
	url ifNil: [ ^ self error: 'URL is nil' ].
	client := ZnClient new.
	client
		url: (ZnUrl fromString: url);
		accept: ZnMimeType applicationJson;
		signalProgress: false;
		timeout: 30;
		enforceHttpSuccess: false.  "we check ourselves"
	[ client get ] on: Error do: [ :e | ^ self error: 'Fetch failed: ', e messageText ].
	resp := client response.
	(resp isNil or: [ resp status isNil ]) ifTrue: [ ^ self error: 'No HTTP response' ].
	(resp isSuccess) ifFalse: [
		^ self error: 'HTTP ', resp status printString, ' ', resp statusLine reason ].
	text := resp hasEntity ifTrue: [ resp contents ] ifFalse: [ '' ].
	text := (text isString) ifTrue: [ text ] ifFalse: [ text asString ].
	text isEmpty ifTrue: [ ^ self error: 'Empty body' ].
	json := [ NeoJSONReader fromString: text ]
		on: Error do: [ :e | ^ self error: 'JSON parse failed: ', e messageText ].
	snap := GTWikiSitemapSnapshot fromJson: json.
	self history add: snap.
	lastDiff := (self history size > 1)
		ifTrue: [ GTWikiSitemapDiff
			between: (self history at: self history size - 1)
			and: snap ]
		ifFalse: [ GTWikiSitemapDiff between: nil and: snap ].
	^ snap
]

{ #category : #'gt-views' }
GTWikiSitemapWatcher >> gtDiffOn: aView [
	<gtView>
	self fetchIfEmpty.
	^ (self history size <= 1)
		ifTrue: [
			aView text
				title: 'Diff';
				priority: 2;
				text: [ 'Initial snapshot — no diff yet. Click "Fetch now" again to compute changes.' ] ]
		ifFalse: [
			aView columnedList
				title: 'Diff';
				priority: 2;
				items: [
					| now rows |
					now := DateAndTime now.
					rows :=
						(lastDiff added collect: [ :slug | { 'added'. slug. now } ]) ,
						(lastDiff updated collect: [ :slug |
							| nd |
							nd := ((self history last pages at: slug ifAbsent: [ Dictionary new ]) at: #date ifAbsent: [ nil ]).
							{ 'updated'. slug. nd } ]) ,
						(lastDiff removed collect: [ :slug | { 'removed'. slug. nil } ]).
					rows ];
				column: 'Change' text: [ :row | row first ];
				column: 'Slug'   text: [ :row | row second ];
				column: 'Date'   text: [ :row | | d | d := row third. d ifNil: [ '' ] ifNotNil: [ d asString ] ] ]
]

{ #category : #'gt-views' }
GTWikiSitemapWatcher >> gtHistoryOn: aView [
	<gtView>
	self fetchIfEmpty.
	^ aView list
		title: 'History';
		priority: 3;
		items: [ self history collect: #summaryString ]
]

{ #category : #'gt-views' }
GTWikiSitemapWatcher >> gtStatusOn: aView [
	<gtView>
	^ aView text
		title: 'Status';
		priority: 1;
		action: [ :act | 
			(act respondsTo: #button)
				ifTrue: [
					act button
						label: 'Fetch now';
						icon: (Smalltalk at: #BrGlamorousVectorIcons ifPresent: [ :i | i refresh ] ifAbsent: [ nil ]);
						action: [ self fetchNow ] ]
				ifFalse: [ ] ];
		text: [
			String streamContents: [ :s |
				s nextPutAll: 'URL: '; nextPutAll: (url ifNil: [ '—' ]); cr.
				s nextPutAll: 'Snapshots: '; nextPutAll: self history size asString; cr.
				self history isEmpty
					ifTrue: [ s nextPutAll: 'No snapshot yet. Click "Fetch now".' ]
					ifFalse: [
						self history size = 1
							ifTrue: [
								| n |
								n := self history last pages size.
								s nextPutAll: 'Initial snapshot — '; nextPutAll: n asString; nextPutAll: ' pages (baseline).' ]
							ifFalse: [
								s nextPutAll: 'Last diff — ';
								nextPutAll: lastDiff added size asString; nextPutAll: ' added, ';
								nextPutAll: lastDiff updated size asString; nextPutAll: ' updated, ';
								nextPutAll: lastDiff removed size asString; nextPutAll: ' removed.' ] ] ] ]
]

{ #category : #accessing }
GTWikiSitemapWatcher >> history [
	^ history ifNil: [ history := OrderedCollection new ]
]

{ #category : #initialization }
GTWikiSitemapWatcher >> initialize [
	super initialize.
	history := OrderedCollection new
]

{ #category : #accessing }
GTWikiSitemapWatcher >> lastDiff [
	^ lastDiff
]

{ #category : #printing }
GTWikiSitemapWatcher >> storeOn: aStream [
	aStream
		nextPutAll: '(GTWikiSitemapWatcher httpURL: ';
		nextPutAll: url storeString;
		nextPutAll: ')'
]

{ #category : #accessing }
GTWikiSitemapWatcher >> url [
	^ url
]

{ #category : #accessing }
GTWikiSitemapWatcher >> url: aString [
	url := aString.
	^ self
]
