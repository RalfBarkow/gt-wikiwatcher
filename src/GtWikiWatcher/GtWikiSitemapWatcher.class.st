Class {
	#name : #GtWikiSitemapWatcher,
	#superclass : #Object,
	#instVars : [
		'url',
		'history',
		'lastDiff',
		'host',
		'added',
		'updated',
		'removed'
	],
	#category : #GtWikiWatcher
}

{ #category : #'instance creation' }
GtWikiSitemapWatcher class >> httpURL: aString [
	^ self new
		url: aString;
		yourself
]

{ #category : #'gt-views' }
GtWikiSitemapWatcher >> ensureTranscriptOpen [
	| opened tryOpen |
	opened := false.
	tryOpen := [ :blk | [ blk value. opened := true ] on: Error, MessageNotUnderstood do: [ :e | ] ].

	"Canonical tool opener (works on most GT/Pharo builds)"
	tryOpen value: [ Smalltalk tools openTranscript ].

	"Fallbacks for various GT/Pharo versions"
	opened ifFalse: [ tryOpen value: [ (Smalltalk at: #GtTranscriptTool ifAbsent: [ nil ]) ifNotNil: #open ] ].
	opened ifFalse: [ tryOpen value: [ (Smalltalk at: #GtTranscript ifAbsent: [ nil ]) ifNotNil: #open ] ].
	opened ifFalse: [ tryOpen value: [ (Smalltalk at: #TranscriptBrowser ifAbsent: [ nil ]) ifNotNil: #open ] ].
	opened ifFalse: [ tryOpen value: [ (Smalltalk at: #Transcript ifAbsent: [ nil ]) ifNotNil: #open ] ].
	^ opened

]

{ #category : #fetching }
GtWikiSitemapWatcher >> fetchIfEmpty [
	"Backward-compatibility no-op. Views no longer auto-fetch."
	^ self
]

{ #category : #fetching }
GtWikiSitemapWatcher >> fetchNow [
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
	snap := GtWikiSitemapSnapshot fromJson: json.
	self history add: snap.
	lastDiff := (self history size > 1)
		ifTrue: [ GtWikiSitemapDiff
			between: (self history at: self history size - 1)
			and: snap ]
		ifFalse: [ GtWikiSitemapDiff between: nil and: snap ].
	^ snap
]

{ #category : #'gt-views' }
GtWikiSitemapWatcher >> fetchNowAsyncFrom: aPhlowAction [
	self ensureTranscriptOpen.
	Transcript cr; show: '[GtWikiSitemapWatcher] Fetching '; show: (url ifNil: [ '—' ]); cr; flush.

	[ 
		[ 
			self fetchNow.
			Transcript show: '…done'; cr; flush.
		] on: Error do: [ :ex |
			Transcript show: '…failed: '; show: ex messageText; cr; flush ].

		self refreshInspectorFrom: aPhlowAction
	] forkAt: Processor userBackgroundPriority.

]

{ #category : #fetching }
GtWikiSitemapWatcher >> fetchNowAsyncWithTranscript [
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
GtWikiSitemapWatcher >> gtDiffOn: aView [
	<gtView>
	^ (self history size <= 1)
		ifTrue: [
			aView text
				title: 'Diff';
				priority: 2;
				action: [ :act | (act respondsTo: #button)
					ifTrue: [ act button label: 'Reload'; icon: (Smalltalk at: #BrGlamorousVectorIcons ifPresent: [ :i | i refresh ] ifAbsent: [ nil ]); action: [ self refreshInspectorFrom: act ] ] ];
				text: [
					self history isEmpty
						ifTrue: [ 'No snapshot yet. Click "Fetch now".' ]
						ifFalse: [ 'Initial snapshot — no diff yet. Click "Fetch now" again to compute changes.' ] ] ]
		ifFalse: [
			((lastDiff ifNil: [ GtWikiSitemapDiff new ]) isEmpty)
				ifTrue: [
					aView text
						title: 'Diff';
						priority: 2;
						action: [ :act | (act respondsTo: #button)
							ifTrue: [ act button label: 'Reload'; icon: (Smalltalk at: #BrGlamorousVectorIcons ifPresent: [ :i | i refresh ] ifAbsent: [ nil ]); action: [ self refreshInspectorFrom: act ] ] ];
						text: [ 'No changes since the previous snapshot.' ] ]
				ifFalse: [
					aView columnedList
						title: 'Diff';
						priority: 2;
						action: [ :act | (act respondsTo: #button)
							ifTrue: [ act button label: 'Reload'; icon: (Smalltalk at: #BrGlamorousVectorIcons ifPresent: [ :i | i refresh ] ifAbsent: [ nil ]); action: [ self refreshInspectorFrom: act ] ] ];
						items: [ self rowsForLastDiff ];
						column: 'Change' text: [ :row | row first ];
						column: 'Slug'   text: [ :row | row second ];
						column: 'Date'   text: [ :row | (row third ifNil: [ '' ] ifNotNil: [ :d | d asString ]) ] ] ].

]

{ #category : #'gt-views' }
GtWikiSitemapWatcher >> gtHistoryOn: aView [
	<gtView>
	^ aView list
		title: 'History';
		priority: 3;
		action: [ :act | (act respondsTo: #button)
			ifTrue: [ act button label: 'Reload'; icon: (Smalltalk at: #BrGlamorousVectorIcons ifPresent: [ :i | i refresh ] ifAbsent: [ nil ]); action: [ self refreshInspectorFrom: act ] ] ];
		items: [ self history collect: #summaryString ].

]

{ #category : #'gt-views' }
GtWikiSitemapWatcher >> gtStatusOn: aView [
	<gtView>
	^ aView text
		title: 'Status';
		priority: 1;
		action: [ :act |
			(act respondsTo: #button) ifTrue: [
				act button
					label: 'Fetch now';
					icon: (Smalltalk at: #BrGlamorousVectorIcons ifPresent: [ :i | i refresh ] ifAbsent: [ nil ]);
					action: [ self fetchNowAsyncFrom: act ] ] ];
		text: [
			String streamContents: [ :s |
				s nextPutAll: 'URL: '; nextPutAll: (url ifNil: [ '—' ]); cr.
				s nextPutAll: 'Snapshots: '; nextPutAll: self history size asString; cr.
				self history isEmpty
					ifTrue: [ s nextPutAll: 'No snapshot yet. Click "Fetch now".' ]
					ifFalse: [
						self history size = 1
							ifTrue: [ s nextPutAll: 'Initial snapshot — click "Fetch now" again to compute changes.' ]
							ifFalse: [ s nextPutAll: 'Diff available. Open the Diff tab.' ] ] ] ].

]

{ #category : #accessing }
GtWikiSitemapWatcher >> history [
	^ history ifNil: [ history := OrderedCollection new ]
]

{ #category : #'as yet unclassified' }
GtWikiSitemapWatcher >> host [
	^ host ifNil: [  "set your preferred default"host := 'wiki.ralfbarkow.ch' ]
]

{ #category : #initialization }
GtWikiSitemapWatcher >> initialize [
	super initialize.
	history := OrderedCollection new
]

{ #category : #accessing }
GtWikiSitemapWatcher >> lastDiff [
	^ lastDiff
]

{ #category : #printing }
GtWikiSitemapWatcher >> log: aString [
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
GtWikiSitemapWatcher >> openTranscriptIfAvailable [
	"Try to open a transcript tool. Fall back to the classic Transcript."
	| gt |
	gt := Smalltalk at: #GtTranscript ifAbsent: [ nil ].
	(gt notNil and: [ gt respondsTo: #open ])
		ifTrue: [ gt open ].
	(Smalltalk at: #Transcript ifAbsent: [ nil ]) ifNotNil: [ :tr |
		(tr respondsTo: #open) ifTrue: [ tr open ] ]
]

{ #category : #'as yet unclassified' }
GtWikiSitemapWatcher >> refreshInspectorFrom: aPhlowAction [
	"Politely ask Phlow to rebuild the whole inspector; ignore older GT builds."
	[ aPhlowAction phlow fireToolUpdateWish ] on: MessageNotUnderstood do: [ :ex | ].

]

{ #category : #'gt-views' }
GtWikiSitemapWatcher >> rowsForLastDiff [
	| now curr |
	now := DateAndTime now.
	curr := self history last.
	^ (lastDiff added collect: [ :slug | { 'added'. slug. now } ])
		, (lastDiff updated collect: [ :slug | 
			| pageDate |
			pageDate := (curr pages at: slug ifAbsent: [ nil ])
				ifNotNil: [ :p | p at: #date ifAbsent: [ nil ] ].
			{ 'updated'. slug. pageDate } ])
		, (lastDiff removed collect: [ :slug | { 'removed'. slug. nil } ]).

]

{ #category : #'as yet unclassified' }
GtWikiSitemapWatcher >> sitemapFile [
	^ Wiki sitemapFileForHost: self host
]

{ #category : #printing }
GtWikiSitemapWatcher >> storeOn: aStream [
	aStream
		nextPutAll: '(GTWikiSitemapWatcher httpURL: ';
		nextPutAll: url storeString;
		nextPutAll: ')'
]

{ #category : #accessing }
GtWikiSitemapWatcher >> url [
	^ url
]

{ #category : #accessing }
GtWikiSitemapWatcher >> url: aString [
	url := aString.
	^ self
]
