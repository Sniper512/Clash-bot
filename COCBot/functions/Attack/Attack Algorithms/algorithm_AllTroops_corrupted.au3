; #FUNCTION# ====================================================================================================================
; Name ..........: algorith_AllTroops
; Description ...: This file contens all functions to attack algorithm will all Troops , using Barbarians, Archers, Goblins, Giants and Wallbreakers as they are available
; Syntax ........: algorithm_AllTroops()
; Parameters ....: None
; Return values .: None
; Author ........:
; Modified ......: Didipe (05-2015), ProMac(2016), MonkeyHunter(03-2017), AI-Enhanced (2025)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
;                  Enhanced with AI-generated attack strategies using Firebase Genkit
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

#include "..\HttpRequest.au3"

Func algorithm_AllTroops() ;Attack Algorithm for all existing troops
	; Initialize color constants with safe fallbacks
	Local $iColorSuccess = IsDeclared("COLOR_SUCCESS") ? $COLOR_SUCCESS : 0x00FF00
	Local $iColorInfo = IsDeclared("COLOR_INFO") ? $COLOR_INFO : 0x0000FF
	Local $iColorError = IsDeclared("COLOR_ERROR") ? $COLOR_ERROR : 0xFF0000
	Local $iColorDebug = IsDeclared("COLOR_DEBUG") ? $COLOR_DEBUG : 0xFF00FF
	
	; TEST: Check if this function is being called
	SetLog("🚀 algorithm_AllTroops FUNCTION CALLED!", $iColorSuccess)
	
	; 🧪 IMMEDIATE TEST: Test AI strategy generation
	SetLog("🧪 IMMEDIATE TEST: Calling GenerateAIStrategy...", $iColorInfo)
	Local $sTestStrategy = GenerateAIStrategy(0, "LavaLoon", 4, "Barbarian,Archer,Giant", "Test target")
	SetLog("🧪 TEST RESULT: " & $sTestStrategy, $iColorInfo)
	
	; 🧪 TEST PARSE: Test parsing the response
	If $sTestStrategy <> "" Then
		SetLog("🧪 TESTING ParseAIStrategyResponse...", $iColorInfo)
		Local $aTestParsed = ParseAIStrategyResponse($sTestStrategy)
		If IsArray($aTestParsed) Then
			SetLog("🧪 TEST PARSE SUCCESS: Array with " & UBound($aTestParsed,1) & " rows and " & UBound($aTestParsed,2) & " cols", $iColorSuccess)
		Else
			SetLog("🧪 TEST PARSE FAILED: Not an array", $iColorError)
		EndIf
	Else
		SetLog("🧪 TEST SKIPPED: No response from server", $iColorInfo)
	EndIf
	
	; ✅ TEST COMPLETED - Remove early exit to allow normal bot operation
	SetLog("✅ AI INTEGRATION TEST COMPLETED - Continuing with normal bot operation", $iColorSuccess)
	
	; Continue with normal function after test
	Local $bDebugMode = IsDeclared("g_bDebugSetLog") ? $g_bDebugSetLog : False
	SetSlotSpecialTroops()

	If IsDeclared("DELAYALGORITHM_ALLTROOPS1") And _Sleep($DELAYALGORITHM_ALLTROOPS1) Then Return

	; Check if match mode variable exists
	Local $iMatchMode = IsDeclared("g_iMatchMode") ? $g_iMatchMode : 0
	SmartAttackStrategy($iMatchMode) ; detect redarea first to drop any troops

	Local $nbSides = 0
	; Check if attack drop sides array exists
	Local $iDropSideMode = 3 ; Default to all sides
	If IsDeclared("g_aiAttackStdDropSides") And IsArray($g_aiAttackStdDropSides) Then
		If UBound($g_aiAttackStdDropSides) > $iMatchMode Then
			$iDropSideMode = $g_aiAttackStdDropSides[$iMatchMode]
		EndIf
	EndIf
	
	Switch $iDropSideMode
		Case 0 ;Single sides ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			SetLog("Attacking on a single side", $iColorInfo)
			$nbSides = 1
		Case 1 ;Two sides ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			SetLog("Attacking on two sides", $iColorInfo)
			$nbSides = 2
		Case 2 ;Three sides ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			SetLog("Attacking on three sides", $iColorInfo)
			$nbSides = 3
		Case 3 ;All sides ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			SetLog("Attacking on all sides", $iColorInfo)
			$nbSides = 4
		Case 4 ;DE Side - Live Base only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			SetLog("Attacking on Dark Elixir Side.", $iColorInfo)
			$nbSides = 1
			If IsDeclared("g_abAttackStdSmartAttack") And IsArray($g_abAttackStdSmartAttack) And UBound($g_abAttackStdSmartAttack) > $iMatchMode Then
				If Not ($g_abAttackStdSmartAttack[$iMatchMode]) Then 
					If IsDeclared("eSideBuildingDES") Then
						GetBuildingEdge($eSideBuildingDES) ; Get DE Storage side when Redline is not used.
					EndIf
				EndIf
			EndIf
		Case 5 ;TH Side - Live Base only ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
			SetLog("Attacking on Town Hall Side.", $iColorInfo)
			$nbSides = 1
			If IsDeclared("g_abAttackStdSmartAttack") And IsArray($g_abAttackStdSmartAttack) And UBound($g_abAttackStdSmartAttack) > $iMatchMode Then
				If Not ($g_abAttackStdSmartAttack[$iMatchMode]) Then 
					If IsDeclared("eSideBuildingTH") Then
						GetBuildingEdge($eSideBuildingTH) ; Get Townhall side when Redline is not used.
					EndIf
				EndIf
			EndIf
	EndSwitch
	If ($nbSides = 0) Then Return
	If IsDeclared("DELAYALGORITHM_ALLTROOPS2") And _Sleep($DELAYALGORITHM_ALLTROOPS2) Then Return

	; Check if global attack sides variable exists
	If IsDeclared("g_iSidesAttack") Then
		$g_iSidesAttack = $nbSides
	EndIf

	; Reset the deploy Giants points , spread along red line
	Local $g_iSlotsGiants = 0
	Local $GiantComp = 0
	; Giants quantities - check if variables exist
	If IsDeclared("g_avAttackTroops") And IsArray($g_avAttackTroops) And IsDeclared("eGiant") Then
		; Check if it's a 2D array
		Local $iArrayDims = UBound($g_avAttackTroops, 0)
		If $iArrayDims >= 2 Then
			Local $iCols = UBound($g_avAttackTroops, 2)
			If $iCols >= 2 Then
				For $i = 0 To UBound($g_avAttackTroops) - 1
					If $g_avAttackTroops[$i][0] = $eGiant Then
						$GiantComp = $g_avAttackTroops[$i][1]
					EndIf
				Next
			EndIf
		EndIf
	EndIf

	; Lets select the deploy points according by Giants qunatities & sides
	; Deploy points : 0 - spreads along the red line , 1 - one deploy point .... X - X deploy points
	Switch $GiantComp
		Case 0 To 10
			$g_iSlotsGiants = 2
		Case Else
			Switch $nbSides
				Case 1 To 2
					$g_iSlotsGiants = 4
				Case Else
					$g_iSlotsGiants = 0
			EndSwitch
	EndSwitch

	; $ListInfoDeploy = [Troop, No. of Sides, $WaveNb, $MaxWaveNb, $slotsPerEdge]
	; Generate AI-powered attack strategy
	SetLog("Generating AI-powered attack strategy...", $iColorInfo)
	
	; Collect available troop information
	Local $sAvailableTroops = GetAvailableTroopsString()
	Local $sTargetInfo = GetTargetInfoString()
	
	; Generate AI strategy with safe variable checking
	Local $sDropOrder = ""
	If IsDeclared("g_aiAttackStdDropOrder") And IsArray($g_aiAttackStdDropOrder) And UBound($g_aiAttackStdDropOrder) > $iMatchMode Then
		$sDropOrder = $g_aiAttackStdDropOrder[$iMatchMode]
	EndIf
	
	SetLog("ABOUT TO CALL AI STRATEGY - MatchMode: " & $iMatchMode & " DropOrder: " & $sDropOrder & " Sides: " & $nbSides, $iColorDebug)
	Local $sAIStrategy = GenerateAIStrategy($iMatchMode, $sDropOrder, $nbSides, $sAvailableTroops, $sTargetInfo)
	SetLog("AI STRATEGY RESPONSE: " & $sAIStrategy, $iColorDebug)
	SetLog("Length of AI response: " & StringLen($sAIStrategy), $iColorDebug)
	
	; Declare strategy array
	Local $listInfoDeploy[10][5]
	
	; Execute the AI-generated strategy
	If $sAIStrategy <> "" Then
		SetLog("Executing AI-generated strategy", $iColorSuccess)
		SetLog("Calling ParseAIStrategyResponse...", $iColorDebug)
		Local $aAIStrategy = ParseAIStrategyResponse($sAIStrategy)
		SetLog("ParseAIStrategyResponse returned, checking validity...", $iColorDebug)
		
		; Check if we got a valid strategy array
		Local $bIsValid = False
		If IsArray($aAIStrategy) Then
			SetLog("Result is an array", $iColorDebug)
			Local $iDims = UBound($aAIStrategy, 0)
			Local $iRows = UBound($aAIStrategy, 1)
			Local $iCols = UBound($aAIStrategy, 2)
			SetLog("Array dimensions: " & $iDims & "D, Rows: " & $iRows & ", Cols: " & $iCols, $iColorDebug)
			
			If $iDims = 2 And $iRows > 0 And $iCols = 5 Then
				$bIsValid = True
				SetLog("Array validation passed!", $iColorSuccess)
			Else
				SetLog("Array validation failed - wrong dimensions", $iColorError)
			EndIf
		Else
			SetLog("Result is NOT an array", $iColorError)
		EndIf
		
		If $bIsValid Then
			; Copy the AI strategy to our array
			ReDim $listInfoDeploy[UBound($aAIStrategy)][5]
			For $i = 0 To UBound($aAIStrategy) - 1
				For $j = 0 To 4
					$listInfoDeploy[$i][$j] = $aAIStrategy[$i][$j]
				Next
			Next
			SetLog("AI strategy loaded successfully with " & UBound($aAIStrategy) & " entries", $iColorSuccess)
		Else
			SetLog("AI strategy invalid, using fallback", $iColorError)
			Local $iSafeSlots = IsDeclared("g_iSlotsGiants") ? $g_iSlotsGiants : 2
			$listInfoDeploy = _CreateFallbackStrategy($nbSides, $iSafeSlots)
		EndIf
	Else
		SetLog("AI strategy generation failed, using fallback", $iColorError)
		; Fallback to default strategy with safety check
		Local $iSafeSlots = IsDeclared("g_iSlotsGiants") ? $g_iSlotsGiants : 2
		$listInfoDeploy = _CreateFallbackStrategy($nbSides, $iSafeSlots)
	EndIf

	; Check if global variables exist before using them
	If IsDeclared("g_bIsCCDropped") Then $g_bIsCCDropped = False
	If IsDeclared("g_aiDeployCCPosition") And IsArray($g_aiDeployCCPosition) And UBound($g_aiDeployCCPosition) >= 2 Then
		$g_aiDeployCCPosition[0] = -1
		$g_aiDeployCCPosition[1] = -1
	EndIf
	If IsDeclared("g_bIsHeroesDropped") Then $g_bIsHeroesDropped = False
	If IsDeclared("g_aiDeployHeroesPosition") And IsArray($g_aiDeployHeroesPosition) And UBound($g_aiDeployHeroesPosition) >= 2 Then
		$g_aiDeployHeroesPosition[0] = -1
		$g_aiDeployHeroesPosition[1] = -1
	EndIf

	; Launch troops with safe variable checking
	Local $iClanCastleSlot = IsDeclared("g_iClanCastleSlot") ? $g_iClanCastleSlot : -1
	Local $iKingSlot = IsDeclared("g_iKingSlot") ? $g_iKingSlot : -1
	Local $iQueenSlot = IsDeclared("g_iQueenSlot") ? $g_iQueenSlot : -1
	Local $iPrinceSlot = IsDeclared("g_iPrinceSlot") ? $g_iPrinceSlot : -1
	Local $iWardenSlot = IsDeclared("g_iWardenSlot") ? $g_iWardenSlot : -1
	Local $iChampionSlot = IsDeclared("g_iChampionSlot") ? $g_iChampionSlot : -1
	
	; Final validation of the strategy array before launching troops
	$listInfoDeploy = _ValidateStrategyArray($listInfoDeploy, $nbSides)
	
	; ABSOLUTE FINAL SAFETY CHECK - if anything is still wrong, force a simple fallback
	If Not IsArray($listInfoDeploy) Or UBound($listInfoDeploy, 0) <> 2 Or UBound($listInfoDeploy, 1) = 0 Or UBound($listInfoDeploy, 2) <> 5 Then
		SetLog("EMERGENCY: Final safety check failed. Creating emergency fallback strategy.", $iColorError)
		; Create the simplest possible valid strategy
		Local $emergencyStrategy[3][5]
		$emergencyStrategy[0][0] = IsDeclared("eBarb") ? $eBarb : 0
		$emergencyStrategy[0][1] = $nbSides
		$emergencyStrategy[0][2] = 1
		$emergencyStrategy[0][3] = 1
		$emergencyStrategy[0][4] = 0
		
		$emergencyStrategy[1][0] = IsDeclared("eArch") ? $eArch : 1
		$emergencyStrategy[1][1] = $nbSides
		$emergencyStrategy[1][2] = 1
		$emergencyStrategy[1][3] = 1
		$emergencyStrategy[1][4] = 0
		
		$emergencyStrategy[2][0] = "CC"
		$emergencyStrategy[2][1] = 1
		$emergencyStrategy[2][2] = 1
		$emergencyStrategy[2][3] = 1
		$emergencyStrategy[2][4] = 1
		
		$listInfoDeploy = $emergencyStrategy
	EndIf
	
	; 🔍 DEBUG: Final validation before LaunchTroop2
	SetLog("🔍 FINAL DEBUG: About to call LaunchTroop2 with array:", $iColorDebug)
	SetLog("🔍 Array dimensions: UBound(listInfoDeploy,0)=" & UBound($listInfoDeploy,0) & ", UBound(listInfoDeploy,1)=" & UBound($listInfoDeploy,1) & ", UBound(listInfoDeploy,2)=" & UBound($listInfoDeploy,2), $iColorDebug)
	
	; Check if array has valid data
	If UBound($listInfoDeploy,1) > 0 Then
		SetLog("🔍 First entry: [0][0]=" & $listInfoDeploy[0][0] & ", [0][1]=" & $listInfoDeploy[0][1] & ", [0][2]=" & $listInfoDeploy[0][2] & ", [0][3]=" & $listInfoDeploy[0][3] & ", [0][4]=" & $listInfoDeploy[0][4], $iColorDebug)
	Else
		SetLog("🔍 ERROR: listInfoDeploy has 0 rows!", $iColorError)
	EndIf
	
	; Additional safety check for 2D array
	If UBound($listInfoDeploy, 0) <> 2 Then
		SetLog("🔍 CRITICAL ERROR: listInfoDeploy is not a 2D array! Dimensions=" & UBound($listInfoDeploy, 0), $iColorError)
		Return ; Exit function to prevent crash
	EndIf
	
	LaunchTroop2($listInfoDeploy, $iClanCastleSlot, $iKingSlot, $iQueenSlot, $iPrinceSlot, $iWardenSlot, $iChampionSlot)

	CheckHeroesHealth()

	; Drop spells after troops are deployed
	If IsDeclared("DELAYALGORITHM_ALLTROOPS4") And _Sleep($DELAYALGORITHM_ALLTROOPS4) Then Return
	SetLog("Starting spell deployment phase", $iColorInfo)
	dropSpells($iMatchMode)

	If IsDeclared("DELAYALGORITHM_ALLTROOPS4") And _Sleep($DELAYALGORITHM_ALLTROOPS4) Then Return
	SetLog("Dropping left over troops", $iColorInfo)
	For $x = 0 To 1
		If PrepareAttack($iMatchMode, True) = 0 Then
			If $bDebugMode Then SetDebugLog("No Wast time... exit, no troops usable left", $iColorDebug)
			ExitLoop ;Check remaining quantities
		EndIf
		; Check if troop constants exist before using them
		Local $iStartTroop = IsDeclared("eBarb") ? $eBarb : 0
		Local $iEndTroop = IsDeclared("eFurn") ? $eFurn : 20
		For $i = $iStartTroop To $iEndTroop ; launch all remaining troops
			If LaunchTroop($i, $nbSides, 1, 1, 1) Then
				CheckHeroesHealth()
				If IsDeclared("DELAYALGORITHM_ALLTROOPS5") And _Sleep($DELAYALGORITHM_ALLTROOPS5) Then Return
			EndIf
		Next
	Next

	CheckHeroesHealth()

	SetLog("Finished Attacking, waiting for the battle to end")
