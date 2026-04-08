Class {
	#name : 'GDZealLspModel',
	#superclass : 'GtLSPDirectoryModel',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
GDZealLspModel class >> defaultHost [
	^ 'localhost'
]

{ #category : 'accessing' }
GDZealLspModel class >> defaultPort [
	"Godot's GDScript LSP default port (Editor → Editor Settings → Network → Language Server)."
	^ 6005
]

{ #category : 'accessing' }
GDZealLspModel class >> extensions [
	^ '*.gd'
]

{ #category : 'accessing' }
GDZealLspModel class >> languageType [
	^ 'gdscript'
]

{ #category : 'instance creation' }
GDZealLspModel class >> onDirectory: aDirectory [
	^ self onDirectory: aDirectory host: self defaultHost port: self defaultPort
]

{ #category : 'instance creation' }
GDZealLspModel class >> onDirectory: aDirectory host: aHost port: aPort [
	"Mirror GtLSPDirectoryModel>>onDirectory: but plug in the TCP client and skip the
	 process-spawn dance — Godot's LSP is in-editor, we just connect a socket."
	| client dir semaphore model |
	semaphore := Semaphore new.
	dir := aDirectory asFileReference.
	client := (GDZealLspTcpClient host: aHost port: aPort)
		defaultLanguageType: self languageType;
		start;
		yourself.
	model := self new
		filename: dir;
		extensions: self extensions;
		lspClient: client;
		styler: self styler.
	client
		initializeIn: { dir }
		do: [ semaphore signal ]
		onError: [ semaphore signal ].
	(semaphore waitTimeoutSeconds: 10) 
		ifTrue: [ self error: 'Timed out waiting for LSP initialize handshake' ].
	self registry
		add: model
		finalizer: (ObjectFinalizer receiver: client selector: #terminate).
	^ model
]

{ #category : 'accessing' }
GDZealLspModel class >> styler [
	"No GDScript styler in GT yet — fall back to GDZeal's own theme tokenizer."
	^ GDZealTheme
]

{ #category : 'message handlers' }
GDZealLspModel >> installMessageHandlers [
	"Godot's GDScript LSP uses push-based diagnostics: it sends 
	 textDocument/publishDiagnostics notifications when it has results to report.
	 (Pull-based textDocument/diagnostic is LSP 3.17+ and Godot doesn't advertise it.)"
	lspClient
		on: 'textDocument/publishDiagnostics'
		as: GtLSPPublishDiagnosticsParamsStructure
		send: #publishDiagnostics:
		to: self
]

{ #category : 'message handlers' }
GDZealLspModel >> publishDiagnostics: each [
	"Server-pushed diagnostics for one file. Route to the matching file model."
	(self fileForUri: each uri) ifNotNil: [ :file | 
		file diagnostics: each diagnostics ]
]
