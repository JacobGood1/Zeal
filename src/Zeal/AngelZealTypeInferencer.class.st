Class {
	#name : 'AngelZealTypeInferencer',
	#superclass : 'ZealTypeInferencer',
	#category : 'Zeal',
	#package : 'Zeal'
}

{ #category : 'api' }
AngelZealTypeInferencer >> knownTypes [
	"AngelScript / Unreal Engine types — primitives, F-structs, A-actors, U-objects,
	 T-templated containers."
	^ self primitiveTypes ,
		#('FString' 'FName' 'FText' 'FVector' 'FVector2D' 'FVector4'
		  'FRotator' 'FTransform' 'FQuat' 'FColor' 'FLinearColor'
		  'FBox' 'FBox2D' 'FIntPoint' 'FIntVector' 'FGuid' 'FDateTime' 'FTimespan'
		  'AActor' 'APawn' 'ACharacter' 'APlayerController' 'APlayerState'
		  'AGameMode' 'AGameModeBase' 'AGameState' 'AGameStateBase' 'AHUD'
		  'UObject' 'UClass' 'UWorld' 'UActorComponent' 'USceneComponent'
		  'UStaticMeshComponent' 'USkeletalMeshComponent'
		  'TArray' 'TMap' 'TSet' 'TSubclassOf' 'TSoftObjectPtr' 'TWeakObjectPtr')
]