EndFunc   ;==>algorithm_AllTroops

Func SetSlotSpecialTroops()
	; Initialize with safe defaults
	If IsDeclared("g_iKingSlot") Then $g_iKingSlot = -1
	If IsDeclared("g_iQueenSlot") Then $g_iQueenSlot = -1
	If IsDeclared("g_iPrinceSlot") Then $g_iPrinceSlot = -1
	If IsDeclared("g_iWardenSlot") Then $g_iWardenSlot = -1
	If IsDeclared("g_iChampionSlot") Then $g_iChampionSlot = -1
	If IsDeclared("g_iClanCastleSlot") Then $g_iClanCastleSlot = -1

	; Check if attack troops array exists and is 2D
	If Not IsDeclared("g_avAttackTroops") Or Not IsArray($g_avAttackTroops) Then Return
	
	; Check if it's a 2D array by trying to get second dimension
	Local $iArrayDims = UBound($g_avAttackTroops, 0)  ; Get number of dimensions
	If $iArrayDims < 2 Then Return  ; Must be at least 2D
	
	Local $iCols = UBound($g_avAttackTroops, 2)  ; Get number of columns
	If $iCols < 2 Then Return  ; Must have at least 2 columns

	For $i = 0 To UBound($g_avAttackTroops) - 1
		; Check each troop constant before using it
		Local $bIsClanCastle = False
		If IsDeclared("eCastle") And $g_avAttackTroops[$i][0] = $eCastle Then $bIsClanCastle = True
		If IsDeclared("eWallW") And $g_avAttackTroops[$i][0] = $eWallW Then $bIsClanCastle = True
		If IsDeclared("eBattleB") And $g_avAttackTroops[$i][0] = $eBattleB Then $bIsClanCastle = True
		If IsDeclared("eStoneS") And $g_avAttackTroops[$i][0] = $eStoneS Then $bIsClanCastle = True
		If IsDeclared("eSiegeB") And $g_avAttackTroops[$i][0] = $eSiegeB Then $bIsClanCastle = True
		If IsDeclared("eLogL") And $g_avAttackTroops[$i][0] = $eLogL Then $bIsClanCastle = True
		If IsDeclared("eFlameF") And $g_avAttackTroops[$i][0] = $eFlameF Then $bIsClanCastle = True
		If IsDeclared("eBattleD") And $g_avAttackTroops[$i][0] = $eBattleD Then $bIsClanCastle = True
		If IsDeclared("eTroopL") And $g_avAttackTroops[$i][0] = $eTroopL Then $bIsClanCastle = True
		
		If $bIsClanCastle Then
			If IsDeclared("g_iClanCastleSlot") Then $g_iClanCastleSlot = $i
		ElseIf IsDeclared("eKing") And $g_avAttackTroops[$i][0] = $eKing Then
			If IsDeclared("g_iKingSlot") Then $g_iKingSlot = $i
		ElseIf IsDeclared("eQueen") And $g_avAttackTroops[$i][0] = $eQueen Then
			If IsDeclared("g_iQueenSlot") Then $g_iQueenSlot = $i
		ElseIf IsDeclared("ePrince") And $g_avAttackTroops[$i][0] = $ePrince Then
			If IsDeclared("g_iPrinceSlot") Then $g_iPrinceSlot = $i
		ElseIf IsDeclared("eWarden") And $g_avAttackTroops[$i][0] = $eWarden Then
			If IsDeclared("g_iWardenSlot") Then $g_iWardenSlot = $i
		ElseIf IsDeclared("eChampion") And $g_avAttackTroops[$i][0] = $eChampion Then
			If IsDeclared("g_iChampionSlot") Then $g_iChampionSlot = $i
		EndIf
	Next

	; Debug logging with safe variable checking
	Local $bDebugMode = IsDeclared("g_bDebugSetLog") ? $g_bDebugSetLog : False
	If $bDebugMode Then
		Local $iColorDebug = IsDeclared("COLOR_DEBUG") ? $COLOR_DEBUG : 0xFF0000
		Local $iKing = IsDeclared("g_iKingSlot") ? $g_iKingSlot : -1
		Local $iQueen = IsDeclared("g_iQueenSlot") ? $g_iQueenSlot : -1
		Local $iPrince = IsDeclared("g_iPrinceSlot") ? $g_iPrinceSlot : -1
		Local $iWarden = IsDeclared("g_iWardenSlot") ? $g_iWardenSlot : -1
		Local $iChampion = IsDeclared("g_iChampionSlot") ? $g_iChampionSlot : -1
		Local $iClanCastle = IsDeclared("g_iClanCastleSlot") ? $g_iClanCastleSlot : -1
		
		SetDebugLog("SetSlotSpecialTroops() King Slot: " & $iKing, $iColorDebug)
		SetDebugLog("SetSlotSpecialTroops() Queen Slot: " & $iQueen, $iColorDebug)
		SetDebugLog("SetSlotSpecialTroops() Prince Slot: " & $iPrince, $iColorDebug)
		SetDebugLog("SetSlotSpecialTroops() Warden Slot: " & $iWarden, $iColorDebug)
		SetDebugLog("SetSlotSpecialTroops() Champion Slot: " & $iChampion, $iColorDebug)
		SetDebugLog("SetSlotSpecialTroops() Clan Castle Slot: " & $iClanCastle, $iColorDebug)
	EndIf

