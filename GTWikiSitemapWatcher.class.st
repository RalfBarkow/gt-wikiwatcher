Class {
	#name : #GTWikiSitemapWatcher,
	#superclass : #Object,
	#instVars : [
		'url',
		'history',
		'lastDiff',
		'host'
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
GTWikiSitemapWatcher >> fetchIfEmpty [
	"Backward-compatibility no-op. Views no longer auto-fetch."
	^ self
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

{ #category : #fetching }
GTWikiSitemapWatcher >> fetchNowAsyncWithTranscript [
	"Run fetchNow in the background and stream progress to a transcript."
	self openTranscriptIfAvailable.
	[
		| t0 |
		self log: ('=== Fetch start: ' , url).
		t0 := DateAndTime now.
		[
			self log: 'GET…'.
			self fetchNow.
			self log: ('OK — snapshots: ' , self history size asString ,
				' | +' , lastDiff added size asString ,
				' / ~' , lastDiff updated size asString ,
				' / -' , lastDiff removed size asString).
		] on: Error do: [ :e |
			self log: ('ERROR: ' , e messageText).
		].
		self log: ('Finished in ' , ((DateAndTime now - t0) asDuration printString)).
	] forkAt: Processor userBackgroundPriority
]

{ #category : #'gt-views' }
GTWikiSitemapWatcher >> gtDiffOn: aView [
	<gtView>
	^ (self history size <= 1)
		ifTrue: [
			aView text
				title: 'Diff';
				priority: 2;
				text: [ (self history isEmpty
					ifTrue: [ 'No snapshot yet. Click "Fetch now".' ]
					ifFalse: [ 'Initial snapshot — no diff yet. Click "Fetch now" again to compute changes.' ]) ] ]
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
				ifTrue: [ act button
						label: 'Fetch now';
						icon: (Smalltalk
								at: #BrGlamorousVectorIcons
								ifPresent: [ :i | i refresh ]
								ifAbsent: [ nil ]);
						action: [ self fetchNow ] ] ];
		text: [ String
				streamContents: [ :s | 
					| fileRef sm |
					s
						nextPutAll: 'Host: ';
						nextPutAll: self host;
						cr.
					fileRef := self sitemapFile.
					s
						nextPutAll: 'File: ';
						nextPutAll: fileRef asString;
						cr.
					s
						nextPutAll: 'Exists: ';
						nextPutAll: (fileRef exists ifTrue: [ 'yes' ] ifFalse: [ 'no' ]);
						cr.
					sm := FwSiteMap forHost: self host.
					s
						nextPutAll: 'Pages: ';
						nextPutAll: sm pages size asString;
						cr.
					s
						nextPutAll: 'Last loaded: ';
						nextPutAll: (sm lastLoadedAt ifNil: [ '—' ] ifNotNil: [ sm lastLoadedAt asString ]);
						cr.
					history isNil | history isEmpty
						ifTrue: [ s nextPutAll: 'No snapshot yet. Click "Fetch now".' ]
						ifFalse: [ s
								nextPutAll: 'Snapshots: ';
								nextPutAll: history size asString;
								cr ] ] ]
]

{ #category : #accessing }
GTWikiSitemapWatcher >> history [
	^ history ifNil: [ history := OrderedCollection new ]
]

{ #category : #'as yet unclassified' }
GTWikiSitemapWatcher >> host [
	^ host ifNil: [  "set your preferred default"host := 'wiki.ralfbarkow.ch' ]
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
GTWikiSitemapWatcher >> log: aString [
	"Prefix with a short timestamp and write to whichever transcript we have."
	| line ts tr |
	ts := Time now print24.
	line := '[GTWikiWatcher ' , ts , '] ' , aString.
	(Smalltalk at: #GtTranscript ifAbsent: [ nil ])
		ifNotNil: [ :gt | (gt respondsTo: #show:)
			ifTrue: [ gt show: line; cr ] ].
	tr := Smalltalk at: #Transcript ifAbsent: [ nil ].
	tr ifNotNil: [ (tr respondsTo: #show:)
		ifTrue: [ tr show: line; cr ] ]
]

{ #category : #printing }
GTWikiSitemapWatcher >> openTranscriptIfAvailable [
	"Try to open a transcript tool. Fall back to the classic Transcript."
	| gt |
	gt := Smalltalk at: #GtTranscript ifAbsent: [ nil ].
	(gt notNil and: [ gt respondsTo: #open ])
		ifTrue: [ gt open ].
	(Smalltalk at: #Transcript ifAbsent: [ nil ]) ifNotNil: [ :tr |
		(tr respondsTo: #open) ifTrue: [ tr open ] ]
]

{ #category : #'as yet unclassified' }
GTWikiSitemapWatcher >> sitemapFile [
	^ Wiki sitemapFileForHost: self host
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
