Class {
	#name : 'ZealKeyChord',
	#superclass : 'Object',
	#instVars : [
		'chords',
		'editor',
		'lastChar',
		'lastTime',
		'pendingDelete',
		'chordWindow'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
ZealKeyChord >> addChord: twoCharString action: aBlock [
	"Register a two-key chord. Example: addChord: 'jk' action: [ ... ]"
	chords at: twoCharString put: aBlock
]

{ #category : 'private' }
ZealKeyChord >> chordStartChars [
	"Return characters that can START a chord (first char only)"
	| starts |
	starts := Set new.
	chords keysDo: [:k | starts add: k first ].
	^ starts
]

{ #category : 'api' }
ZealKeyChord >> chordWindow: milliseconds [
	chordWindow := milliseconds
]

{ #category : 'private' }
ZealKeyChord >> deleteLastChar [
	"Delete the previously inserted character (the first key of the chord)"
	| pos |
	editor ifNil: [ ^ self ].
	pos := 0.
	editor editor cursors do: [:c | pos := c position].
	pos > 0 ifTrue: [
		editor editor deleter
			from: pos - 1 to: pos;
			delete ]
]

{ #category : 'private' }
ZealKeyChord >> handleTextInput: evt [
	"Intercept text input for chord detection.
	 First chord key: consume event, buffer char, start timer.
	 Second key within window: fire chord or flush both chars."
	| char now elapsed pair action |
	char := evt text.
	(char isNil or: [ char isEmpty ]) ifTrue: [ ^ self ].
	char := char first.
	now := DateAndTime now.
	
	"If we have a buffered first key, check for chord completion"
	lastChar ifNotNil: [
		elapsed := (now - lastTime) asMilliSeconds.
		elapsed <= chordWindow ifTrue: [
			pair := String with: lastChar with: char.
			action := chords at: pair ifAbsent: [ nil ].
			action ifNotNil: [
				"Chord matched! Consume this event, fire action."
				evt consumed: true.
				lastChar := nil. lastTime := nil.
				action value.
				^ self ].
			"Not a chord — flush the buffered char, then let this one through"
			self insertText: lastChar asString.
			lastChar := nil. lastTime := nil.
			^ self ] 
		ifFalse: [
			"Timer expired — flush buffered char"
			self insertText: lastChar asString.
			lastChar := nil. lastTime := nil ] ].
	
	"Check if this char could start a chord"
	(self chordStartChars includes: char) ifTrue: [
		"Buffer it, don't insert yet"
		evt consumed: true.
		lastChar := char.
		lastTime := now.
		"Schedule a flush in case no second key arrives"
		[ (Delay forMilliseconds: chordWindow + 20) wait.
		  lastChar ifNotNil: [
			editor enqueueTask: (BlTaskAction new action: [
				lastChar ifNotNil: [
					self insertText: lastChar asString.
					lastChar := nil. lastTime := nil ] ]) ] ] fork ]
]

{ #category : 'initialization' }
ZealKeyChord >> initialize [
	super initialize.
	chords := Dictionary new.
	lastChar := nil.
	lastTime := nil.
	pendingDelete := false.
	chordWindow := 200 "milliseconds"
]

{ #category : 'private' }
ZealKeyChord >> insertText: aString [
	"Manually insert text at cursor position"
	| pos |
	editor ifNil: [ ^ self ].
	pos := 0.
	editor editor cursors do: [:c | pos := c position].
	editor editor inserter
		at: pos;
		string: aString;
		insert
]

{ #category : 'api' }
ZealKeyChord >> installOn: anEditor [
	"Install the chord handler as an event FILTER (capture phase, runs before default handlers)"
	editor := anEditor.
	editor addEventFilterOn: BlTextInputEvent do: [:evt | self handleTextInput: evt]
]