EndFunc   ;==>SetSlotSpecialTroops

Func CloseBattle()
	If IsAttackPage() Then
		For $i = 1 To 30
			;_CaptureRegion()
			; Check if array exists before accessing
			If IsDeclared("aWonOneStar") And IsArray($aWonOneStar) And UBound($aWonOneStar) >= 4 Then
				If _ColorCheck(_GetPixelColor($aWonOneStar[0], $aWonOneStar[1], True), Hex($aWonOneStar[2], 6), $aWonOneStar[3]) = True Then ExitLoop ;exit if not 'no star'
			EndIf
			If IsDeclared("DELAYALGORITHM_ALLTROOPS2") And _Sleep($DELAYALGORITHM_ALLTROOPS2) Then Return
		Next
	EndIf

	; Check if surrender button array exists
	If IsAttackPage() And IsDeclared("aSurrenderButton") And IsArray($aSurrenderButton) Then
		ClickP($aSurrenderButton, 1, 0, "#0030") ;Click Surrender
	EndIf
	If IsDeclared("DELAYALGORITHM_ALLTROOPS3") And _Sleep($DELAYALGORITHM_ALLTROOPS3) Then Return
	If IsEndBattlePage() Then
		; Check if confirm surrender array exists
		If IsDeclared("aConfirmSurrender") And IsArray($aConfirmSurrender) Then
			ClickP($aConfirmSurrender, 1, 120, "#0031") ;Click Confirm
		EndIf
		If IsDeclared("DELAYALGORITHM_ALLTROOPS1") And _Sleep($DELAYALGORITHM_ALLTROOPS1) Then Return
	EndIf

