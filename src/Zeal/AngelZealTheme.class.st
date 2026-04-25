Class {
	#name : 'AngelZealTheme',
	#superclass : 'VerseZealTheme',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealTheme class >> dialectTokenColorFor: aWord [
	"AngelZeal: UE attribute macros and built-in UE types get distinct colors.
	 - UCLASS/USTRUCT/UFUNCTION/UPROPERTY/UENUM/UINTERFACE → specialFormColor
	 - AActor/UObject/APawn/FString/FName/FVector/FRotator/FTransform/TArray/TMap → classRefColor"
	(#('UCLASS' 'USTRUCT' 'UFUNCTION' 'UPROPERTY' 'UENUM' 'UINTERFACE' 'UMETA') includes: aWord)
		ifTrue: [ ^ self specialFormColor ].
	(#('AActor' 'APawn' 'ACharacter' 'AGameMode' 'AGameModeBase' 'APlayerController'
	   'UObject' 'UActorComponent' 'UWorld' 'UClass'
	   'FString' 'FName' 'FText' 'FVector' 'FVector2D' 'FRotator' 'FTransform'
	   'TArray' 'TMap' 'TSet' 'TSubclassOf' 'TSoftObjectPtr' 'TWeakObjectPtr')
		includes: aWord)
		ifTrue: [ ^ self classRefColor ].
	^ nil
]

{ #category : 'api' }
AngelZealTheme class >> specialForms [
	"AngelZeal's syntactic keywords — these get the specialFormColor."
	^ #('def' 'var' 'set' 'defn' 'defclass' 'defstruct' 'if' 'when' 'for' 'while' 'let' 'do' 'return' 'as')
]

{ #category : 'api' }
AngelZealTheme class >> typeInferencer [
	^ AngelZealTypeInferencer default
]
