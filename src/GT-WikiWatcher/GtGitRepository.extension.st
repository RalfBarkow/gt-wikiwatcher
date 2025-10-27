Extension { #name : #GtGitRepository }

{ #category : #'*GT-WikiWatcher' }
GtGitRepository >> gw_makeOpenAIChat [
	| chat |
	chat := GtLlmChat new.
	chat provider: GtOpenAIProvider withApiKeyFromFile.
	^ chat
]