EndFunc   ;==>CloseBattle


Func SmartAttackStrategy($imode)
	; Initialize color constants with safe fallbacks
	Local $iColorInfo = IsDeclared("COLOR_INFO") ? $COLOR_INFO : 0x0000FF
	
	; Check if smart attack is enabled
	If IsDeclared("g_abAttackStdSmartAttack") And IsArray($g_abAttackStdSmartAttack) And UBound($g_abAttackStdSmartAttack) > $imode Then
		If ($g_abAttackStdSmartAttack[$imode]) Then
			SetLog("Calculating Smart Attack Strategy", $iColorInfo)
			Local $hTimer = __TimerInit()
			_CaptureRegion2()
			_GetRedArea()

			SetLog("Calculated  (in " & Round(__TimerDiff($hTimer) / 1000, 2) & " seconds) :")

			; Check if collector targeting is enabled
			If IsDeclared("g_abAttackStdSmartNearCollectors") And IsArray($g_abAttackStdSmartNearCollectors) And UBound($g_abAttackStdSmartNearCollectors) > $imode Then
				Local $aNearCollectors = $g_abAttackStdSmartNearCollectors[$imode]
				If IsArray($aNearCollectors) And UBound($aNearCollectors) >= 3 Then
					If ($aNearCollectors[0] Or $aNearCollectors[1] Or $aNearCollectors[2]) Then
						SetLog("Locating Mines, Collectors & Drills", $iColorInfo)
						$hTimer = __TimerInit()
						
						; Initialize arrays safely
						If IsDeclared("g_aiPixelMine") Then Global $g_aiPixelMine[0]
						If IsDeclared("g_aiPixelElixir") Then Global $g_aiPixelElixir[0]
						If IsDeclared("g_aiPixelDarkElixir") Then Global $g_aiPixelDarkElixir[0]
						If IsDeclared("g_aiPixelNearCollector") Then Global $g_aiPixelNearCollector[0]
						
						; If drop troop near gold mine
						If $aNearCollectors[0] And IsDeclared("g_aiPixelMine") Then
							$g_aiPixelMine = GetLocationMine()
							If (IsArray($g_aiPixelMine)) And IsDeclared("g_aiPixelNearCollector") Then
								If IsDeclared("ARRAYFILL_FORCE_STRING") Then
									_ArrayAdd($g_aiPixelNearCollector, $g_aiPixelMine, 0, "|", @CRLF, $ARRAYFILL_FORCE_STRING)
								Else
									_ArrayAdd($g_aiPixelNearCollector, $g_aiPixelMine, 0, "|", @CRLF)
								EndIf
							EndIf
						EndIf
						
						; If drop troop near elixir collector
						If $aNearCollectors[1] And IsDeclared("g_aiPixelElixir") Then
							$g_aiPixelElixir = GetLocationElixir()
							If (IsArray($g_aiPixelElixir)) And IsDeclared("g_aiPixelNearCollector") Then
								If IsDeclared("ARRAYFILL_FORCE_STRING") Then
									_ArrayAdd($g_aiPixelNearCollector, $g_aiPixelElixir, 0, "|", @CRLF, $ARRAYFILL_FORCE_STRING)
								Else
									_ArrayAdd($g_aiPixelNearCollector, $g_aiPixelElixir, 0, "|", @CRLF)
								EndIf
							EndIf
						EndIf
						
						; If drop troop near dark elixir drill
						If $aNearCollectors[2] And IsDeclared("g_aiPixelDarkElixir") Then
							$g_aiPixelDarkElixir = GetLocationDarkElixir()
							If (IsArray($g_aiPixelDarkElixir)) And IsDeclared("g_aiPixelNearCollector") Then
								If IsDeclared("ARRAYFILL_FORCE_STRING") Then
									_ArrayAdd($g_aiPixelNearCollector, $g_aiPixelDarkElixir, 0, "|", @CRLF, $ARRAYFILL_FORCE_STRING)
								Else
									_ArrayAdd($g_aiPixelNearCollector, $g_aiPixelDarkElixir, 0, "|", @CRLF)
								EndIf
							EndIf
						EndIf
						
						SetLog("Located  (in " & Round(__TimerDiff($hTimer) / 1000, 2) & " seconds) :")
						Local $iMineCount = IsDeclared("g_aiPixelMine") And IsArray($g_aiPixelMine) ? UBound($g_aiPixelMine) : 0
						Local $iElixirCount = IsDeclared("g_aiPixelElixir") And IsArray($g_aiPixelElixir) ? UBound($g_aiPixelElixir) : 0
						Local $iDarkElixirCount = IsDeclared("g_aiPixelDarkElixir") And IsArray($g_aiPixelDarkElixir) ? UBound($g_aiPixelDarkElixir) : 0
						
						SetLog("[" & $iMineCount & "] Gold Mines")
						SetLog("[" & $iElixirCount & "] Elixir Collectors")
						SetLog("[" & $iDarkElixirCount & "] Dark Elixir Drill/s")
						
						; Update stats safely
						If IsDeclared("g_aiNbrOfDetectedMines") And IsArray($g_aiNbrOfDetectedMines) And UBound($g_aiNbrOfDetectedMines) > $imode Then
							$g_aiNbrOfDetectedMines[$imode] += $iMineCount
						EndIf
						If IsDeclared("g_aiNbrOfDetectedCollectors") And IsArray($g_aiNbrOfDetectedCollectors) And UBound($g_aiNbrOfDetectedCollectors) > $imode Then
							$g_aiNbrOfDetectedCollectors[$imode] += $iElixirCount
						EndIf
						If IsDeclared("g_aiNbrOfDetectedDrills") And IsArray($g_aiNbrOfDetectedDrills) And UBound($g_aiNbrOfDetectedDrills) > $imode Then
							$g_aiNbrOfDetectedDrills[$imode] += $iDarkElixirCount
						EndIf
						
						UpdateStats()
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc   ;==>SmartAttackStrategy

