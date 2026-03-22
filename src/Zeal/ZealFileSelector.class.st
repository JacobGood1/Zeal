Class {
	#name : 'ZealFileSelector',
	#superclass : 'BrFileSelector',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'building' }
ZealFileSelector >> createBreadcrumb [
	| bc |
	bc := super createBreadcrumb.
	bc allChildrenBreadthFirstDo: [:child |
		(child isKindOf: BrLabel) ifTrue: [
			child aptitude foreground: ZealTheme foregroundColor ] ].
	^ bc
]

{ #category : 'building' }
ZealFileSelector >> createTable [
	| aTable labelColor |
	labelColor := ZealTheme foregroundColor.
	aTable := BrColumnedList new.
	aTable 
		rowStencil: (BrGlamorousColumnedListSelectableRowElementStencilBuilder new);
		padding: (BlInsets top: 5);
		matchParent;
		background: (ZealTheme backgroundColor lighter).
	aTable column
		title: 'Icon' translated;
		width: 40;
		stencil: [ :each | 
			each isDirectory
				ifTrue: [ BrGlamorousVectorIcons folder ]
				ifFalse: [ BrGlamorousVectorIcons file ] ].
	aTable column
		title: 'Name' translated;
		matchParent;
		cellStencil: [ :each | BrLabel new aptitude: (BrGlamorousLabelAptitude new foreground: labelColor) ];
		dataBinder: [ :aLabel :eachItem | 
			aLabel text: ((folder isChildOf: eachItem)
				ifTrue: [ '..' ]
				ifFalse: [ eachItem basename asString ]) asRopedText ].
	aTable column 
		title: 'Size' translated;
		width: 100;
		cellStencil: [ :each | BrLabel new aptitude: (BrGlamorousLabelAptitude new foreground: labelColor) ];
		dataBinder: [ :aLabel :eachItem |
			aLabel text: (eachItem isDirectory
				ifTrue: [ '-' ]
				ifFalse: [ [ eachItem humanReadableSize ] 
					on: FileException 
					do: [ :anException | anException return: '? B' ] ]) asRopedText ].
	aTable column 
		title: 'Modified' translated;
		width: 100;
		cellStencil: [ :each | BrLabel new aptitude: (BrGlamorousLabelAptitude new foreground: labelColor) ];
		dataBinder: [ :aLabel :eachItem |
			aLabel text: ([ String
				streamContents: [ :s | 
					eachItem creationTime printYMDOn: s.
					s nextPut: Character space.
					eachItem creationTime printHMSOn: s ] ] 
				on: FileException 
				do: [ :anException | anException return: '?' ]) asRopedText ].
	aTable
		when: BrSelectionDoubleClicked
		do: [ :anEvent | 
			anEvent selection
				ifNotEmpty: [ :theIndices | 
					| aWidgetElement selectedObject |
					aWidgetElement := anEvent currentTarget.
					selectedObject := aWidgetElement viewModel itemAt: theIndices first.
					self folder: selectedObject ] ].
	aTable
		when: BrSelectionChanged 
		do: [ :anEvent | okButton enable ].
	aTable addAptitude: BrColumnedListHeaderAptitude.
	^ aTable
]
