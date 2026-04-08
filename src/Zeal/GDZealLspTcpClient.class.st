Class {
	#name : 'GDZealLspTcpClient',
	#superclass : 'GtLanguageServerProtocolStdioClient',
	#instVars : [
		'socket',
		'host',
		'port',
		'readProcess',
		'readBuffer'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'instance creation' }
GDZealLspTcpClient class >> host: aHost port: aPort [
	"Build a client that connects to an LSP server over TCP (e.g. Godot's GDScript LSP
	 on localhost:6005). Inherits all JSON-RPC framing and message routing from the
	 stdio client; only the transport methods are overridden."
	^ self new
		host: aHost;
		port: aPort;
		yourself
]

{ #category : 'accessing' }
GDZealLspTcpClient >> host [
	^ host ifNil: [ 'localhost' ]
]

{ #category : 'accessing' }
GDZealLspTcpClient >> host: aString [
	host := aString
]

{ #category : 'testing' }
GDZealLspTcpClient >> isRunning [
	^ socket notNil and: [ socket isConnected ]
]

{ #category : 'accessing' }
GDZealLspTcpClient >> port [
	^ port ifNil: [ 6005 ]
]

{ #category : 'accessing' }
GDZealLspTcpClient >> port: anInteger [
	port := anInteger
]

{ #category : 'protocol' }
GDZealLspTcpClient >> send: aString with: aStructure id: id [
	"Format an LSP JSON-RPC frame and write it to the TCP socket. Same wire format
	 as the parent stdio version (Content-Length header + JSON body) — only the
	 sink differs."
	| string data jsonData dict |
	(socket isNil or: [ socket isConnected not ]) ifTrue: [
		(errorHandlers at: id ifAbsent: [ [ :e | nil ] ]) cull: nil.
		self terminate.
		^ self ].
	dict := Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'id' put: id;
		at: 'method' put: aString;
		yourself.
	aStructure ifNotNil: [ dict at: 'params' put: aStructure asDictionary ].
	data := GtJson forJsonObject: dict.
	jsonData := data asJsonString.
	(GtLSPServerInputSignal new message: jsonData) emit.
	string := 'Content-Length: ' , jsonData utf8Encoded size printString
		, String crlf , String crlf , jsonData.
	mutex critical: [ socket sendData: string utf8Encoded ]
]

{ #category : 'protocol' }
GDZealLspTcpClient >> sendNotification: aString with: aStructure [
	"TCP variant — same wire format as parent but writes to socket and checks
	 socket health instead of externalProcess (which is always nil for us)."
	| string data jsonData dict |
	(socket isNil or: [ socket isConnected not ]) ifTrue: [
		self terminate.
		^ self ].
	dict := Dictionary new
		at: 'jsonrpc' put: '2.0';
		at: 'method' put: aString;
		yourself.
	aStructure ifNotNil: [ dict at: 'params' put: aStructure asDictionary ].
	data := GtJson forJsonObject: dict.
	jsonData := data asJsonString.
	(GtLSPServerInputSignal new message: jsonData) emit.
	string := 'Content-Length: ' , jsonData utf8Encoded size printString
		, String crlf , String crlf , jsonData.
	mutex critical: [ socket sendData: string utf8Encoded ]
]

{ #category : 'lifecycle' }
GDZealLspTcpClient >> start [
	"Connect to the remote LSP server over TCP and spawn a background process that
	 polls the socket, accumulating bytes into a buffer and feeding them to the inherited
	 processMessagePart: parser. Reuses all JSON-RPC framing/handler logic from the parent."
	socket := Socket newTCP.
	socket connectTo: (NetNameResolver addressForName: self host) port: self port.
	socket waitForConnectionFor: 5.
	socket isConnected ifFalse: [ self error: 'Failed to connect to LSP server at ' , self host , ':' , self port printString ].
	readBuffer := ''.
	readProcess := [ 
		[ socket isConnected ] whileTrue: [
			| chunk |
			chunk := nil.
			[ socket dataAvailable ifTrue: [
				chunk := socket receiveDataTimeout: 1 ] ]
				on: Error 
				do: [ :e | nil ].
			(chunk notNil and: [ chunk notEmpty ]) 
				ifTrue: [
					| previous |
					readBuffer := readBuffer , chunk asString.
					previous := nil.
					[ readBuffer := self processMessagePart: readBuffer.
					  previous = readBuffer ] whileFalse: [ previous := readBuffer ] ]
				ifFalse: [ (Delay forMilliseconds: 20) wait ] ].
		"socket closed — notify error handlers"
		errorHandlers do: [ :h | h cull: nil ].
	] forkNamed: 'GDZeal LSP TCP reader'
]

{ #category : 'lifecycle' }
GDZealLspTcpClient >> terminate [
	"Close socket and stop the read loop. Reset all handler dictionaries (parent
	 maintains those for stdio in the same way)."
	socket ifNotNil: [
		[ socket closeAndDestroy ] on: Error do: [ :e | nil ].
		socket := nil ].
	readProcess ifNotNil: [
		(readProcess isTerminated or: [ readProcess isTerminating ])
			ifFalse: [ [ readProcess terminate ] on: Error do: [ :e | nil ] ].
		readProcess := nil ].
	readBuffer := ''.
	resultHandlers := Dictionary new.
	methodHandlers := Dictionary new.
	errorHandlers := Dictionary new
]