; Helper function to get available troops information for AI
Func GetAvailableTroopsString()
	Local $troopInfo = ""
	
	; Check if attack troops array exists
	If Not IsDeclared("g_avAttackTroops") Or Not IsArray($g_avAttackTroops) Then
		Return "No troops available"
	EndIf
	
	; Check if it's a 2D array by trying to get second dimension
	Local $iArrayDims = UBound($g_avAttackTroops, 0)  ; Get number of dimensions
	If $iArrayDims < 2 Then
		Return "No troops available"
	EndIf
	
	Local $iCols = UBound($g_avAttackTroops, 2)  ; Get number of columns
	If $iCols < 2 Then
		Return "No troops available"
	EndIf
	
	; Check each troop type and add available quantities
	For $i = 0 To UBound($g_avAttackTroops) - 1
		; Check if the troop array has proper dimensions
		If $g_avAttackTroops[$i][1] > 0 Then
			Local $troopName = ""
			Local $troopType = $g_avAttackTroops[$i][0]
			
			; Check each troop constant safely
			If IsDeclared("eBarb") And $troopType = $eBarb Then
				$troopName = "Barbarian"
			ElseIf IsDeclared("eArch") And $troopType = $eArch Then
				$troopName = "Archer"
			ElseIf IsDeclared("eGiant") And $troopType = $eGiant Then
				$troopName = "Giant"
			ElseIf IsDeclared("eGobl") And $troopType = $eGobl Then
				$troopName = "Goblin"
			ElseIf IsDeclared("eWiza") And $troopType = $eWiza Then
				$troopName = "Wizard"
			ElseIf IsDeclared("eBall") And $troopType = $eBall Then
				$troopName = "Balloon"
			ElseIf IsDeclared("eDrag") And $troopType = $eDrag Then
				$troopName = "Dragon"
			ElseIf IsDeclared("ePekk") And $troopType = $ePekk Then
				$troopName = "PEKKA"
			ElseIf IsDeclared("eBabyD") And $troopType = $eBabyD Then
				$troopName = "Baby Dragon"
			ElseIf IsDeclared("eMine") And $troopType = $eMine Then
				$troopName = "Miner"
			ElseIf IsDeclared("eEDrag") And $troopType = $eEDrag Then
				$troopName = "Electro Dragon"
			ElseIf IsDeclared("eYeti") And $troopType = $eYeti Then
				$troopName = "Yeti"
			ElseIf IsDeclared("eDragR") And $troopType = $eDragR Then
				$troopName = "Dragon Rider"
			ElseIf IsDeclared("eElem") And $troopType = $eElem Then
				$troopName = "Electro Titan"
			ElseIf IsDeclared("eHeal") And $troopType = $eHeal Then
				$troopName = "Healer"
			ElseIf IsDeclared("eWall") And $troopType = $eWall Then
				$troopName = "Wall Breaker"
			ElseIf IsDeclared("eLoon") And $troopType = $eLoon Then
				$troopName = "Balloon"
			ElseIf IsDeclared("eLava") And $troopType = $eLava Then
				$troopName = "Lava Hound"
			ElseIf IsDeclared("eBowl") And $troopType = $eBowl Then
				$troopName = "Bowler"
			ElseIf IsDeclared("eIceG") And $troopType = $eIceG Then
				$troopName = "Ice Golem"
			ElseIf IsDeclared("eHunt") And $troopType = $eHunt Then
				$troopName = "Headhunter"
			ElseIf IsDeclared("eAppW") And $troopType = $eAppW Then
				$troopName = "Apprentice Warden"
			ElseIf IsDeclared("eDruid") And $troopType = $eDruid Then
				$troopName = "Druid"
			ElseIf IsDeclared("eFurn") And $troopType = $eFurn Then
				$troopName = "Furnace"
			Else
				$troopName = "Troop" & $troopType ; Use number if name unknown
			EndIf
			
			If $troopName <> "" Then
				$troopInfo &= $troopName & ":" & $g_avAttackTroops[$i][1] & ", "
			EndIf
		EndIf
	Next
	
	; Remove trailing comma
	If StringRight($troopInfo, 2) = ", " Then
		$troopInfo = StringTrimRight($troopInfo, 2)
	EndIf
	
	If $troopInfo = "" Then $troopInfo = "No troops available"
	
	Return $troopInfo
