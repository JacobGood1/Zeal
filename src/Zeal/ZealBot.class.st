Class {
	#name : 'ZealBot',
	#superclass : 'BlElement',
	#instVars : [
		'chatHistory',
		'inputEditor',
		'outputEditor',
		'currentProcess',
		'systemPrompt',
		'conversationId',
		'browser',
		'prefixText'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'opening' }
ZealBot class >> open [
	"Open a standalone Zeal Bot window"
	| space chat |
	chat := self new.
	space := BlSpace new.
	space title: 'Zeal Bot'.
	space extent: 700 @ 500.
	space root layout: BlLinearLayout vertical.
	space root background: (Color fromHexString: '1A1A1A').
	space root addChild: chat.
	space show.
	^ chat
]

{ #category : 'ui' }
ZealBot >> appendToChat: speaker text: aString color: aColor [
	"Append a styled message to the chat output and save prefix snapshot"
	| existing header body bodyColor |
	existing := outputEditor editor text.
	header := (speaker, ':') asRopedText 
		foreground: aColor;
		bold;
		fontSize: 13.
	bodyColor := speaker = 'You' 
		ifTrue: [ Color fromHexString: '4499DD' ] 
		ifFalse: [ Color white alpha: 0.85 ].
	body := (String cr, aString, String cr, String cr) asRopedText 
		foreground: bodyColor;
		fontSize: 13.
	existing append: header.
	existing append: body.
	outputEditor editor text: existing.
	chatHistory add: { speaker. aString }.
	"Save everything before the Bot response as the prefix"
	speaker = 'Bot' ifTrue: [
		prefixText := existing copy ]
]

{ #category : 'ui' }
ZealBot >> appendToolCall: toolName input: inputDict [
	"Show a tool call in the chat output"
	| existing line |
	existing := outputEditor editor text.
	line := ('> ', toolName, '(') asRopedText foreground: (Color fromHexString: 'FFB86C'); fontSize: 12.
	inputDict keysAndValuesDo: [:k :v |
		| arg |
		arg := (k, '=', (v printString copyFrom: 1 to: (v printString size min: 80))) asRopedText 
			foreground: (Color fromHexString: 'AAAAAA'); fontSize: 11.
		line append: arg.
		line append: (' ' asRopedText) ].
	line append: (')' asRopedText foreground: (Color fromHexString: 'FFB86C'); fontSize: 12).
	line append: (String cr asRopedText).
	existing append: line.
	outputEditor editor text: existing
]

{ #category : 'ui' }
ZealBot >> appendToolResult: toolName result: resultText [
	"Show a tool result in the chat output"
	| existing line preview |
	existing := outputEditor editor text.
	preview := resultText copyFrom: 1 to: (resultText size min: 200).
	(resultText size > 200) ifTrue: [ preview := preview, '...' ].
	line := ('< ', toolName, ': ', preview, String cr) asRopedText 
		foreground: (Color fromHexString: '66BB6A'); fontSize: 11.
	existing append: line.
	outputEditor editor text: existing
]

{ #category : 'accessing' }
ZealBot >> browser: aBrowser [
	browser := aBrowser
]

{ #category : 'context' }
ZealBot >> buildClassContext: aClass on: s [
	"Add class-specific context: fields, methods, parents"
	| fields methods |
	
	"Parents/extends"
	(aClass respondsTo: #extensions) ifTrue: [
		aClass extensions notEmpty ifTrue: [
			s nextPutAll: 'Extends: ', (aClass extensions joinUsing: ', '); cr ]].
	
	"Specifiers"
	aClass specifiers notEmpty ifTrue: [
		s nextPutAll: 'Specifiers: ', (aClass specifiers collect: [:sp | '<', sp, '>']) printString; cr ].
	
	"Fields"
	fields := OrderedCollection new.
	(aClass respondsTo: #fields) ifTrue: [ fields addAll: aClass fields ].
	(aClass respondsTo: #mutableFields) ifTrue: [ fields addAll: aClass mutableFields ].
	fields notEmpty ifTrue: [
		s cr; nextPutAll: '### Fields'; cr.
		fields do: [:f |
			s nextPutAll: '- ', f name.
			(f respondsTo: #type) ifTrue: [ f type ifNotNil: [:t | s nextPutAll: ' : ', t ]].
			s cr ]].
	
	"Methods"
	methods := (aClass respondsTo: #methods) ifTrue: [aClass methods] ifFalse: [#()].
	methods notEmpty ifTrue: [
		s cr; nextPutAll: '### Methods'; cr.
		methods do: [:m |
			| src |
			src := [m compileToZeal] on: Error do: [''].
			s nextPutAll: '- '.
			src notEmpty ifTrue: [s nextPutAll: src] ifFalse: [s nextPutAll: m name].
			s cr ]]
]

{ #category : 'context' }
ZealBot >> buildContext [
	"Build context string from the current browser selection"
	| ctx node |
	browser ifNil: [ ^ '' ].
	node := browser instVarNamed: 'selectedNode'.
	node ifNil: [ ^ '' ].
	
	ctx := String streamContents: [:s |
		s nextPutAll: '## Current Context'; cr; cr.
		
		"Node type and name"
		s nextPutAll: 'Selected: ', node class name, ' named "', node name, '"'; cr.
		
		"Module"
		(node respondsTo: #module) ifTrue: [
			node module ifNotNil: [:mod |
				s nextPutAll: 'Module: ', mod name; cr ]].
		
		"Usings"
		(node respondsTo: #usings) ifTrue: [
			node usings notEmpty ifTrue: [
				s nextPutAll: 'Using: ', ((node usings collect: [:u | 
					(u respondsTo: #path) ifTrue: [u path] ifFalse: [u printString]]) joinUsing: ', '); cr ]].
		
		"Zeal source"
		(node respondsTo: #compileToZeal) ifTrue: [
			| zealSrc |
			zealSrc := [node compileToZeal] on: Error do: [''].
			zealSrc notEmpty ifTrue: [
				s cr; nextPutAll: '### Zeal Source'; cr.
				s nextPutAll: '```'; cr; nextPutAll: zealSrc; cr; nextPutAll: '```'; cr ]].
		
		"For classes: fields, methods, parents"
		(node isKindOf: ZealClass) ifTrue: [
			self buildClassContext: node on: s ].
		(node isKindOf: ZealInterface) ifTrue: [
			self buildClassContext: node on: s ].
		
		"Verse output"
		(node respondsTo: #compileToVerse) ifTrue: [
			| verseSrc |
			verseSrc := [node compileToVerse] on: Error do: [''].
			verseSrc notEmpty ifTrue: [
				s cr; nextPutAll: '### Verse Output'; cr.
				s nextPutAll: '```verse'; cr; nextPutAll: verseSrc; cr; nextPutAll: '```'; cr ]] ].
	^ ctx
]

{ #category : 'ui' }
ZealBot >> buildUI [
	| chatPane inputRow sendBtn topBar |
	self
		layout: BlLinearLayout vertical;
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		background: (Color fromHexString: '1A1A1A');
		padding: (BlInsets all: 8).
	
	"Top bar"
	topBar := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		padding: (BlInsets all: 6);
		margin: (BlInsets bottom: 4).
	topBar addChild: (BrLabel new
		aptitude: (BrGlamorousLabelAptitude new foreground: (Color fromHexString: '4499DD'); fontSize: 16; bold);
		text: 'Zeal Bot').
	topBar addChild: (BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Clear';
		margin: (BlInsets left: 12);
		action: [ self clearChat ]).
	topBar addChild: (BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Stop';
		margin: (BlInsets left: 6);
		action: [ self stopProcess ]).
	self addChild: topBar.
	
	"Chat output — no default foreground so styled text keeps its colors"
	outputEditor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new);
		beReadOnlyWithSelection;
		text: '' asRopedText;
		background: (Color fromHexString: '1E1E1E');
		border: (BlBorder paint: (Color fromHexString: '333333') width: 1);
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent ];
		padding: (BlInsets all: 8).
	self addChild: (outputEditor asScrollableElement 
		constraintsDo: [:c | c horizontal matchParent. c vertical matchParent]).
	
	"Input row"
	inputRow := BlElement new
		layout: BlLinearLayout horizontal alignCenterLeft;
		constraintsDo: [:c | c horizontal matchParent. c vertical fitContent ];
		margin: (BlInsets top: 6).
	
	inputEditor := BrEditor new
		aptitude: (BrGlamorousCodeEditorAptitude new foreground: (Color white alpha: 0.85));
		text: ('' asRopedText foreground: (Color white alpha: 0.85));
		background: (Color fromHexString: '262626');
		border: (BlBorder paint: (Color fromHexString: '4499DD') width: 1);
		constraintsDo: [:c | c horizontal matchParent. c vertical exact: 80 ];
		padding: (BlInsets all: 6).
	
	"Ctrl+Enter to send"
	inputEditor addShortcut: (BlShortcutWithAction new
		combination: (BlKeyCombination builder control return build);
		action: [ self sendMessage ]).
	
	sendBtn := BrButton new
		aptitude: (BrGlamorousButtonWithLabelAptitude new);
		label: 'Send';
		margin: (BlInsets left: 6);
		constraintsDo: [:c | c vertical exact: 80 ];
		action: [ self sendMessage ].
	
	inputRow addChild: inputEditor.
	inputRow addChild: sendBtn.
	self addChild: inputRow
]

{ #category : 'actions' }
ZealBot >> clearChat [
	chatHistory := OrderedCollection new.
	conversationId := nil.
	outputEditor editor text: '' asRopedText
]

{ #category : 'initialization' }
ZealBot >> initialize [
	super initialize.
	chatHistory := OrderedCollection new.
	systemPrompt := ''.
	conversationId := nil.
	self buildUI
]

{ #category : 'parsing' }
ZealBot >> parseStreamChunk: rawChunk into: displayText [
	"Parse stream-json lines and update display. Each line is a JSON object."
	| lines |
	lines := rawChunk lines.
	lines do: [:line |
		| trimmed json |
		trimmed := line trimBoth.
		(trimmed notEmpty and: [trimmed first = ${]) ifTrue: [
			[
				json := STONJSON fromString: trimmed.
				self processStreamEvent: json
			] on: Error do: [:e | "ignore malformed json" ] ] ]
]

{ #category : 'parsing' }
ZealBot >> processStreamEvent: json [
	"Process a single stream-json event and update the chat display"
	| type |
	type := json at: 'type' ifAbsent: [''].
	
	"Capture session ID for --continue"
	(json includesKey: 'session_id') ifTrue: [
		conversationId := json at: 'session_id' ].
	
	type = 'assistant' ifTrue: [
		| message content |
		message := json at: 'message' ifAbsent: [nil].
		message ifNotNil: [
			content := message at: 'content' ifAbsent: [#()].
			content do: [:block |
				| blockType |
				blockType := block at: 'type' ifAbsent: [''].
				blockType = 'text' ifTrue: [
					| text |
					text := block at: 'text' ifAbsent: [''].
					text notEmpty ifTrue: [
						self enqueueTask: (BlTaskAction new action: [
							self updateLastResponse: text ]) ] ].
				blockType = 'tool_use' ifTrue: [
					| toolName toolInput |
					toolName := block at: 'name' ifAbsent: ['?'].
					toolInput := block at: 'input' ifAbsent: [Dictionary new].
					self enqueueTask: (BlTaskAction new action: [
						self appendToolCall: toolName input: toolInput ]) ] ] ] ].
	
	type = 'result' ifTrue: [
		| content |
		content := json at: 'content' ifAbsent: [#()].
		content do: [:block |
			| blockType |
			blockType := block at: 'type' ifAbsent: [''].
			blockType = 'tool_result' ifTrue: [
				| toolName resultText |
				toolName := block at: 'tool_name' ifAbsent: ['?'].
				resultText := block at: 'text' ifAbsent: [''].
				self enqueueTask: (BlTaskAction new action: [
					self appendToolResult: toolName result: resultText ]) ] ] ]
]

{ #category : 'ui' }
ZealBot >> recolorLabels: aText [
	"Re-apply colors to You: and Bot: labels and user message text"
	| str idx nextBotIdx |
	str := aText asString.
	idx := 1.
	[idx := str indexOfSubCollection: 'You:' startingAt: idx.
	 idx > 0] whileTrue: [
		(aText from: idx to: idx + 3) foreground: (Color fromHexString: '4499DD'); bold.
		"Color user text blue until next Bot: or end"
		nextBotIdx := str indexOfSubCollection: 'Bot:' startingAt: idx + 4.
		nextBotIdx = 0 ifTrue: [ nextBotIdx := str size + 1 ].
		(idx + 4 < nextBotIdx and: [idx + 4 <= str size]) ifTrue: [
			(aText from: idx + 4 to: (nextBotIdx - 1 min: str size)) foreground: (Color fromHexString: '4499DD') ].
		idx := idx + 4].
	idx := 1.
	[idx := str indexOfSubCollection: 'Bot:' startingAt: idx.
	 idx > 0] whileTrue: [
		(aText from: idx to: idx + 3) foreground: (Color fromHexString: '9580FF'); bold.
		idx := idx + 4]
]

{ #category : 'actions' }
ZealBot >> runClaude: userText [
	"Run claude CLI with GT MCP server, streaming, and conversation continuity"
	| builder child stdout stderr done |
	builder := GtExternalProcessBuilder new
		command: 'claude';
		arg: '--print';
		arg: '--verbose';
		arg: '--output-format'; arg: 'stream-json';
		arg: '--dangerously-skip-permissions';
		arg: '--mcp-config'; arg: 'C:\projects\gt-mcp\.claude-chat-mcp.json'.
	
	"Continue conversation if we have a session ID"
	conversationId ifNotNil: [
		builder arg: '--resume'; arg: conversationId ].
	
	(systemPrompt notNil and: [systemPrompt notEmpty]) ifTrue: [
		builder arg: '--system-prompt'; arg: systemPrompt ].
	
	builder arg: userText.
	builder pipeStdout. builder pipeStderr.
	
	child := builder spawn.
	currentProcess := child.
	stdout := child asynchronousStdout.
	stderr := child asynchronousStderr.
	done := false.
	
	[
		[done not] whileTrue: [
			| chunk |
			(Delay forMilliseconds: 50) wait.
			chunk := stdout pollString.
			(chunk notNil and: [chunk notEmpty]) ifTrue: [
				self parseStreamChunk: chunk into: nil ].
			(child isTerminated and: [stdout isEndOfStreamReached]) ifTrue: [
				done := true ] ].
		currentProcess := nil
	] on: Error do: [:e |
		self enqueueTask: (BlTaskAction new action: [
			self updateLastResponse: 'Error: ', e messageText ]).
		currentProcess := nil ]
]

{ #category : 'actions' }
ZealBot >> sendMessage [
	"Send the input text to Claude with current browser context"
	| userText context fullPrompt |
	userText := inputEditor editor text asString trimBoth.
	userText isEmpty ifTrue: [ ^ self ].
	
	"Display user message"
	self appendToChat: 'You' text: userText color: (Color fromHexString: '4499DD').
	inputEditor editor text: ('' asRopedText foreground: (Color white alpha: 0.85)).
	
	"Build context from browser selection"
	context := self buildContext.
	fullPrompt := context isEmpty 
		ifTrue: [ userText ]
		ifFalse: [ context, String cr, '## User Question', String cr, userText ].
	
	"Display bot header"
	self appendToChat: 'Bot' text: '...' color: (Color fromHexString: '9580FF').
	
	"Spawn claude process in background"
	[ self runClaude: fullPrompt ] fork
]

{ #category : 'actions' }
ZealBot >> stopProcess [
	currentProcess ifNotNil: [:p |
		[p terminate] on: Error do: [:e | ].
		currentProcess := nil.
		self enqueueTask: (BlTaskAction new action: [
			self updateLastResponse: '(stopped)' ])]
]

{ #category : 'ui' }
ZealBot >> styleInlineMarkdown: aLine [
	"Handle **bold** and `code` inline formatting — all text is light colored"
	| result i size ch |
	result := '' asRopedText.
	i := 1. size := aLine size.
	[ i <= size ] whileTrue: [
		ch := aLine at: i.
		"Bold: **text**"
		(ch = $* and: [i + 1 <= size and: [(aLine at: i + 1) = $*]]) ifTrue: [
			| endIdx boldText |
			endIdx := aLine indexOfSubCollection: '**' startingAt: i + 2.
			endIdx > 0 ifTrue: [
				boldText := (aLine copyFrom: i + 2 to: endIdx - 1) asRopedText bold; foreground: Color white.
				result append: boldText.
				i := endIdx + 2 ]
			ifFalse: [ result append: (ch asString asRopedText foreground: (Color white alpha: 0.85)). i := i + 1 ] ]
		"Inline code: `text`"
		ifFalse: [ ch = $` ifTrue: [
			| endIdx codeText |
			endIdx := aLine indexOf: $` startingAt: i + 1.
			endIdx > 0 ifTrue: [
				codeText := (aLine copyFrom: i + 1 to: endIdx - 1) asRopedText monospace; foreground: (Color fromHexString: 'E876B0'); fontSize: 12.
				result append: codeText.
				i := endIdx + 1 ]
			ifFalse: [ result append: (ch asString asRopedText foreground: (Color white alpha: 0.85)). i := i + 1 ] ]
		ifFalse: [
			result append: (ch asString asRopedText foreground: (Color white alpha: 0.85)).
			i := i + 1 ] ] ].
	^ result
]

{ #category : 'ui' }
ZealBot >> styleMarkdown: aString [
	"Apply basic markdown styling to a roped text: bold, inline code, code blocks, headers"
	| text lines result inCodeBlock codeBlockContent |
	lines := aString lines.
	result := '' asRopedText.
	inCodeBlock := false.
	codeBlockContent := OrderedCollection new.
	
	lines do: [:line |
		| trimmed |
		trimmed := line trimBoth.
		
		"Code block fences"
		(trimmed beginsWith: '```') ifTrue: [
			inCodeBlock ifTrue: [
				"End code block"
				| code |
				code := (String lf join: codeBlockContent) asRopedText
					monospace;
					foreground: (Color fromHexString: '69F0AE');
					fontSize: 12.
				result append: code.
				result append: String lf asRopedText.
				codeBlockContent := OrderedCollection new.
				inCodeBlock := false ]
			ifFalse: [
				"Start code block"
				inCodeBlock := true ] ]
		ifFalse: [
			inCodeBlock ifTrue: [
				codeBlockContent add: line ]
			ifFalse: [
				| styled |
				styled := self styleMarkdownLine: line.
				result append: styled.
				result append: String lf asRopedText ] ] ].
	
	"Handle unclosed code block"
	codeBlockContent notEmpty ifTrue: [
		result append: ((String lf join: codeBlockContent) asRopedText monospace foreground: (Color fromHexString: '69F0AE'); fontSize: 12) ].
	
	^ result
]

{ #category : 'ui' }
ZealBot >> styleMarkdownLine: aLine [
	"Style a single markdown line: headers, bold, inline code"
	| trimmed |
	trimmed := aLine trimLeft.
	
	"Headers"
	(trimmed beginsWith: '### ') ifTrue: [
		^ (trimmed allButFirst: 4) asRopedText bold; foreground: (Color fromHexString: '4499DD'); fontSize: 14 ].
	(trimmed beginsWith: '## ') ifTrue: [
		^ (trimmed allButFirst: 3) asRopedText bold; foreground: (Color fromHexString: '4499DD'); fontSize: 15 ].
	(trimmed beginsWith: '# ') ifTrue: [
		^ (trimmed allButFirst: 2) asRopedText bold; foreground: (Color fromHexString: '4499DD'); fontSize: 16 ].
	
	"Inline formatting: bold and code"
	^ self styleInlineMarkdown: aLine
]

{ #category : 'accessing' }
ZealBot >> systemPrompt: aString [
	systemPrompt := aString
]

{ #category : 'ui' }
ZealBot >> updateLastResponse: aString [
	"Replace only the last Bot response using saved prefix"
	| newText lastBotIdx searchStr header styled |
	prefixText ifNil: [ ^ self ].
	
	"Find Bot: in the saved prefix and keep everything before it"
	searchStr := 'Bot:'.
	lastBotIdx := prefixText asString findLastOccurrenceOfString: searchStr startingAt: 1.
	lastBotIdx = 0 ifTrue: [ ^ self ].
	
	"Copy prefix up to (but not including) the last Bot:"
	newText := prefixText copyFrom: 1 to: lastBotIdx - 1.
	
	"Add Bot: header"
	header := 'Bot:' asRopedText foreground: (Color fromHexString: '9580FF'); bold; fontSize: 13.
	newText append: header.
	newText append: String lf asRopedText.
	
	"Add styled response"
	styled := self styleMarkdown: aString.
	newText append: styled.
	newText append: (String lf, String lf) asRopedText.
	
	outputEditor editor text: newText
]
