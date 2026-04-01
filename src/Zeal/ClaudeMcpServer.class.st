"
An MCP (Model Context Protocol) server that exposes Glamorous Toolkit capabilities as tools for Claude and other LLM clients.

ClaudeMcpServer wraps a GtMcpServer and registers a set of tools that allow an LLM to interact with the GT environment: evaluating Smalltalk code, browsing classes and methods, managing Lepiter knowledge base pages, and more.

## Quick Start

Start a server on a given port:

```
server := ClaudeMcpServer startOnPort: 8200.
```

Or create and configure before starting:

```
server := ClaudeMcpServer new.
server port: 8100.
server maxLength: 5000.
server start.
```

Stop the server when done:

```
server stop.
```

## Configuration

- `port:` — sets the HTTP port the MCP server listens on.
- `maxLength:` — sets the maximum character length for tool result strings (default: 2000).

## Available Tools

The server registers the following tools via `addAllTools`:

**Code browsing**
- `getImplementors` — find implementors of a method name.
- `getMethodSource` — get the source code of a method by reference (e.g. `ClassName>>#method`).
- `getPackageInfo` — list classes and methods in a package.
- `getExamples` — list gtExample methods for a class or package.

**Code editing**
- `defineClass` — define a new class.
- `defineMethod` — define or update a method on a class.
- `evaluate` — evaluate a Smalltalk expression and return the result.

**Lepiter knowledge base**
- `listPages` — list all Lepiter pages.
- `readPage` — read a page by title.
- `readSnippet` — read a snippet by UID.
- `updateSnippet` — update a snippet's content.
- `addSnippet` — add a new snippet to a page.

## Instance Variables

- `server` — the underlying `GtMcpServer` instance.
- `maxLength` — maximum character length for truncating tool output (default 2000).

"
Class {
	#name : 'ClaudeMcpServer',
	#superclass : 'Object',
	#instVars : [
		'server',
		'maxLength',
		'announcer'
	],
	#classInstVars : [
		'DefaultInstance'
	],
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'accessing' }
ClaudeMcpServer class >> default [
	^ DefaultInstance ifNil: [ DefaultInstance := self new ]
]