EndFunc   ;==>GetAvailableTroopsString

; Helper function to get target information for AI
Func GetTargetInfoString()
	Local $targetInfo = "Base analysis: "
	
	; Add basic target information
	$targetInfo &= "Town Hall visible, "
	
	; Add resource information if available (with safe variable checking)
	If IsDeclared("g_iSearchGold") And $g_iSearchGold > 0 Then
		$targetInfo &= "Gold available: " & $g_iSearchGold & ", "
	EndIf
	If IsDeclared("g_iSearchElixir") And $g_iSearchElixir > 0 Then
		$targetInfo &= "Elixir available: " & $g_iSearchElixir & ", "
	EndIf
	If IsDeclared("g_iSearchDark") And $g_iSearchDark > 0 Then
		$targetInfo &= "Dark Elixir available: " & $g_iSearchDark & ", "
	EndIf
	
	; Add trophy information
	If IsDeclared("g_iSearchTrophy") And $g_iSearchTrophy > 0 Then
		$targetInfo &= "Trophy value: " & $g_iSearchTrophy & ", "
	EndIf
	
	; Add general strategy preferences
	$targetInfo &= "Looking for effective troop deployment strategy"
	
	; Remove trailing comma and space if present
	If StringRight($targetInfo, 2) = ", " Then
		$targetInfo = StringTrimRight($targetInfo, 2)
	EndIf
	
	Return $targetInfo
