Extension { #name : 'BlThemeableColor' }

{ #category : '*Zeal' }
BlThemeableColor >> adjustBrightness: brightness [
	^ self resolvedColor adjustBrightness: brightness
]

{ #category : '*Zeal' }
BlThemeableColor >> adjustSaturation: saturation brightness: brightness [
	^ self resolvedColor adjustSaturation: saturation brightness: brightness
]

{ #category : '*Zeal' }
BlThemeableColor >> alpha: aFloat [
	"Resolve the themeable color and return a new Color with the given alpha"
	^ (self blocResolveColorForTheme: (BlTheme default)) alpha: aFloat
]

{ #category : '*Zeal' }
BlThemeableColor >> asHexString [
	^ self resolvedColor asHexString
]

{ #category : '*Zeal' }
BlThemeableColor >> darker [
	^ self resolvedColor darker
]

{ #category : '*Zeal' }
BlThemeableColor >> lighter [
	^ self resolvedColor lighter
]

{ #category : '*Zeal' }
BlThemeableColor >> mixed: proportion with: aColor [
	^ self resolvedColor mixed: proportion with: aColor
]

{ #category : '*Zeal' }
BlThemeableColor >> muchDarker [
	^ self resolvedColor muchDarker
]

{ #category : '*Zeal' }
BlThemeableColor >> muchLighter [
	^ self resolvedColor muchLighter
]

{ #category : '*Zeal' }
BlThemeableColor >> negated [
	^ self resolvedColor negated
]

{ #category : '*Zeal' }
BlThemeableColor >> resolvedColor [
	"Resolve this themeable color against the current theme"
	^ self blocResolveColorForTheme: BlTheme default
]