{ #category : 'accessing' }
ClaudeMcpServer class >> resetDefault [
	DefaultInstance ifNotNil: [ :inst | 
		[ inst stop ] on: Error do: [ "ignore" ] ].
	DefaultInstance := nil
]

{ #category : 'instance creation' }
ClaudeMcpServer class >> startOnPort: aPort [
	^ self new
		port: aPort;
		start;
		yourself
]

{ #category : 'tools' }
ClaudeMcpServer >> addAddSnippetTool [
	self addTool: (GtLlmFunctionTool new
		name: 'addSnippet';
		parameters: {'pageTitle'. 'content'. 'snippetType'};
		description: 'Adds a new snippet to a Lepiter page. snippetType can be "text" or "pharo". Returns the new snippet UID.';
		block: [ :functionCall |
			| db page args content snippetType snippet |
			args := functionCall arguments.
			db := LeDatabasesRegistry default defaultLogicalDatabase.
			page := db pageNamed: (args at: 'pageTitle') ifAbsent: [
				| newPage |
				newPage := LePage named: (args at: 'pageTitle').
				db addPage: newPage.
				newPage ].
			content := args at: 'content'.
			snippetType := args at: 'snippetType' ifAbsent: ['text'].
			snippet := snippetType = 'pharo'
				ifTrue: [LePharoSnippet code: content]
				ifFalse: [LeTextSnippet string: content].
			page addSnippet: snippet.
			'Added snippet: ', snippet uid asString ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addAddTableSnippetTool [
	self addTool: (GtLlmFunctionTool new
		name: 'addTableSnippet';
		parameters: {'pageTitle'. 'columns'. 'rows'. 'height'};
		description: 'Adds an inline table snippet (LeElementSnippet with GtPhlowColumnedListView) to a Lepiter page. columns is a JSON array of objects with "title", "key" (one of "first","second","third",... or "at1","at2",...), and optional "weight" (float, default 1). rows is a JSON array of arrays (each inner array is one row of cell values). height is optional pixel height (default "200"). Returns the new snippet UID.';
		block: [ :functionCall |
			| db page args colDefs rowData height code snippet |
			args := functionCall arguments.
			colDefs := STONJSON fromString: (args at: 'columns').
			rowData := STONJSON fromString: (args at: 'rows').
			height := (args at: 'height' ifAbsent: [ '200' ]) asInteger.

			db := LeDatabasesRegistry default defaultLogicalDatabase.
			page := db pageNamed: (args at: 'pageTitle') ifAbsent: [
				| newPage |
				newPage := LePage named: (args at: 'pageTitle').
				db addPage: newPage.
				newPage ].

			code := self buildTableCode: colDefs rows: rowData.

			snippet := LeElementSnippet new
				code: code;
				codeVisible: false;
				elementHeight: height.
			page addSnippet: snippet.
			'Added table snippet: ' , snippet uid asString ])
]

{ #category : 'initialization' }
ClaudeMcpServer >> addAllTools [
	self addGetImplementorsTool.
	self addGetMethodSourceTool.
	self addDefineClassTool.
	self addDefineMethodTool.
	self addEvaluateTool.
	self addGetPackageInfoTool.
	self addGetExamplesTool.
	self addListPagesTool.
	self addReadPageTool.
	self addReadSnippetTool.
	self addUpdateSnippetTool.
	self addAddSnippetTool.
	self addGetReferencesTool.
	self addAddTableSnippetTool.
	self addZealCompileTool.
	self addZealDefinitionTool.
	self addZealListDefinitionsTool.
	self addZealSyntaxReferenceTool.
	self addZealAddToClassTool.
	self addZealUpdateDefinitionTool.
	self addZealSetUsingsTool
]

{ #category : 'tools' }
ClaudeMcpServer >> addDefineClassTool [
	self addTool: (GtLlmFunctionTool new
		name: 'defineClass';
		parameters: {'superclassName'. 'className'. 'instanceVariableNames'. 'package'};
		description: 'Defines a new class. superclassName is the parent class (e.g., "Object"), className is the new class name, instanceVariableNames is a space-separated string of ivar names, package is the package name.';
		block: [ :functionCall |
			| args superclassName |
			args := functionCall arguments.
			superclassName := (args at: 'superclassName') asSymbol.
			(Smalltalk globals includesKey: superclassName)
				ifFalse: [ 'Superclass not found: ', superclassName ]
				ifTrue: [
					(Smalltalk globals at: superclassName)
						subclass: (args at: 'className') asSymbol
						instanceVariableNames: (args at: 'instanceVariableNames' ifAbsent: [ '' ])
						classVariableNames: ''
						package: (args at: 'package').
					'Class defined: ', (args at: 'className') ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addDefineMethodTool [
	self addTool: (GtLlmFunctionTool new
		name: 'defineMethod';
		parameters: {'className'. 'sourceCode'. 'protocol'};
		description: 'Defines or updates a method on a class. For class-side methods, append " class" to className (e.g., "MyClass class"). The sourceCode should be the complete method source including the selector.';
		block: [ :functionCall |
			| args className sourceCode protocol theClass isClassSide |
			args := functionCall arguments.
			className := args at: 'className'.
			sourceCode := args at: 'sourceCode'.
			protocol := args at: 'protocol' ifAbsent: [ 'api' ].
			isClassSide := className endsWith: ' class'.
			isClassSide ifTrue: [ className := className allButLast: 6 ].
			(Smalltalk globals includesKey: className asSymbol)
				ifFalse: [ 'Class not found: ', className ]
				ifTrue: [
					theClass := Smalltalk globals at: className asSymbol.
					isClassSide ifTrue: [ theClass := theClass class ].
					theClass compile: sourceCode classified: protocol.
					'Method defined: ', theClass name, '>>#', (sourceCode lines first copyUpTo: Character cr) ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addEvaluateTool [
	self addTool: (GtLlmFunctionTool new
		name: 'evaluate';
		parameters: {'expression'. 'maxLength'};
		description: 'Evaluates a Smalltalk expression and returns the result as a string. Results are truncated to maxLength (default 2000 characters).';
		block: [ :functionCall |
			| args result max |
			args := functionCall arguments.
			max := (args at: 'maxLength' ifAbsent: [ maxLength ]) asNumber.
			[ result := Smalltalk compiler evaluate: (args at: 'expression').
			  self truncate: result printString to: max ]
				on: Error
				do: [ :e | 'Error: ', e class name, ' - ', e messageText ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addGetExamplesTool [
	self addTool: (GtLlmFunctionTool new
		name: 'getExamples';
		parameters: {'name'. 'type'};
		description: 'Gets gtExample methods. Type can be "class" (examples defined in that class, including inherited) or "package" (all examples in package). Returns method names and first lines of code.';
		block: [ :functionCall |
			| args name type examples |
			args := functionCall arguments.
			name := args at: 'name'.
			type := args at: 'type' ifAbsent: [ 'class' ].
			[ examples := type = 'package'
				ifTrue: [ | pkg |
					pkg := RPackageOrganizer default packageNamed: name asSymbol.
					pkg definedClasses flatCollect: [:cls |
						(cls methods, cls class methods) select: [:m | m hasPragmaNamed: #gtExample ]]]
				ifFalse: [ | cls |
					cls := Smalltalk globals at: name asSymbol.
					((Pragma allNamed: #gtExample from: cls to: Object),
					 (Pragma allNamed: #gtExample from: cls class to: Object class))
						reject: [:p | p method methodClass instanceSide == Object]
						thenCollect: [:p | p method]] ]
				on: Error
				do: [ :e | examples := nil ].
			examples
				ifNil: [ 'Not found: ', name, ' (type: ', type, ')' ]
				ifNotNil: [
					String streamContents: [:s |
						s nextPutAll: 'Examples: '; nextPutAll: examples size asString; cr; cr.
						examples do: [:m |
							s nextPutAll: m methodClass name; nextPutAll: '>>#'; nextPutAll: m selector; cr.
							s nextPutAll: '  '; nextPutAll: (m sourceCode lines first: (3 min: m sourceCode lines size)) asString; cr; cr ]] ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addGetImplementorsTool [
	self addTool: (GtLlmFunctionTool new
		name: 'getImplementors';
		parameters: {'methodName'};
		description: 'Gets a method by name and returns a list of methods that implement it.';
		block: [ :functionCall |
			[ Character cr join:
				(functionCall anyArgument asSymbol gtImplementors result toArray wait
					collect: #name) ]
				on: Error
				do: [ :e | 'Error looking up implementors: ', e messageText ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addGetMethodSourceTool [
	self addTool: (GtLlmFunctionTool new
		name: 'getMethodSource';
		parameters: {'methodReference'};
		description: 'Gets the source code for a method. Takes a method reference in the format "ClassName>>#methodName" for instance methods or "ClassName class>>#methodName" for class methods.';
		block: [ :functionCall |
			| ref parts className selector theClass isClassSide |
			ref := functionCall anyArgument.
			parts := ref splitOn: '>>#'.
			parts size = 2
				ifFalse: [ 'Invalid format. Use ClassName>>#method or ClassName class>>#method' ]
				ifTrue: [
					className := parts first.
					selector := parts second asSymbol.
					isClassSide := className endsWith: ' class'.
					isClassSide ifTrue: [ className := className allButLast: 6 ].
					(Smalltalk globals includesKey: className asSymbol)
						ifFalse: [ 'Class not found: ', className ]
						ifTrue: [
							theClass := Smalltalk globals at: className asSymbol.
							isClassSide ifTrue: [ theClass := theClass class ].
							(theClass includesSelector: selector)
								ifFalse: [ 'Method not found: ', ref ]
								ifTrue: [ (theClass >> selector) sourceCode ] ] ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addGetPackageInfoTool [
	self addTool: (GtLlmFunctionTool new
		name: 'getPackageInfo';
		parameters: {'packageName'};
		description: 'Gets information about a package: its classes and their methods.';
		block: [ :functionCall |
			| pkgName pkg classes output |
			pkgName := functionCall anyArgument asSymbol.
			[ pkg := RPackageOrganizer default packageNamed: pkgName ]
				on: Error
				do: [ :e | pkg := nil ].
			pkg
				ifNil: [ 'Package not found: ', pkgName ]
				ifNotNil: [
					classes := pkg definedClasses sorted: [:a :b | a name < b name].
					String streamContents: [:s |
						s nextPutAll: 'Package: '; nextPutAll: pkg name; cr.
						s nextPutAll: 'Classes: '; nextPutAll: classes size asString; cr; cr.
						classes do: [:cls |
							s nextPutAll: cls name; cr.
							s nextPutAll: '  superclass: '; nextPutAll: cls superclass name; cr.
							s nextPutAll: '  ivars: '; nextPutAll: cls instVarNames printString; cr.
							s nextPutAll: '  methods: '; nextPutAll: cls methods size asString; cr ]] ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addGetReferencesTool [
	self addTool: (GtLlmFunctionTool new
		name: 'getReferences';
		parameters: {'name'. 'type'};
		description: 'Gets references to a name. Type can be "class" (all references to a class) or "selector" (all senders of a selector). Returns a list of method references.';
		block: [ :functionCall |
			| args name type results |
			args := functionCall arguments.
			name := args at: 'name'.
			type := args at: 'type'.
			
			results := [
				type = 'class'
					ifTrue: [
						| classSymbol theClass binding |
						classSymbol := name asSymbol.
						(Smalltalk globals includesKey: classSymbol)
							ifFalse: [ ^ 'Class not found: ', name ].
						theClass := Smalltalk globals at: classSymbol.
						binding := theClass binding.
						SystemNavigation default allReferencesTo: binding ]
					ifFalse: [ type = 'selector'
						ifTrue: [
							SystemNavigation default allSendersOf: name asSymbol ]
						ifFalse: [ ^ 'Invalid type: ', type, '. Must be "class" or "selector".' ] ]
			] on: Error do: [ :e | ^ 'Error finding references: ', e messageText ].
			
			results isEmpty
				ifTrue: [ 'No references found' ]
				ifFalse: [
					Character cr join: (results collect: [ :method |
						method methodClass name, '>>#', method selector ]) ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addListPagesTool [
	self addTool: (GtLlmFunctionTool new
		name: 'listPages';
		parameters: #('query');
		description: 'Lists Lepiter pages with their titles and UIDs. The optional query parameter filters pages by case-insensitive substring match on the title. Without a query, lists all pages (may be truncated).';
		block: [ :functionCall |
			| db pages query |
			db := LeDatabasesRegistry default defaultLogicalDatabase.
			query := functionCall arguments at: 'query' ifAbsent: [ nil ].
			pages := db pages sorted: [ :a :b | a title < b title ].
			(query notNil and: [ query isNotEmpty ]) ifTrue: [
				pages := pages select: [ :page |
					page title asLowercase includesSubstring: query asLowercase ] ].
			String streamContents: [ :s |
				s nextPutAll: 'Pages ('; nextPutAll: pages size asString; nextPutAll: ' results)'; cr; cr.
				pages do: [ :page |
					s nextPutAll: page uid asString; nextPutAll: ' | '; nextPutAll: page title; cr ] ] ])
]

{ #category : 'tools - lepiter' }
ClaudeMcpServer >> addReadPageTool [
	self addTool: (GtLlmFunctionTool new
		name: 'readPage';
		parameters: {'pageTitle'};
		description: 'Reads a Lepiter page by title. Returns snippets with their UIDs, types, and content.';
		block: [ :functionCall |
			| db page |
			db := LeDatabasesRegistry default defaultLogicalDatabase.
			page := db pages 
				detect: [ :p | p title = functionCall anyArgument ] 
				ifNone: [ nil ].
			page
				ifNil: [ 'Page not found: ', functionCall anyArgument ]
				ifNotNil: [
					String streamContents: [:s |
						s nextPutAll: 'Page: '; nextPutAll: page title; cr.
						s nextPutAll: 'UID: '; nextPutAll: page uid asString; cr.
						s nextPutAll: 'Snippets: '; nextPutAll: page children size asString; cr; cr.
						page children withIndexDo: [:snippet :idx |
							s nextPutAll: idx asString; nextPutAll: '. '.
							s nextPutAll: '['; nextPutAll: snippet class name; nextPutAll: ']'; cr.
							s nextPutAll: '   UID: '; nextPutAll: snippet uid asString; cr.
							s nextPutAll: '   Content: '; nextPutAll: (snippet isTextualSnippet 
								ifTrue: [snippet string] 
								ifFalse: ['(non-textual snippet)']); cr; cr ]] ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addReadSnippetTool [
	self addTool: (GtLlmFunctionTool new
		name: 'readSnippet';
		parameters: {'snippetUid'};
		description: 'Reads a specific Lepiter snippet by UID. Returns full content.';
		block: [ :functionCall |
			| db snippet uid |
			uid := LeUID new uidString: functionCall anyArgument.
			db := LeDatabasesRegistry default defaultLogicalDatabase.
			[ snippet := db snippetWithUID: uid ]
				on: Error
				do: [ :e | snippet := nil ].
			snippet
				ifNil: [ 'Snippet not found for UID: ', functionCall anyArgument ]
				ifNotNil: [
					String streamContents: [:s |
						s nextPutAll: 'Type: '; nextPutAll: snippet class name; cr.
						s nextPutAll: 'UID: '; nextPutAll: snippet uid asString; cr; cr.
						s nextPutAll: 'Content:'; cr.
						s nextPutAll: (snippet isTextualSnippet 
							ifTrue: [snippet string] 
							ifFalse: ['(non-textual snippet)'])] ] ])
]

{ #category : 'tools' }
ClaudeMcpServer >> addTool: aGtLlmFunctionTool [
        "Wrap the tool's block so the result is always truncated before being returned."
        | originalBlock |
        originalBlock := aGtLlmFunctionTool block.
        aGtLlmFunctionTool block: [ :call | self truncate: (originalBlock value: call) ].
        server addTool: aGtLlmFunctionTool
]

{ #category : 'tools' }
ClaudeMcpServer >> addUpdateSnippetTool [
	self addTool: (GtLlmFunctionTool new
		name: 'updateSnippet';
		parameters: {'snippetUid'. 'content'};
		description: 'Updates a Lepiter snippet content by UID. Only works for textual snippets.';
		block: [ :functionCall |
			| db snippet uid args content |
			args := functionCall arguments.
			uid := LeUID new uidString: (args at: 'snippetUid').
			content := args at: 'content'.
			db := LeDatabasesRegistry default defaultLogicalDatabase.
			[ snippet := db snippetWithUID: uid ]
				on: Error
				do: [ :e | snippet := nil ].
			snippet
				ifNil: [ 'Snippet not found for UID: ', (args at: 'snippetUid') ]
				ifNotNil: [
					snippet isTextualSnippet
						ifFalse: [ 'Error: Cannot update non-textual snippet (', snippet class name, ')' ]
						ifTrue: [
							snippet updateString: content.
							'Updated snippet: ', snippet uid asString ] ] ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealAddToClassTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealAddToClass';
		parameters: {'className'. 'zealCode'};
		description: 'Adds a field or method to a class, or replaces the entire class. Persists changes.';
		block: [ :functionCall |
			[
				| args className code browser selectedClass compiled result |
				args := functionCall arguments.
				className := args at: 'className'.
				code := args at: 'zealCode'.
				browser := ZealBrowser allInstances detect: [:b | b isAttachedToSceneGraph] ifNone: [nil].
				browser ifNil: [ ^ 'Error: No active ZealBrowser' ].
				selectedClass := nil.
				(browser instVarNamed: 'project') modules do: [:mod |
					(mod instVarNamed: 'definitions') do: [:d |
						((d isKindOf: ZealClass) or: [(d isKindOf: ZealInterface)]) ifTrue: [
							(d name = className or: [d name = (ZealNode new toKebabCase: className)]) ifTrue: [
								selectedClass := d ] ] ] ].
				selectedClass ifNil: [ ^ String streamContents: [:s | s nextPutAll: 'Error: Class not found: '; nextPutAll: className] ].
				compiled := ZealCompiler compile: code.
				(compiled isKindOf: ZealCompileError) ifTrue: [ ^ String streamContents: [:s | s nextPutAll: 'Compile error: '; nextPutAll: compiled printString] ].
				compiled := (compiled isKindOf: Collection) ifTrue: [compiled first] ifFalse: [compiled].
				
				((compiled isKindOf: ZealClass) or: [(compiled isKindOf: ZealInterface)]) ifTrue: [
					| mod defs |
					mod := nil.
					(browser instVarNamed: 'project') modules do: [:m |
						((m instVarNamed: 'definitions') includes: selectedClass) ifTrue: [mod := m]].
					mod ifNil: [ ^ 'Error: Module not found for class' ].
					defs := (mod instVarNamed: 'definitions') asOrderedCollection.
					defs at: (defs indexOf: selectedClass) put: compiled.
					compiled generatedClass: selectedClass generatedClass.
					mod instVarNamed: 'definitions' put: defs asArray.
					selectedClass := compiled.
					result := String streamContents: [:s | s nextPutAll: 'Replaced '; nextPutAll: (compiled class name copyReplaceAll: 'Zeal' with: ''); nextPutAll: ' "'; nextPutAll: compiled name; nextPutAll: '"'] ]
				ifFalse: [
					((compiled isKindOf: ZealFunction) or: [(compiled isKindOf: ZealVariable)]) ifFalse: [
						^ String streamContents: [:s | s nextPutAll: 'Error: Expected def/var/defn/defclass, got '; nextPutAll: compiled class name] ].
					browser addCompiled: compiled to: selectedClass.
					result := String streamContents: [:s | s nextPutAll: 'Added '; nextPutAll: (compiled class name copyReplaceAll: 'Zeal' with: ''); nextPutAll: ' "'; nextPutAll: compiled name; nextPutAll: '" to '; nextPutAll: className] ].
				
				browser persistNode: selectedClass.
				browser enqueueTask: (BlTaskAction new action: [
					browser rebuildTree. browser selectNode: selectedClass ]).
				result
			] on: Error do: [:e | String streamContents: [:s | s nextPutAll: 'Error: '; nextPutAll: e messageText] ] ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealCompileTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealCompile';
		parameters: {'zealSource'};
		description: 'Compiles Zeal source code to Verse output. Returns the generated Verse code or an error message.';
		block: [ :functionCall |
			| src result |
			src := functionCall arguments at: 'zealSource'.
			[ result := ZealCompiler compile: src.
			  result := (result isKindOf: Collection) ifTrue: [result first] ifFalse: [result].
			  result compileToVerse ]
				on: Error
				do: [ :e | String streamContents: [:s | s nextPutAll: 'Compile error: '; nextPutAll: e messageText] ] ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealDefinitionTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealGetDefinition';
		parameters: {'name'};
		description: 'Gets structured info about a definition — type, fields, methods, usings, and source.';
		block: [ :functionCall |
			[self handleGetDefinition: (functionCall arguments at: 'name')]
				on: Error do: [:e | String streamContents: [:s | s nextPutAll: 'Error: '; nextPutAll: e messageText]] ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealListDefinitionsTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealListDefinitions';
		parameters: {'moduleName'};
		description: 'Lists all definitions in a Zeal module. Pass empty string to list all modules. Returns names and types.';
		block: [ :functionCall |
			| modName result |
			modName := functionCall arguments at: 'moduleName'.
			result := String streamContents: [:s |
				ZealBrowser allInstances do: [:b |
					| proj |
					proj := b instVarNamed: 'project'.
					(modName isEmpty or: [modName = '']) ifTrue: [
						s nextPutAll: 'Project: ', proj name; cr.
						proj modules do: [:mod |
							s nextPutAll: '  Module: ', mod name, ' (', (mod instVarNamed: 'definitions') size printString, ' definitions)'; cr ] ]
					ifFalse: [
						proj modules do: [:mod |
							(mod name = modName) ifTrue: [
								(mod instVarNamed: 'definitions') do: [:d |
									s nextPutAll: d class name allButFirst: 4. "Strip 'Zeal'"
									s nextPutAll: ': ', d name; cr ] ] ] ] ] ].
			result trimBoth ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealSetUsingsTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealSetUsings';
		parameters: {'name'. 'usings'};
		description: 'Sets the using declarations on a definition. Pass the definition name and a comma-separated list of module paths.
Example: zealSetUsings("cute-kitty", "/Verse.org/Random, /Fortnite.com/Devices")
Pass empty string to clear all usings.';
		block: [ :functionCall |
			[
				| args defName usingStr browser proj found paths |
				args := functionCall arguments.
				defName := args at: 'name'.
				usingStr := args at: 'usings'.
				browser := ZealBrowser allInstances detect: [:b | b isAttachedToSceneGraph] ifNone: [nil].
				browser ifNil: [ ^ 'Error: No active ZealBrowser' ].
				proj := browser instVarNamed: 'project'.
				
				found := nil.
				proj modules do: [:mod |
					(mod instVarNamed: 'definitions') do: [:d |
						(d name = defName or: [d name = (ZealNode new toKebabCase: defName)]) ifTrue: [
							found := d ] ] ].
				found ifNil: [ ^ String streamContents: [:s | s nextPutAll: 'Error: Definition "'; nextPutAll: defName; nextPutAll: '" not found'] ].
				
				"Parse comma-separated paths"
				paths := (usingStr substrings: ',') collect: [:p | p trimBoth].
				paths := paths reject: [:p | p isEmpty].
				found usings: (paths collect: [:p | ZealUsing new path: p]).
				
				"Persist"
				found generatedClass ifNotNil: [:genClass |
					| zealSrc verseSrc |
					zealSrc := [found compileToZeal] on: Error do: [''].
					verseSrc := [found compileToVerse] on: Error do: [''].
					genClass class compile: (String streamContents: [:s | s nextPutAll: 'zealSource'; lf; tab; nextPutAll: '^ '; nextPutAll: zealSrc printString]) classified: 'zeal'.
					genClass class compile: (String streamContents: [:s | s nextPutAll: 'verseSource'; lf; tab; nextPutAll: '^ '; nextPutAll: verseSrc printString]) classified: 'zeal' ].
				
				browser enqueueTask: (BlTaskAction new action: [browser selectNode: found]).
				
				paths isEmpty
					ifTrue: [ 'Cleared usings on "', defName, '"' ]
					ifFalse: [ String streamContents: [:s | s nextPutAll: 'Set usings on "'; nextPutAll: defName; nextPutAll: '": '; nextPutAll: (', ' join: paths)] ]
			] on: Error do: [:e | String streamContents: [:s | s nextPutAll: 'Error: '; nextPutAll: e messageText] ] ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealSyntaxReferenceTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealSyntaxReference';
		parameters: #();
		description: 'Returns the Zeal language syntax reference.';
		block: [ :functionCall |
'# Zeal Language Reference

Zeal is a Lisp-syntax language that transpiles to Epic Verse (UEFN).
Code blocks should use ```zeal (NOT clojure or lisp).

## Class names use @ prefix
All class, interface, struct, and enum names are prefixed with @.
This distinguishes types from functions/variables.

## Definitions
(defn name:specifiers:return-type [param1:type1 param2:type2] body)
(defclass @name [@parent1 @parent2] body)
(definterface @name [@parent1] body)
(defstruct @name [field1:type default] [field2:type default])
(defenum @name val1 val2 val3)
(def name:type value)          — immutable field
(var name:type value)          — mutable field
(defmodule name)               — module declaration

## Constructor / Archetype
(@class-name :field1 val1 :field2 val2) — creates an instance

## Control Flow
(if cond then)                 — single branch
(if cond then-expr else-expr)  — if/else (positional)
(for [x 1..10] body)          — for with range
(for [item collection] body)  — for with collection
(for [x 1..10 (> x 3) (< x 8)] body) — for with predicates
(loop body)                    — infinite loop
(case val (pattern1 expr1) (pattern2 expr2)) — pattern match
(block body)                   — block expression
(defer expr)                   — deferred execution
(break)                        — break from loop
(return expr)                  — early return

## Member Access
obj/field                      — property access (-> obj.Field in Verse)
(obj/method args)              — method call (-> obj.Method(args) in Verse)

## Operators
(+ a b) (- a b) (* a b) (/ a b) — arithmetic (wrapped in parens)
(= a b) (<> a b) (< a b) (> a b) — comparison
(? something)                  — query/failable
(and a b) (or a b) (not a)    — logical
(set x value)                  — mutation
(:= name value)                — binding

## Types
:int :float :string :logic :void :char — basic types
:type?                         — optional type (-> ?type in Verse)
[]:type                        — array type
Type inference: (var x 42) infers :int, (var d (@my-class :field 1)) infers :@my-class

## Abstract Methods
(defn name:type [])            — empty body = abstract

## Specifiers (colon chain on name)
name:public:override:suspends:void
<public> <private> <internal> <final> <abstract> <override> <unique>
<transacts> <decides> <suspends> <varies> <converges> <computes>
' ])
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> addZealUpdateDefinitionTool [
	self addTool: (GtLlmFunctionTool new
		name: 'zealUpdateDefinition';
		parameters: {'name'. 'zealCode'};
		description: 'Updates or replaces any top-level definition by name. Pass the full new Zeal source. Persists to generated class and .verse file.';
		block: [ :functionCall |
			[
				| args name code browser proj found foundMod compiled |
				args := functionCall arguments.
				name := args at: 'name'.
				code := args at: 'zealCode'.
				browser := ZealBrowser allInstances detect: [:b | b isAttachedToSceneGraph] ifNone: [nil].
				browser ifNil: [ ^ 'Error: No active ZealBrowser' ].
				proj := browser instVarNamed: 'project'.
				
				found := nil. foundMod := nil.
				proj modules do: [:mod |
					(mod instVarNamed: 'definitions') do: [:d |
						(d name = name or: [d name = (ZealNode new toKebabCase: name)]) ifTrue: [
							found := d. foundMod := mod ] ] ].
				
				compiled := ZealCompiler compile: code.
				(compiled isKindOf: ZealCompileError) ifTrue: [ 
					^ String streamContents: [:s | s nextPutAll: 'Compile error: '; nextPutAll: compiled printString] ].
				compiled := (compiled isKindOf: Collection) ifTrue: [compiled first] ifFalse: [compiled].
				
				found ifNotNil: [
					| defs idx |
					compiled generatedClass: found generatedClass.
					defs := (foundMod instVarNamed: 'definitions') asOrderedCollection.
					idx := defs indexOf: found.
					idx > 0 ifTrue: [ defs at: idx put: compiled ] ifFalse: [ defs add: compiled ].
					foundMod instVarNamed: 'definitions' put: defs asArray ]
				ifNil: [
					| mod defs |
					mod := proj modules first.
					defs := (mod instVarNamed: 'definitions') asOrderedCollection.
					defs add: compiled.
					mod instVarNamed: 'definitions' put: defs asArray ].
				
				"Persist using browser's unified method"
				browser persistNode: compiled.
				
				browser enqueueTask: (BlTaskAction new action: [
					browser instVarNamed: 'selectedNode' put: nil.
					browser rebuildTree.
					browser selectNode: compiled ]).
				
				String streamContents: [:s |
					s nextPutAll: (found ifNotNil: ['Replaced '] ifNil: ['Added new ']).
					s nextPutAll: (compiled class name copyReplaceAll: 'Zeal' with: '').
					s nextPutAll: ' "'; nextPutAll: compiled name; nextPutAll: '"' ]
			] on: Error do: [:e | String streamContents: [:s | s nextPutAll: 'Error: '; nextPutAll: e messageText] ] ])
]

{ #category : 'accessing' }
ClaudeMcpServer >> announcer [
	^ announcer ifNil: [ announcer := Announcer new ]
]

{ #category : 'private' }
ClaudeMcpServer >> buildTableCode: colDefs rows: rowData [
	"Build the Smalltalk code string for a LeElementSnippet that renders a table.
	colDefs is an array of dictionaries with 'title' and optional 'weight'.
	rowData is an array of arrays (each inner array is one row).
	Since we build the code string programmatically (not as a literal),
	embedded strings use single quotes only. The snippet evaluates this code directly."

	| stream q |
	stream := String new writeStream.
	q := ''''.
	stream
		nextPutAll: '| view |'; cr;
		nextPutAll: 'view := GtPhlowColumnedListView new.'; cr;
		nextPutAll: 'view items: [ {'; cr.

	rowData doWithIndex: [ :row :rowIndex |
		stream nextPutAll: '  { '.
		row doWithIndex: [ :cell :cellIndex |
			| escaped |
			escaped := cell asString copyReplaceAll: q with: q, q.
			stream
				nextPut: $';
				nextPutAll: escaped;
				nextPut: $'.
			cellIndex < row size ifTrue: [ stream nextPutAll: '. ' ] ].
		stream nextPutAll: ' }'.
		rowIndex < rowData size ifTrue: [ stream nextPut: $. ].
		stream cr ].

	stream nextPutAll: '} ].'; cr.

	colDefs doWithIndex: [ :col :index |
		| title weight escaped |
		escaped := (col at: 'title') copyReplaceAll: q with: q, q.
		weight := col at: 'weight' ifAbsent: [ nil ].
		stream
			nextPutAll: 'view column: ';
			nextPut: $';
			nextPutAll: escaped;
			nextPut: $';
			nextPutAll: ' text: [ :row | row at: ';
			nextPutAll: index asString;
			nextPutAll: ' ]'.
		weight ifNotNil: [
			stream nextPutAll: ' weight: '; nextPutAll: weight asString ].
		stream nextPut: $.; cr ].

	stream nextPutAll: 'view asElement'.
	^ stream contents
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> emitClassInfo: aNode on: s lf: lf [
	"Emit structured class/interface info"
	(aNode respondsTo: #superclass) ifTrue: [
		aNode superclass ifNotNil: [:sc | s nextPutAll: 'Extends: '; nextPutAll: sc; nextPutAll: lf]].
	((aNode respondsTo: #interfaces) and: [aNode interfaces notNil]) ifTrue: [
		aNode interfaces notEmpty ifTrue: [
			s nextPutAll: 'Interfaces: '; nextPutAll: (aNode interfaces joinUsing: ', '); nextPutAll: lf]].
	
	"Fields"
	((aNode respondsTo: #fields) and: [aNode fields notNil]) ifTrue: [
		aNode fields notEmpty ifTrue: [
			s nextPutAll: lf; nextPutAll: 'Fields:'; nextPutAll: lf.
			aNode fields do: [:f |
				| mut |
				mut := (f respondsTo: #isMutable) ifTrue: [f isMutable] ifFalse: [false].
				s nextPutAll: '  '.
				mut ifTrue: [s nextPutAll: 'var '] ifFalse: [s nextPutAll: 'def '].
				s nextPutAll: f name.
				(f respondsTo: #type) ifTrue: [f type ifNotNil: [:t | s nextPutAll: ':'; nextPutAll: t]].
				s nextPutAll: lf ] ] ].
	
	"Methods"
	((aNode respondsTo: #methods) and: [aNode methods notNil]) ifTrue: [
		aNode methods notEmpty ifTrue: [
			s nextPutAll: lf; nextPutAll: 'Methods:'; nextPutAll: lf.
			aNode methods do: [:m |
				s nextPutAll: '  '; nextPutAll: m name.
				m type ifNotNil: [:t | s nextPutAll: ':'; nextPutAll: t].
				s nextPutAll: '('.
				s nextPutAll: ((m parameters collect: [:p | 
					p name, ':', (p type ifNil: ['any'])]) joinUsing: ', ').
				s nextPutAll: ')'; nextPutAll: lf ] ] ]
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> emitFunctionInfo: aNode on: s lf: lf [
	"Emit structured function info"
	s nextPutAll: 'Return: '; nextPutAll: (aNode type ifNil: ['void']); nextPutAll: lf.
	s nextPutAll: 'Params: '.
	s nextPutAll: ((aNode parameters collect: [:p | 
		p name, ':', (p type ifNil: ['any'])]) joinUsing: ', ').
	s nextPutAll: lf
]

{ #category : 'gt-actions' }
ClaudeMcpServer >> gtClearHistoryActionFor: anAction [
	<gtAction>
	^ anAction button
		priority: 5;
		icon: BrGlamorousVectorIcons cancel;
		tooltip: 'Clear history and tool usage stats';
		action: [ :aButton |
			server clearHistory.
			aButton phlow fireToolUpdateWish ]
]

{ #category : 'gt-views' }
ClaudeMcpServer >> gtHistoryFor: aView [
	<gtView>
	^ aView forward
		title: 'History';
		priority: 5;
		object: [ server ];
		view: #gtHistoryFor:
]

{ #category : 'gt-actions' }
ClaudeMcpServer >> gtInspectServerActionFor: anAction [
	<gtAction>
	^ anAction button
		priority: 10;
		icon: BrGlamorousVectorIcons inspect;
		tooltip: 'Inspect MCP server';
		action: [ :aButton | aButton phlow spawnObject: server ]
]

{ #category : 'gt-views' }
ClaudeMcpServer >> gtLiveLogFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Live log';
		priority: 4;
		items: [ self parsedHistory reversed ];
		column: '#' text: [ :each :idx | idx ] width: 40;
		column: 'Tool' text: [ :each | each at: #toolName ] width: 130;
		column: 'Arguments' text: [ :each |
			| args |
			args := each at: #arguments.
			args isDictionary
				ifTrue: [ 
					(', ' join: (args associations collect: [ :a |
						a key, ': ', (a value asString truncateTo: 40) ])) truncateTo: 120 ]
				ifFalse: [ args asString truncateTo: 120 ] ];
		column: 'Error' text: [ :each |
			(each at: #isError)
				ifTrue: [ 'Yes' ]
				ifFalse: [ '' ] ] width: 50;
		actionUpdateButton
]

{ #category : 'gt-views' }
ClaudeMcpServer >> gtOverviewFor: aView [
	<gtView>
	^ aView columnedList
		title: 'Overview';
		priority: 1;
		items: [
			| znServer isRunning |
			znServer := server instVarNamed: 'server'.
			isRunning := znServer notNil and: [ znServer isRunning ].
			{
				'Status' -> (isRunning ifTrue: [ 'Running' ] ifFalse: [ 'Stopped' ]).
				'Port' -> server port.
				'Max length' -> maxLength.
				'Tools' -> server tools size.
				'Debug' -> server isDebug
			} ];
		column: 'Property' text: [ :assoc | assoc key ];
		column: 'Value' text: [ :assoc | assoc value ]
]

{ #category : 'gt-actions' }
ClaudeMcpServer >> gtStartStopActionFor: anAction [
	<gtAction>
	^ anAction button
		priority: 1;
		icon: BrGlamorousVectorIcons play;
		tooltip: 'Start/Stop server';
		action: [ :aButton :aTab |
			| znServer isRunning |
			znServer := server instVarNamed: 'server'.
			isRunning := znServer notNil and: [ znServer isRunning ].
			isRunning
				ifTrue: [ self stop ]
				ifFalse: [ self start ].
			aButton phlow fireToolUpdateWish ]
]

{ #category : 'gt-views' }
ClaudeMcpServer >> gtToolUsageFor: aView [
	<gtView>
	^ aView explicit
		title: 'Tool usage';
		priority: 3;
		stencil: [ | parsed counts toolCounts theData maxCount |
			parsed := self parsedHistory.
			parsed
				ifEmpty: [ BrLabel new
						aptitude: BrGlamorousLabelAptitude new;
						text: 'No history yet' ]
				ifNotEmpty: [ counts := Dictionary new.
					parsed
						do: [ :each | 
							| name |
							name := each at: #toolName.
							counts at: name put: (counts at: name ifAbsent: [ 0 ]) + 1 ].
					toolCounts := counts associations sorted: [ :a :b | a value > b value ].
					theData := GtPlotterDataGroup new values: toolCounts.
					theData := theData labelled: [ :each | each key ].
					theData := theData
							background: [ :each | 
								Color
									r: 66
									g: 188
									b: 238
									range: 255 ].
					maxCount := toolCounts first value.
					GtPlotterHorizontalBarChart new
						barLabelSpacing: 150;
						barWidthScale: (GtPlotterLinearScale new domainFrom: 0 to: maxCount);
						barWidthData: [ :each | each value ];
						amountOfTicks: (maxCount min: 10);
						tickLabelFormat: [ :val | val truncated asString ];
						barElement: [ :aGtPlotterContext | 
							BlElement new
								aptitude: ((BrGlamorousWithExplicitTooltipAptitude
										text: aGtPlotterContext originalValue key , ': '
												, aGtPlotterContext originalValue value asString)
										hideDelay: 0;
										showDelay: 0) ];
						with: theData ] ]
]

{ #category : 'gt-views' }
ClaudeMcpServer >> gtToolsFor: aView [
	<gtView>
	server tools ifEmpty: [ ^ aView empty ].
	^ aView forward
		title: 'Tools';
		priority: 2;
		object: [ server tools ];
		view: #gtItemsFor:
]

{ #category : 'tools - zeal' }
ClaudeMcpServer >> handleGetDefinition: name [
	"Look up a Zeal definition and return structured info"
	| found kebabName allDefs lf typeName |
	kebabName := ZealNode new toKebabCase: name.
	found := nil.
	allDefs := OrderedCollection new.
	ZealBrowser allInstances do: [:b |
		found ifNil: [
			(b instVarNamed: 'project') modules do: [:mod |
				(mod instVarNamed: 'definitions') do: [:d |
					allDefs add: d name.
					(d name = name or: [d name = kebabName]) ifTrue: [found := d]]]]].
	
	found ifNil: [
		| closest |
		closest := allDefs detect: [:n | n includesSubstring: name caseSensitive: false] ifNone: [nil].
		^ closest 
			ifNotNil: ['Not found. Did you mean "', closest, '"?']
			ifNil: ['Definition "', name, '" not found']].
	
	lf := String lf.
	typeName := found class name copyReplaceAll: 'Zeal' with: ''.
	
	^ String streamContents: [:s |
		s nextPutAll: 'Type: '; nextPutAll: typeName; nextPutAll: lf.
		s nextPutAll: 'Name: '; nextPutAll: found name; nextPutAll: lf.
		
		found usings notEmpty ifTrue: [
			s nextPutAll: 'Usings: '.
			s nextPutAll: ((found usings collect: [:u | (u respondsTo: #path) ifTrue: [u path] ifFalse: [u printString]]) joinUsing: ', ').
			s nextPutAll: lf].
		
		found specifiers notEmpty ifTrue: [
			s nextPutAll: 'Specifiers: '; nextPutAll: (found specifiers joinUsing: ', '); nextPutAll: lf].
		
		"Class/Interface"
		((found isKindOf: ZealClass) or: [found isKindOf: ZealInterface]) ifTrue: [
			self emitClassInfo: found on: s lf: lf].
		
		"Function"
		(found isKindOf: ZealFunction) ifTrue: [
			self emitFunctionInfo: found on: s lf: lf].
		
		s nextPutAll: lf; nextPutAll: 'Zeal source:'; nextPutAll: lf.
		s nextPutAll: ([found compileToZeal] on: Error do: ['(error)']); nextPutAll: lf.
		s nextPutAll: lf; nextPutAll: 'Verse output:'; nextPutAll: lf.
		s nextPutAll: ([found compileToVerse] on: Error do: ['(error)'])]
]

{ #category : 'initialization' }
ClaudeMcpServer >> initialize [
	super initialize.
	maxLength := 2000.
	server := GtMcpServer new port: 3030.
]

{ #category : 'accessing' }
ClaudeMcpServer >> maxLength [
	^ maxLength
]

{ #category : 'accessing' }
ClaudeMcpServer >> maxLength: aNumber [
	maxLength := aNumber
]

{ #category : 'private' }
ClaudeMcpServer >> parsedHistory [
	"Parse history into a collection of dictionaries with keys: toolName, arguments, result, isError, request, response"
	| history |
	history := server instVarNamed: 'history'.
	^ history collect: [ :assoc |
		| reqJson respJson params toolName args result isError |
		reqJson := [ NeoJSONReader fromString: assoc key entity contents ] on: Error do: [ :e | Dictionary new ].
		respJson := [ NeoJSONReader fromString: assoc value entity contents ] on: Error do: [ :e | Dictionary new ].
		params := reqJson at: 'params' ifAbsent: [ Dictionary new ].
		toolName := params at: 'name' ifAbsent: [ reqJson at: 'method' ifAbsent: [ '?' ] ].
		args := params at: 'arguments' ifAbsent: [ Dictionary new ].
		result := respJson at: 'result' ifAbsent: [ Dictionary new ].
		isError := (result isDictionary and: [ result at: 'isError' ifAbsent: [ false ] ]).
		{ 
			#toolName -> toolName.
			#arguments -> args.
			#result -> result.
			#isError -> isError.
			#request -> assoc key.
			#response -> assoc value
		} asDictionary ]
]

{ #category : 'accessing' }
ClaudeMcpServer >> port [
	^ server port
]

{ #category : 'accessing' }
ClaudeMcpServer >> port: aPort [
	server port: aPort
]

{ #category : 'accessing' }
ClaudeMcpServer >> server [
	^ server
]

{ #category : 'controlling' }
ClaudeMcpServer >> start [
	server tools removeAll.
	self addAllTools.
	server start.
	self announcer announce: ClaudeMcpServerStarted new.
	^ self
]

{ #category : 'controlling' }
ClaudeMcpServer >> stop [
	server stop.
	self announcer announce: ClaudeMcpServerStopped new
]

{ #category : 'utilities' }
ClaudeMcpServer >> truncate: aString [
	^ self truncate: aString to: maxLength
]

{ #category : 'utilities' }
ClaudeMcpServer >> truncate: aString to: max [
	^ aString size > max
		ifTrue: [ (aString first: max), '... (truncated, ', (aString size - max) asString, ' more chars)' ]
		ifFalse: [ aString ]
]
