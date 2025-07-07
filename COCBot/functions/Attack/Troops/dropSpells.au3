; #FUNCTION# ====================================================================================================================
; Name ..........: dropSpells
; Description ...: Drop spells during attack based on strategy
; Syntax ........: dropSpells($attackMode)
; Parameters ....: $attackMode - Attack mode (DB/LB)
; Return values .: None
; Author ........: Modified MyBot
; Modified ......: Added spell dropping functionality
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func dropSpells($attackMode = $g_iMatchMode)
	If $g_bDebugSetLog Then SetDebugLog("dropSpells() started for mode: " & $attackMode, $COLOR_DEBUG)
	
	; Check if we're still in attack mode
	If Not IsAttackPage() Then
		SetDebugLog("Not on attack page, skipping spell drop", $COLOR_DEBUG)
		Return
	EndIf
	
	; Wait random time between 3-8 seconds before dropping spells (reduced from 1-15)
	Local $iRandomDelay = Random(3, 8, 1)
	SetLog("Waiting " & $iRandomDelay & " seconds before dropping spells", $COLOR_INFO)
	If _Sleep($iRandomDelay * 1000) Then Return
	
	Local $spellsDropped = 0
	
	; Drop spells in strategic order
	; 1. Drop Lightning/Earthquake first (for destruction)
	If $g_abAttackUseLightSpell[$attackMode] Or $g_bSmartZapEnable Then
		If dropSpellType($eLSpell, "Lightning Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseEarthquakeSpell[$attackMode] = 1 Or $g_bSmartZapEnable Then
		If dropSpellType($eESpell, "Earthquake Spell") Then $spellsDropped += 1
	EndIf
	
	; 2. Drop support spells (Rage, Heal)
	If $g_abAttackUseRageSpell[$attackMode] Then
		If dropSpellType($eRSpell, "Rage Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseHealSpell[$attackMode] Then
		If dropSpellType($eHSpell, "Heal Spell") Then $spellsDropped += 1
	EndIf
	
	; 3. Drop utility spells
	If $g_abAttackUseJumpSpell[$attackMode] Then
		If dropSpellType($eJSpell, "Jump Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseHasteSpell[$attackMode] Then
		If dropSpellType($eHaSpell, "Haste Spell") Then $spellsDropped += 1
	EndIf
	
	; 4. Drop defensive/tactical spells
	If $g_abAttackUseFreezeSpell[$attackMode] Then
		If dropSpellType($eFSpell, "Freeze Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUsePoisonSpell[$attackMode] Then
		If dropSpellType($ePSpell, "Poison Spell") Then $spellsDropped += 1
	EndIf
	
	; 5. Drop special spells
	If $g_abAttackUseCloneSpell[$attackMode] Then
		If dropSpellType($eCSpell, "Clone Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseInvisibilitySpell[$attackMode] Then
		If dropSpellType($eISpell, "Invisibility Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseRecallSpell[$attackMode] Then
		If dropSpellType($eReSpell, "Recall Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseReviveSpell[$attackMode] Then
		If dropSpellType($eRvSpell, "Revive Spell") Then $spellsDropped += 1
	EndIf
	
	; 6. Drop spawning spells
	If $g_abAttackUseSkeletonSpell[$attackMode] Then
		If dropSpellType($eSkSpell, "Skeleton Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseBatSpell[$attackMode] Then
		If dropSpellType($eBtSpell, "Bat Spell") Then $spellsDropped += 1
	EndIf
	
	If $g_abAttackUseOvergrowthSpell[$attackMode] Then
		If dropSpellType($eOgSpell, "Overgrowth Spell") Then $spellsDropped += 1
	EndIf
	
	If $spellsDropped > 0 Then
		SetLog("Successfully dropped " & $spellsDropped & " different spell types", $COLOR_SUCCESS)
	Else
		SetLog("No spells were available to drop", $COLOR_INFO)
	EndIf
EndFunc   ;==>dropSpells

Func dropSpellType($spellIndex, $spellName)
	If $g_bDebugSetLog Then SetDebugLog("dropSpellType() for " & $spellName, $COLOR_DEBUG)
	
	; Check if we're still in attack mode
	If Not IsAttackPage() Then
		SetDebugLog("Not on attack page, stopping spell drop", $COLOR_DEBUG)
		Return False
	EndIf
	
	; Find the spell in attack troops array
	Local $spellSlot = -1
	Local $spellCount = 0
	
	For $i = 0 To UBound($g_avAttackTroops) - 1
		If $g_avAttackTroops[$i][0] = $spellIndex Then
			$spellSlot = $i
			$spellCount = $g_avAttackTroops[$i][1]
			ExitLoop
		EndIf
	Next
	
	If $spellSlot = -1 Or $spellCount <= 0 Then
		SetDebugLog("No " & $spellName & " available to drop", $COLOR_DEBUG)
		Return False
	EndIf
	
	SetLog("Dropping " & $spellCount & "x " & $spellName, $COLOR_SUCCESS)
	
	; Select the spell
	SelectDropTroop($spellSlot)
	If _Sleep(Random(300, 700)) Then Return False
	
	; Determine drop location based on spell type
	Local $dropX, $dropY
	
	Switch $spellIndex
		Case $eLSpell, $eESpell ; Lightning and Earthquake - target defenses/buildings
			$dropX = 430 + Random(-50, 50)
			$dropY = 350 + Random(-50, 50)
		Case $eHSpell, $eRSpell ; Heal and Rage - where troops are fighting
			$dropX = 400 + Random(-30, 30)
			$dropY = 320 + Random(-30, 30)
		Case $eJSpell ; Jump - near walls (closer to center)
			$dropX = 440 + Random(-40, 40)
			$dropY = 360 + Random(-40, 40)
		Case $eFSpell ; Freeze - on defenses
			$dropX = 420 + Random(-60, 60)
			$dropY = 340 + Random(-60, 60)
		Case $ePSpell ; Poison - on enemy clan castle troops or heroes
			$dropX = 430 + Random(-50, 50)
			$dropY = 350 + Random(-50, 50)
		Case $eHaSpell ; Haste - where troops are moving
			$dropX = 410 + Random(-40, 40)
			$dropY = 330 + Random(-40, 40)
		Case $eCSpell ; Clone - where main troops are
			$dropX = 400 + Random(-30, 30)
			$dropY = 320 + Random(-30, 30)
		Case $eISpell ; Invisibility - on important troops
			$dropX = 420 + Random(-50, 50)
			$dropY = 340 + Random(-50, 50)
		Case $eReSpell ; Recall - strategic location
			$dropX = 430 + Random(-40, 40)
			$dropY = 350 + Random(-40, 40)
		Case $eRvSpell ; Revive - where heroes died
			$dropX = 440 + Random(-60, 60)
			$dropY = 360 + Random(-60, 60)
		Case $eSkSpell, $eBtSpell ; Skeleton and Bat - spread around
			$dropX = 425 + Random(-70, 70)
			$dropY = 345 + Random(-70, 70)
		Case $eOgSpell ; Overgrowth - strategic location
			$dropX = 415 + Random(-50, 50)
			$dropY = 335 + Random(-50, 50)
		Case Else ; Default location
			$dropX = 430 + Random(-50, 50)
			$dropY = 350 + Random(-50, 50)
	EndSwitch
	
	; Drop the spell(s)
	For $j = 0 To $spellCount - 1
		; Check if we're still in attack mode before each drop
		If Not IsAttackPage() Then
			SetDebugLog("Attack ended during spell drop", $COLOR_DEBUG)
			Return False
		EndIf
		
		Click($dropX + Random(-10, 10), $dropY + Random(-10, 10), 1, 0, "#0384")
		If _Sleep(Random(800, 1200)) Then Return False
		
		; Add some variation to drop locations for multiple spells
		$dropX += Random(-20, 20)
		$dropY += Random(-20, 20)
		
		; Update spell count in the array after dropping
		$g_avAttackTroops[$spellSlot][1] -= 1
	Next
	
	SetDebugLog("Successfully dropped " & $spellCount & "x " & $spellName, $COLOR_DEBUG)
	Return True
EndFunc   ;==>dropSpellType