EndFunc   ;==>GetTargetInfoString

; Fallback strategy creation function
Func _CreateFallbackStrategy($nbSides, $iSlotsGiants)
	Local $fallbackStrategy[10][5]
	
	; Default strategy pattern: Giants first, then wallbreakers, then main troops, then heroes
	$fallbackStrategy[0][0] = IsDeclared("eGiant") ? $eGiant : 2
	$fallbackStrategy[0][1] = $nbSides
	$fallbackStrategy[0][2] = 1
	$fallbackStrategy[0][3] = 1
	$fallbackStrategy[0][4] = $iSlotsGiants
	
	$fallbackStrategy[1][0] = "CC"
	$fallbackStrategy[1][1] = 1
	$fallbackStrategy[1][2] = 1
	$fallbackStrategy[1][3] = 1
	$fallbackStrategy[1][4] = 1
	
	$fallbackStrategy[2][0] = IsDeclared("eWall") ? $eWall : 5
	$fallbackStrategy[2][1] = $nbSides
	$fallbackStrategy[2][2] = 1
	$fallbackStrategy[2][3] = 1
	$fallbackStrategy[2][4] = 1
	
	$fallbackStrategy[3][0] = IsDeclared("eBarb") ? $eBarb : 0
	$fallbackStrategy[3][1] = $nbSides
	$fallbackStrategy[3][2] = 1
	$fallbackStrategy[3][3] = 1
	$fallbackStrategy[3][4] = 0
	
	$fallbackStrategy[4][0] = IsDeclared("eArch") ? $eArch : 1
	$fallbackStrategy[4][1] = $nbSides
	$fallbackStrategy[4][2] = 1
	$fallbackStrategy[4][3] = 1
	$fallbackStrategy[4][4] = 0
	
	$fallbackStrategy[5][0] = "HEROES"
	$fallbackStrategy[5][1] = 1
	$fallbackStrategy[5][2] = 2
	$fallbackStrategy[5][3] = 1
	$fallbackStrategy[5][4] = 1
	
	; Fill remaining slots with empty values
	For $i = 6 To 9
		$fallbackStrategy[$i][0] = ""
		$fallbackStrategy[$i][1] = 0
		$fallbackStrategy[$i][2] = 0
		$fallbackStrategy[$i][3] = 0
		$fallbackStrategy[$i][4] = 0
	Next
	
	Return $fallbackStrategy
