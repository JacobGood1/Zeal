Extension { #name : 'GtPharoBehaviorDefinitionCoderElement' }

{ #category : '*Zeal' }
GtPharoBehaviorDefinitionCoderElement >> editableLabelLook [
	^ BrGlamorousEditableLabelAptitude new
		glamorousCodeFont;
		defaultForeground: ZealDarkMode textColor;
		fontSize: 10
]

{ #category : '*Zeal' }
GtPharoBehaviorDefinitionCoderElement >> readonlyLabelLook [
	^ BrGlamorousEditorAptitude new
		glamorousCodeFont;
		fontSize: 10;
		foreground: ZealDarkMode textColor;
		add:
			(BrStyleCommonAptitude new
				default: [ :aStyle | 
					aStyle
						geometry: (BlRoundedRectangleGeometry cornerRadius: 4);
						border: BlBorder empty ];
				hovered: [ :aStyle | 
					aStyle
						border: (BlBorder paint: self theme button hoveredBorderColor width: 1) ]);
		yourself
]