EndFunc   ;==>_CreateFallbackStrategy

; Final validation function for the strategy array
Func _ValidateStrategyArray($aStrategy, $nbSides)
	; Initialize color constants with safe fallbacks
	Local $iColorDebug = IsDeclared("COLOR_DEBUG") ? $COLOR_DEBUG : 0xFF00FF
	Local $iColorError = IsDeclared("COLOR_ERROR") ? $COLOR_ERROR : 0xFF0000
	Local $iColorSuccess = IsDeclared("COLOR_SUCCESS") ? $COLOR_SUCCESS : 0x00FF00
	
	SetLog("Validating strategy array before deployment...", $iColorDebug)
	
	; Check if it's even an array
	If Not IsArray($aStrategy) Then
		SetLog("CRITICAL: Strategy is not an array. Creating fallback.", $iColorError)
		Local $iSafeSlots = IsDeclared("g_iSlotsGiants") ? $g_iSlotsGiants : 2
		Return _CreateFallbackStrategy($nbSides, $iSafeSlots)
	EndIf
	
	; Check if it's a 2D array
	Local $iDimensions = UBound($aStrategy, 0)
	If $iDimensions <> 2 Then
		SetLog("CRITICAL: Strategy array has " & $iDimensions & " dimensions, need 2. Creating fallback.", $iColorError)
		Local $iSafeSlots = IsDeclared("g_iSlotsGiants") ? $g_iSlotsGiants : 2
		Return _CreateFallbackStrategy($nbSides, $iSafeSlots)
	EndIf
	
	; Check if it has rows
	Local $iRows = UBound($aStrategy, 1)
	If $iRows = 0 Then
		SetLog("CRITICAL: Strategy array has 0 rows. Creating fallback.", $iColorError)
		Local $iSafeSlots = IsDeclared("g_iSlotsGiants") ? $g_iSlotsGiants : 2
		Return _CreateFallbackStrategy($nbSides, $iSafeSlots)
	EndIf
	
	; Check if it has exactly 5 columns
	Local $iCols = UBound($aStrategy, 2)
	If $iCols <> 5 Then
		SetLog("CRITICAL: Strategy array has " & $iCols & " columns, need 5. Creating fallback.", $iColorError)
		Local $iSafeSlots = IsDeclared("g_iSlotsGiants") ? $g_iSlotsGiants : 2
		Return _CreateFallbackStrategy($nbSides, $iSafeSlots)
	EndIf
	
	; Validate each row and fix any bad data
	For $i = 0 To $iRows - 1
		; Column 0: Troop name/type (must be string or number)
		If Not IsString($aStrategy[$i][0]) And Not IsNumber($aStrategy[$i][0]) Then
			$aStrategy[$i][0] = IsDeclared("eBarb") ? $eBarb : 0
		EndIf
		
		; Columns 1-4: Must be integers
		For $j = 1 To 4
			If Not IsNumber($aStrategy[$i][$j]) Then
				$aStrategy[$i][$j] = 0
			Else
				; Ensure it's an integer
				$aStrategy[$i][$j] = Int($aStrategy[$i][$j])
			EndIf
		Next
	Next
	
	SetLog("Strategy array validation passed with " & $iRows & " entries.", $iColorSuccess)
	Return $aStrategy
EndFunc ;==>_ValidateStrategyArray
