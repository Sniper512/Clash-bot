; #FUNCTION# ====================================================================================================================
; Name ..........: GetLocationMine
; Description ...:
; Syntax ........: GetLocationMine()
; Parameters ....:
; Return values .: String with locations
; Author ........:
; Modified ......: ProMac (04-2016)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func GetLocationMine()

	Local $sDirectory = @ScriptDir & "\imgxml\Storages\GoldMines"
	Local $sTxtName = "Mines"
	Local $iMaxReturns = 7

	; Snow Theme detected
	If $g_iDetectedImageType = 1 Then
		$sDirectory = @ScriptDir & "\imgxml\Storages\Mines_Snow"
		$sTxtName = "SnowMines"
	EndIf

	Local $aTempResult = returnMultipleMatches($sDirectory, $iMaxReturns)
	Local $aEndResult = ConvertImgloc2MBR($aTempResult, $iMaxReturns)
	If $g_bDebugBuildingPos Then SetLog("#*# GetLocation" & $sTxtName & ": " & $aEndResult, $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult, $sTxtName)

	Return GetListPixel($aEndResult)
EndFunc   ;==>GetLocationMine

Func GetLocationElixir()
	Local $sDirectory = @ScriptDir & "\imgxml\Storages\Collectors"
	Local $sTxtName = "Collectors"
	Local $iMaxReturns = 7

	; Snow Theme detected
	If $g_iDetectedImageType = 1 Then
		$sDirectory = @ScriptDir & "\imgxml\Storages\Collectors_Snow"
		$sTxtName = "SnowCollectors"
	EndIf

	Local $aTempResult = returnMultipleMatches($sDirectory, $iMaxReturns)
	Local $aEndResult = ConvertImgloc2MBR($aTempResult, $iMaxReturns)
	If $g_bDebugBuildingPos Then SetLog("#*# GetLocation" & $sTxtName & ": " & $aEndResult, $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult, $sTxtName)

	Return GetListPixel($aEndResult)
EndFunc   ;==>GetLocationElixir

Func GetLocationDarkElixir()
	Local $sDirectory = @ScriptDir & "\imgxml\Storages\Drills"
	Local $iMaxReturns = 3
	Local $aTempResult = returnMultipleMatches($sDirectory, $iMaxReturns)
	Local $aEndResult = ConvertImgloc2MBR($aTempResult, $iMaxReturns)

	If $g_bDebugBuildingPos Then SetLog("#*# GetLocationDarkElixir: " & $aEndResult, $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult, "DarkElixir")

	Return GetListPixel($aEndResult)
EndFunc   ;==>GetLocationDarkElixir

; ###############################################################################################################

; USES OLD OPENCV DETECTION
Func GetLocationTownHall()
	Local $aEndResult = DllCallMyBot("getLocationTownHall", "ptr", $g_hHBitmap2)
	If $g_bDebugBuildingPos Then SetLog("#*# GetLocationTownHall: " & $aEndResult[0], $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "TownHall")

	Return GetListPixel($aEndResult[0])
EndFunc   ;==>GetLocationTownHall

; USES OLD OPENCV DETECTION
Func GetLocationDarkElixirStorageWithLevel()
	Local $aEndResult = DllCallMyBot("getLocationDarkElixirStorageWithLevel", "ptr", $g_hHBitmap2)
	If $g_bDebugBuildingPos Then SetLog("#*# GetLocationDarkElixirStorageWithLevel: " & $aEndResult[0], $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "DarkElixirStorageWithLevel")

	Return $aEndResult[0]
EndFunc   ;==>GetLocationDarkElixirStorageWithLevel

; USES OLD OPENCV DETECTION
Func GetLocationDarkElixirStorage()
	Local $aEndResult = DllCallMyBot("getLocationDarkElixirStorage", "ptr", $g_hHBitmap2)
	If $g_bDebugBuildingPos Then SetLog("#*# GetLocationDarkElixirStorage: " & $aEndResult[0], $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "DarkElixirStorage")

	Return GetListPixel($aEndResult[0])
EndFunc   ;==>GetLocationDarkElixirStorage

; USES OLD OPENCV DETECTION
Func GetLocationElixirWithLevel()
	;Note about returned levels:
	; Lvl 0 elixir collector from level 1 to level 4
	; Lvl 1 elixir collector level 5
	; Lvl 2 elixir collector level 6
	; Lvl 3 elixir collector level 7
	; Lvl 4 elixir collector level 8
	; Lvl 5 elixir collector level 9
	; Lvl 6 elixir collector level 10
	; Lvl 7 elixir collector level 11
	; Lvl 8 elixir collector level 12
	; Lvl 9 elixir collector level 13
	; Lvl 10 elixir collector level 14

	If $g_iDetectedImageType = 0 Then
		Local $aEndResult = DllCallMyBot("getLocationElixirExtractorWithLevel", "ptr", $g_hHBitmap2)
		If $g_bDebugBuildingPos Then SetLog("#*# getLocationElixirExtractorWithLevel: " & $aEndResult[0], $COLOR_DEBUG)
		If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "ElixirExtractorWithLevel")
	Else
		Local $aEndResult = DllCallMyBot("getLocationSnowElixirExtractorWithLevel", "ptr", $g_hHBitmap2)
		If $g_bDebugBuildingPos Then SetLog("#*# getLocationSnowElixirExtractorWithLevel: " & $aEndResult[0], $COLOR_DEBUG)
		If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "SnowElixirExtractorWithLevel")
	EndIf

	Return $aEndResult[0]
EndFunc   ;==>GetLocationElixirWithLevel

; USES OLD OPENCV DETECTION
Func GetLocationMineWithLevel()
	;Note about returned levels:
	; Lvl 0 gold mine from level 1 to level 4
	; Lvl 1 gold mine level 5
	; Lvl 2 gold mine level 6
	; Lvl 3 gold mine level 7
	; Lvl 4 gold mine level 8
	; Lvl 5 gold mine level 9
	; Lvl 6 gold mine level 10
	; Lvl 7 gold mine level 11
	; Lvl 8 gold mine level 12
	; Lvl 9 gold mine level 13
	; Lvl 10 gold mine level 14

	If $g_iDetectedImageType = 0 Then
		Local $aEndResult = DllCallMyBot("getLocationMineExtractorWithLevel", "ptr", $g_hHBitmap2)
		If $g_bDebugBuildingPos Then SetLog("#*# getLocationMineExtractorWithLevel: " & $aEndResult[0], $COLOR_DEBUG)
		If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "MineExtractorWithLevel")

	Else
		Local $aEndResult = DllCallMyBot("getLocationSnowMineExtractorWithLevel", "ptr", $g_hHBitmap2)
		If $g_bDebugBuildingPos Then SetLog("#*# getLocationSnowMineExtractorWithLevel: " & $aEndResult[0], $COLOR_DEBUG)
		If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult[0], "SnowMineExtractorWithLevel")
	EndIf
	Return $aEndResult[0]
EndFunc   ;==>GetLocationMineWithLevel

Func GetLocationDarkElixirWithLevel()
	Local $sDirectory = @ScriptDir & "\imgxml\Storages\Drills"
	Local $iMaxReturns = 3
	Local $aTempResult = returnMultipleMatches($sDirectory, $iMaxReturns)
	Local $aEndResult = ConvertImgloc2MBR($aTempResult, $iMaxReturns, True)
	If $g_bDebugBuildingPos Then SetLog("#*# getLocationDarkElixirExtractorWithLevel: " & $aEndResult, $COLOR_DEBUG)
	If $g_bDebugGetLocation Then DebugImageGetLocation($aEndResult, "DarkElixirExtractorWithLevel")

	Return $aEndResult
EndFunc   ;==>GetLocationDarkElixirWithLevel


; #FUNCTION# ====================================================================================================================
; Name ..........: GetLocationBuilding
; Description ...: Finds any buildings in global enum & $g_sBldgNames list, saves property data into $g_oBldgAttackInfo dictionary.
; Syntax ........: GetLocationBuilding($iBuildingType[, $iAttackingTH = 11[, $forceCaptureRegion = True]])
; Parameters ....: $iBuildingType       - an integer value with enum of building to find and retrieve information about from  $g_sBldgNames list
;                  $iAttackingTH        - [optional] an integer value of TH being attacked. Default is 11. Lower TH level reduces # of images by setting MaxLevel
;                  $bforceCaptureRegion  - [optional] a boolean value. Default is True. "False" avoids repetitive capture of same base for multiple finds in row.
; Return values .: None
; Author ........: MonkeyHunter (04-2017)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func GetLocationBuilding($iBuildingType, $iAttackingTH = $g_iMaxTHLevel, $bForceCaptureRegion = True)

	If $g_bDebugSetLog Then SetDebugLog("Begin GetLocationBuilding: " & $g_sBldgNames[$iBuildingType], $COLOR_DEBUG1)
	Local $hTimer = __TimerInit() ; timer to track image detection time

	; Variables
	Local $TotalBuildings = 0
	Local $minLevel = 0
	Local $statFile = ""
	Local $fullCocAreas = $CocDiamondDCD
	Local $BuildingXY, $redLines, $bRedLineExists, $aBldgCoord, $sTempCoord, $tmpNumFound
	Local $tempNewLevel, $tempExistingLevel, $sLocCoord, $sNearCoord, $sFarCoord, $directory, $iCountUpdate

	; error proof TH level
	If $iAttackingTH = "-" Then $iAttackingTH = $g_iMaxTHLevel

	; Get path to image file
	If _ObjSearch($g_oBldgImages, $iBuildingType & "_" & $g_iDetectedImageType) = True Then ; check if image exists to prevent error when snow images are not avialable for building type
		$directory = _ObjGetValue($g_oBldgImages, $iBuildingType & "_" & $g_iDetectedImageType)
		If @error Then
			_ObjErrMsg("_ObjGetValue $g_oBldgImages " & $g_sBldgNames[$iBuildingType] & ($g_iDetectedImageType = 1 ? "Snow " : " "), @error) ; Log COM error prevented
			SetError(1, 0, -1) ; unknown image, must exit find
			Return
		EndIf
	Else
		$directory = _ObjGetValue($g_oBldgImages, $iBuildingType & "_0") ; fall back to regular non-snow image if needed
		If @error Then
			_ObjErrMsg("_ObjGetValue $g_oBldgImages" & $g_sBldgNames[$iBuildingType], @error) ; Log COM error prevented
			SetError(1, 0, -1) ; unknown image, must exit find
			Return
		EndIf
	EndIf

	; Get max number of buildings available for TH level
	Local $maxReturnPoints = _ObjGetValue($g_oBldgMaxQty, $iBuildingType)[$iAttackingTH - 1]
	If @error Then
		_ObjErrMsg("_ObjGetValue $g_oBldgMaxQty", @error) ; Log COM error prevented
		$maxReturnPoints = 20 ; unknown number of buildings, then set equal to 20 and keep going
	EndIf

	; Get redline data
	If _ObjSearch($g_oBldgAttackInfo, $eBldgRedLine & "_OBJECTPOINTS") = True Then
		If _ObjGetValue($g_oBldgAttackInfo, $eBldgRedLine & "_COUNT") > 50 Then ; if count is less 50, try again to more red line locations
			$redLines = _ObjGetValue($g_oBldgAttackInfo, $eBldgRedLine & "_OBJECTPOINTS")
			If @error Then _ObjErrMsg("_ObjGetValue $g_oBldgAttackInfo redline", @error) ; Log COM error prevented
			If IsString($redLines) And $redLines <> "" And $redLines <> "ECD" Then ; error check for null red line data in dictionary
				$bRedLineExists = True
			Else
				$redLines = ""
				$bRedLineExists = False
			EndIf
		Else ; if less than 25 redline stored, then try again.
			$redLines = ""
			$bRedLineExists = False
		EndIf
	Else
		$redLines = ""
		$bRedLineExists = False
	EndIf

	; get max building level available for TH
	Local $maxLevel = _ObjGetValue($g_oBldgLevels, $iBuildingType)[$iAttackingTH - 1]
	If @error Then
		_ObjErrMsg("_ObjGetValue $g_oBldgLevels", @error) ; Log COM error prevented
		$maxLevel = 20 ; unknown number of building levels, then set equal to 20
	EndIf

	If $bForceCaptureRegion = True Then _CaptureRegion2()

	; Perform the search
	Local $res = DllCallMyBot("SearchMultipleTilesBetweenLevels", "handle", $g_hHBitmap2, "str", $directory, "str", $fullCocAreas, "Int", $maxReturnPoints, "str", $redLines, "Int", $minLevel, "Int", $maxLevel)
	If @error Then _logErrorDLLCall($g_sLibMyBotPath, @error)
	If checkImglocError($res, "SearchMultipleTilesBetweenLevels", $directory) = True Then ; check for bad values returned from DLL
		SetError(2, 1, 1) ; set return = 1 when no building found
		Return
	EndIf

	;	Get the redline data
	If $bRedLineExists = False Then ; if already exists, then skip saving again.
		Local $aValue = RetrieveImglocProperty("redline", "")
		If $aValue <> "" Then ; redline exists
			Local $aCoordsSplit = StringSplit($aValue, "|") ; split redlines in x,y, to get count of redline locations
			If $aCoordsSplit[0] > 50 Then ; check that we have enough red line points or keep trying for better data
				$redLines = $aValue
				_ObjPutValue($g_oBldgAttackInfo, $eBldgRedLine & "_OBJECTPOINTS", $redLines) ; add/update value
				If @error Then _ObjErrMsg("_ObjPutValue $g_oBldgAttackInfo", @error)
				Local $redlinesCount = $aCoordsSplit[0] ; assign to variable to avoid constant check for array exists
				_ObjPutValue($g_oBldgAttackInfo, $eBldgRedLine & "_COUNT", $redlinesCount)
				If @error Then _ObjErrMsg("_ObjSetValue $g_oBldgAttackInfo", @error)
			Else
				Setdebuglog("> Not enough red line points to save in building dictionary?", $COLOR_WARNING)
			EndIf
		Else
			SetLog("> DLL Error getting Red Lines in GetLocationBuilding", $COLOR_ERROR)
		EndIf
	EndIf

	; Get rest of data return by DLL
	If $res[0] <> "" Then
		Local $aKeys = StringSplit($res[0], "|", $STR_NOCOUNT) ; Spilt each returned key into array
		For $i = 0 To UBound($aKeys) - 1 ; Loop through the array to get all property values
			;SetDebugLog("$aKeys[" & $i & "]: " & $aKeys[$i], $COLOR_DEBUG)  ; key value debug

			; Object level retrieval
			$tempNewLevel = Int(RetrieveImglocProperty($aKeys[$i], "objectlevel"))

			; Munber of objects found retrieval
			$tmpNumFound = Int(RetrieveImglocProperty($aKeys[$i], "totalobjects"))

			; Location string retrieval
			$sTempCoord = RetrieveImglocProperty($aKeys[$i], "objectpoints") ; get location points

			; Check for duplicate locations from DLL when more than 1 location returned?
			If $i = 0 And StringLen($sTempCoord) > 7 Then
				$iCountUpdate = RemoveDupNearby($sTempCoord) ; remove duplicates BYREF, return location count
				If $tmpNumFound <> $iCountUpdate And $iCountUpdate <> "" Then $tmpNumFound = $iCountUpdate
			EndIf

			; check if this building is max level found
			If _ObjSearch($g_oBldgAttackInfo, $iBuildingType & "_MAXLVLFOUND") Then
				$tempExistingLevel = _ObjGetValue($g_oBldgAttackInfo, $iBuildingType & "_MAXLVLFOUND")
			Else
				$tempExistingLevel = 0
			EndIf
			If Int($tempNewLevel) > Int($tempExistingLevel) Then ; save if max level
				_ObjPutValue($g_oBldgAttackInfo, $iBuildingType & "_MAXLVLFOUND", $tempNewLevel)
				If @error Then _ObjErrMsg("_ObjPutValue " & $g_sBldgNames[$iBuildingType] & " _MAXLVLFOUND", @error) ; log errors
				_ObjPutValue($g_oBldgAttackInfo, $iBuildingType & "_NAMEFOUND", $aKeys[$i])
				If @error Then _ObjErrMsg("_ObjPutValue " & $g_sBldgNames[$iBuildingType] & " _NAMEFOUND", @error) ; log errors
			EndIf

			; save all relevant data on every image found using key number to differentiate data, ONLY WHEN more than one image is found!
			If UBound($aKeys) > 1 Then
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_LVLFOUND_K" & $i, $tempNewLevel)
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _LVLFOUND_K" & $i, @error) ; log errors
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_FILENAME_K" & $i, $aKeys[$i])
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _FILENAME_K" & $i, @error) ; log errors
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_COUNT_K" & $i, $tmpNumFound)
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _COUNT_K" & $i, @error) ; log errors
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_OBJECTPOINTS_K" & $i, $sTempCoord) ; save string of locations
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _OBJECTPOINTS_K" & $i, @error) ; Log errors
			EndIf

			; check if valid objectpoints returned
			If $sTempCoord <> "" Then
				If $sLocCoord = "" Then ; check if 1st set of points
					$sLocCoord = $sTempCoord
					$TotalBuildings = $tmpNumFound
				Else ; if not 1st set, then merge and check for duplicate locations in object points
					$iCountUpdate = AddPoints_RemoveDuplicate($sLocCoord, $sTempCoord, $maxReturnPoints) ; filter results to remove duplicate locations matching same building location, return no more than max allowed
					If $iCountUpdate <> "" Then $TotalBuildings = $iCountUpdate
				EndIf
			Else
				SetDebugLog("> no data in 'objectpoints' request?", $COLOR_WARNING)
			EndIf
		Next
	EndIf

	$aBldgCoord = decodeMultipleCoords($sLocCoord) ; change string into array with location x,y sub-arrays inside each row
	;$aBldgCoord = GetListPixel($sLocCoord, ",", "GetLocationBuilding" & $g_sBldgNames[$iBuildingType]) ; change string into array with debugattackcsv message instead of general log msg?

	If $g_bDebugBuildingPos Or  $g_bDebugSetLog Then ; temp debug message to display building location string returned, and convert "_LOCATION" array to string message for comparison
		SetLog("Bldg Loc Coord String: " & $sLocCoord, $COLOR_DEBUG)
		Local $sText
		Select
			Case UBound($aBldgCoord, 1) > 1 And IsArray($aBldgCoord[1]) ; if we have array of arrays, separate and list
				$sText = PixelArrayToString($aBldgCoord, ",")
			Case IsArray($aBldgCoord[0]) ; single row with array
				Local $aPixelb = $aBldgCoord[0]
				$sText = PixelToString($aPixelb, ";")
			Case IsArray($aBldgCoord[0]) = 0
				$sText = PixelToString($aBldgCoord, ":")
			Case Else
				$sText = "Monkey ate bad banana!"
		EndSelect
		SetLog($g_sBldgNames[$iBuildingType] & " $aBldgCoord Array Contents: " & $sText, $COLOR_DEBUG)
	EndIf

	If IsArray($aBldgCoord) Then ; string and array location(s) save to dictionary
		_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_OBJECTPOINTS", $sLocCoord) ; save string of locations
		If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _OBJECTPOINTS", @error) ; Log errors
		_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_LOCATION", $aBldgCoord) ; save array of locations
		If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _LOCATION", @error) ; Log errors
	EndIf

	If $TotalBuildings <> 0 Then ; building count save to dictionary
		_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_COUNT", $TotalBuildings)
		If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _COUNT", @error) ; Log errors
	EndIf
	SetLog("Total " & $g_sBldgNames[$iBuildingType] & " Buildings: " & $TotalBuildings)

	Local $iTime = __TimerDiff($hTimer) * 0.001 ; Image search time saved to dictionary in seconds
	_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_FINDTIME", $iTime)
	If @error Then _ObjErrMsg("_ObjAdd" & $g_sBldgNames[$iBuildingType] & " _FINDTIME", @error) ; Log errors

	If $g_bDebugBuildingPos Then SetLog("  - Location(s) found in: " & Round($iTime, 2) & " seconds ", $COLOR_DEBUG)

EndFunc   ;==>GetLocationBuilding

; Enhanced detection with confidence scoring and multi-scale matching
Func GetLocationBuildingEnhanced($iBuildingType, $iAttackingTH = $g_iMaxTHLevel, $bForceCaptureRegion = True, $fMinConfidence = 0.8)

	If $g_bDebugSetLog Then SetDebugLog("Begin Enhanced GetLocationBuilding: " & $g_sBldgNames[$iBuildingType], $COLOR_DEBUG1)
	Local $hTimer = __TimerInit()

	; Variables
	Local $TotalBuildings = 0
	Local $minLevel = 0
	Local $statFile = ""
	Local $fullCocAreas = $CocDiamondDCD
	Local $BuildingXY, $redLines, $bRedLineExists, $aBldgCoord, $sTempCoord, $tmpNumFound
	Local $tempNewLevel, $tempExistingLevel, $sLocCoord, $sNearCoord, $sFarCoord, $directory, $iCountUpdate

	; error proof TH level
	If $iAttackingTH = "-" Then $iAttackingTH = $g_iMaxTHLevel

	; Get path to image file
	If _ObjSearch($g_oBldgImages, $iBuildingType & "_" & $g_iDetectedImageType) = True Then ; check if image exists to prevent error when snow images are not avialable for building type
		$directory = _ObjGetValue($g_oBldgImages, $iBuildingType & "_" & $g_iDetectedImageType)
		If @error Then
			_ObjErrMsg("_ObjGetValue $g_oBldgImages " & $g_sBldgNames[$iBuildingType] & ($g_iDetectedImageType = 1 ? "Snow " : " "), @error) ; Log COM error prevented
			SetError(1, 0, -1) ; unknown image, must exit find
			Return
		EndIf
	Else
		$directory = _ObjGetValue($g_oBldgImages, $iBuildingType & "_0") ; fall back to regular non-snow image if needed
		If @error Then
			_ObjErrMsg("_ObjGetValue $g_oBldgImages" & $g_sBldgNames[$iBuildingType], @error) ; Log COM error prevented
			SetError(1, 0, -1) ; unknown image, must exit find
			Return
		EndIf
	EndIf

	; Get max number of buildings available for TH level
	Local $maxReturnPoints = _ObjGetValue($g_oBldgMaxQty, $iBuildingType)[$iAttackingTH - 1]
	If @error Then
		_ObjErrMsg("_ObjGetValue $g_oBldgMaxQty", @error) ; Log COM error prevented
		$maxReturnPoints = 20 ; unknown number of buildings, then set equal to 20 and keep going
	EndIf

	; Get redline data
	If _ObjSearch($g_oBldgAttackInfo, $eBldgRedLine & "_OBJECTPOINTS") = True Then
		If _ObjGetValue($g_oBldgAttackInfo, $eBldgRedLine & "_COUNT") > 50 Then ; if count is less 50, try again to more red line locations
			$redLines = _ObjGetValue($g_oBldgAttackInfo, $eBldgRedLine & "_OBJECTPOINTS")
			If @error Then _ObjErrMsg("_ObjGetValue $g_oBldgAttackInfo redline", @error) ; Log COM error prevented
			If IsString($redLines) And $redLines <> "" And $redLines <> "ECD" Then ; error check for null red line data in dictionary
				$bRedLineExists = True
			Else
				$redLines = ""
				$bRedLineExists = False
			EndIf
		Else ; if less than 25 redline stored, then try again.
			$redLines = ""
			$bRedLineExists = False
		EndIf
	Else
		$redLines = ""
		$bRedLineExists = False
	EndIf

	; get max building level available for TH
	Local $maxLevel = _ObjGetValue($g_oBldgLevels, $iBuildingType)[$iAttackingTH - 1]
	If @error Then
		_ObjErrMsg("_ObjGetValue $g_oBldgLevels", @error) ; Log COM error prevented
		$maxLevel = 20 ; unknown number of building levels, then set equal to 20
	EndIf

	If $bForceCaptureRegion = True Then _CaptureRegion2()

	; Multi-scale detection for better accuracy
	Local $aScaleFactors = [0.9, 1.0, 1.1] ; Different zoom levels
	Local $aBestResults[0], $fBestConfidence = 0
	
	For $i = 0 To UBound($aScaleFactors) - 1
		Local $fScale = $aScaleFactors[$i]
		
		; Perform search at different scales
		Local $res = DllCallMyBot("SearchMultipleTilesBetweenLevelsEnhanced", "handle", $g_hHBitmap2, "str", $directory, "str", $fullCocAreas, "Int", $maxReturnPoints, "str", $redLines, "Int", $minLevel, "Int", $maxLevel, "float", $fScale, "float", $fMinConfidence)
		
		If @error Then _logErrorDLLCall($g_sLibMyBotPath, @error)
		If checkImglocError($res, "SearchMultipleTilesBetweenLevelsEnhanced", $directory) = False Then
			; Get confidence scores for results
			Local $aConfidenceScores = GetDetectionConfidence($res)
			If UBound($aConfidenceScores) > 0 And $aConfidenceScores[0] > $fBestConfidence Then
				$fBestConfidence = $aConfidenceScores[0]
				$aBestResults = $res
			EndIf
		EndIf
	Next
	
	; Use best results from multi-scale detection
	If UBound($aBestResults) > 0 Then
		$res = $aBestResults
		SetDebugLog("Best detection confidence: " & Round($fBestConfidence * 100, 1) & "%", $COLOR_SUCCESS)
	Else
		SetError(2, 1, 1)
		Return
	EndIf

	; Get redline data
	If $bRedLineExists = False Then ; if already exists, then skip saving again.
		Local $aValue = RetrieveImglocProperty("redline", "")
		If $aValue <> "" Then ; redline exists
			Local $aCoordsSplit = StringSplit($aValue, "|") ; split redlines in x,y, to get count of redline locations
			If $aCoordsSplit[0] > 50 Then ; check that we have enough red line points or keep trying for better data
				$redLines = $aValue
				_ObjPutValue($g_oBldgAttackInfo, $eBldgRedLine & "_OBJECTPOINTS", $redLines) ; add/update value
				If @error Then _ObjErrMsg("_ObjPutValue $g_oBldgAttackInfo", @error)
				Local $redlinesCount = $aCoordsSplit[0] ; assign to variable to avoid constant check for array exists
				_ObjPutValue($g_oBldgAttackInfo, $eBldgRedLine & "_COUNT", $redlinesCount)
				If @error Then _ObjErrMsg("_ObjSetValue $g_oBldgAttackInfo", @error)
			Else
				Setdebuglog("> Not enough red line points to save in building dictionary?", $COLOR_WARNING)
			EndIf
		Else
			SetLog("> DLL Error getting Red Lines in GetLocationBuilding", $COLOR_ERROR)
		EndIf
	EndIf

	; Get rest of data return by DLL
	If $res[0] <> "" Then
		Local $aKeys = StringSplit($res[0], "|", $STR_NOCOUNT) ; Spilt each returned key into array
		For $i = 0 To UBound($aKeys) - 1 ; Loop through the array to get all property values
			;SetDebugLog("$aKeys[" & $i & "]: " & $aKeys[$i], $COLOR_DEBUG)  ; key value debug

			; Object level retrieval
			$tempNewLevel = Int(RetrieveImglocProperty($aKeys[$i], "objectlevel"))

			; Munber of objects found retrieval
			$tmpNumFound = Int(RetrieveImglocProperty($aKeys[$i], "totalobjects"))

			; Location string retrieval
			$sTempCoord = RetrieveImglocProperty($aKeys[$i], "objectpoints") ; get location points

			; Check for duplicate locations from DLL when more than 1 location returned?
			If $i = 0 And StringLen($sTempCoord) > 7 Then
				$iCountUpdate = RemoveDupNearby($sTempCoord) ; remove duplicates BYREF, return location count
				If $tmpNumFound <> $iCountUpdate And $iCountUpdate <> "" Then $tmpNumFound = $iCountUpdate
			EndIf

			; check if this building is max level found
			If _ObjSearch($g_oBldgAttackInfo, $iBuildingType & "_MAXLVLFOUND") Then
				$tempExistingLevel = _ObjGetValue($g_oBldgAttackInfo, $iBuildingType & "_MAXLVLFOUND")
			Else
				$tempExistingLevel = 0
			EndIf
			If Int($tempNewLevel) > Int($tempExistingLevel) Then ; save if max level
				_ObjPutValue($g_oBldgAttackInfo, $iBuildingType & "_MAXLVLFOUND", $tempNewLevel)
				If @error Then _ObjErrMsg("_ObjPutValue " & $g_sBldgNames[$iBuildingType] & " _MAXLVLFOUND", @error) ; log errors
				_ObjPutValue($g_oBldgAttackInfo, $iBuildingType & "_NAMEFOUND", $aKeys[$i])
				If @error Then _ObjErrMsg("_ObjPutValue " & $g_sBldgNames[$iBuildingType] & " _NAMEFOUND", @error) ; log errors
			EndIf

			; save all relevant data on every image found using key number to differentiate data, ONLY WHEN more than one image is found!
			If UBound($aKeys) > 1 Then
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_LVLFOUND_K" & $i, $tempNewLevel)
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _LVLFOUND_K" & $i, @error) ; log errors
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_FILENAME_K" & $i, $aKeys[$i])
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _FILENAME_K" & $i, @error) ; log errors
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_COUNT_K" & $i, $tmpNumFound)
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _COUNT_K" & $i, @error) ; log errors
				_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_OBJECTPOINTS_K" & $i, $sTempCoord) ; save string of locations
				If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _OBJECTPOINTS_K" & $i, @error) ; Log errors
			EndIf

			; check if valid objectpoints returned
			If $sTempCoord <> "" Then
				If $sLocCoord = "" Then ; check if 1st set of points
					$sLocCoord = $sTempCoord
					$TotalBuildings = $tmpNumFound
				Else ; if not 1st set, then merge and check for duplicate locations in object points
					$iCountUpdate = AddPoints_RemoveDuplicate($sLocCoord, $sTempCoord, $maxReturnPoints) ; filter results to remove duplicate locations matching same building location, return no more than max allowed
					If $iCountUpdate <> "" Then $TotalBuildings = $iCountUpdate
				EndIf
			Else
				SetDebugLog("> no data in 'objectpoints' request?", $COLOR_WARNING)
			EndIf
		Next
	EndIf

	$aBldgCoord = decodeMultipleCoords($sLocCoord) ; change string into array with location x,y sub-arrays inside each row
	;$aBldgCoord = GetListPixel($sLocCoord, ",", "GetLocationBuilding" & $g_sBldgNames[$iBuildingType]) ; change string into array with debugattackcsv message instead of general log msg?

	If $g_bDebugBuildingPos Or  $g_bDebugSetLog Then ; temp debug message to display building location string returned, and convert "_LOCATION" array to string message for comparison
		SetLog("Bldg Loc Coord String: " & $sLocCoord, $COLOR_DEBUG)
		Local $sText
		Select
			Case UBound($aBldgCoord, 1) > 1 And IsArray($aBldgCoord[1]) ; if we have array of arrays, separate and list
				$sText = PixelArrayToString($aBldgCoord, ",")
			Case IsArray($aBldgCoord[0]) ; single row with array
				Local $aPixelb = $aBldgCoord[0]
				$sText = PixelToString($aPixelb, ";")
			Case IsArray($aBldgCoord[0]) = 0
				$sText = PixelToString($aBldgCoord, ":")
			Case Else
				$sText = "Monkey ate bad banana!"
		EndSelect
		SetLog($g_sBldgNames[$iBuildingType] & " $aBldgCoord Array Contents: " & $sText, $COLOR_DEBUG)
	EndIf

	If IsArray($aBldgCoord) Then ; string and array location(s) save to dictionary
		_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_OBJECTPOINTS", $sLocCoord) ; save string of locations
		If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _OBJECTPOINTS", @error) ; Log errors
		_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_LOCATION", $aBldgCoord) ; save array of locations
		If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _LOCATION", @error) ; Log errors
	EndIf

	If $TotalBuildings <> 0 Then ; building count save to dictionary
		_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_COUNT", $TotalBuildings)
		If @error Then _ObjErrMsg("_ObjAdd " & $g_sBldgNames[$iBuildingType] & " _COUNT", @error) ; Log errors
	EndIf
	SetLog("Total " & $g_sBldgNames[$iBuildingType] & " Buildings: " & $TotalBuildings)

	Local $iTime = __TimerDiff($hTimer) * 0.001 ; Image search time saved to dictionary in seconds
	_ObjAdd($g_oBldgAttackInfo, $iBuildingType & "_FINDTIME", $iTime)
	If @error Then _ObjErrMsg("_ObjAdd" & $g_sBldgNames[$iBuildingType] & " _FINDTIME", @error) ; Log errors

	If $g_bDebugBuildingPos Then SetLog("  - Location(s) found in: " & Round($iTime, 2) & " seconds ", $COLOR_DEBUG)

EndFunc   ;==>GetLocationBuildingEnhanced

; Machine Learning enhanced detection system
Func GetLocationBuildingML($iBuildingType, $iAttackingTH = $g_iMaxTHLevel, $bForceCaptureRegion = True)
	If $g_bDebugSetLog Then SetDebugLog("Begin ML-Enhanced GetLocationBuilding: " & $g_sBldgNames[$iBuildingType], $COLOR_DEBUG1)
	Local $hTimer = __TimerInit()
	
	; Pre-processing: Analyze image quality and adjust parameters
	Local $aImageQuality = AnalyzeImageQuality()
	Local $fConfidenceThreshold = AdaptConfidenceThreshold($aImageQuality)
	Local $iSearchRadius = AdaptSearchRadius($iBuildingType, $aImageQuality)
	
	; Context analysis: Understand base layout patterns
	Local $aBaseContext = AnalyzeBaseContext($iBuildingType, $iAttackingTH)
	Local $aPredictedLocations = PredictBuildingLocations($iBuildingType, $aBaseContext)
	
	; Priority-based search: Start with most likely locations
	Local $aTotalResults[0]
	For $i = 0 To UBound($aPredictedLocations) - 1
		Local $aSearchArea = CreateFocusedSearchArea($aPredictedLocations[$i], $iSearchRadius)
		
		; Focused search in predicted area
		Local $res = DllCallMyBot("SearchMultipleTilesBetweenLevels", "handle", $g_hHBitmap2, "str", $directory, "str", $aSearchArea, "Int", 5, "str", $redLines, "Int", $minLevel, "Int", $maxLevel)
		
		If @error = 0 And checkImglocError($res, "SearchMultipleTilesBetweenLevels", $directory) = False Then
			; Validate results using context
			Local $aValidatedResults = ValidateDetectionWithContext($res, $aBaseContext, $fConfidenceThreshold)
			If UBound($aValidatedResults) > 0 Then
				_ArrayConcatenate($aTotalResults, $aValidatedResults)
			EndIf
		EndIf
	Next
	
	; Fall back to full area search if needed
	If UBound($aTotalResults) = 0 Then
		SetDebugLog("ML prediction failed, falling back to full area search", $COLOR_WARNING)
		; Standard search implementation here...
	EndIf
	
	; Post-processing: Refine results using ML validation
	Local $aFinalResults = RefineMoveToResultsML($aTotalResults, $iBuildingType, $aBaseContext)
	
	Local $iTime = __TimerDiff($hTimer) * 0.001
	SetLog("ML-Enhanced detection completed in: " & Round($iTime, 2) & " seconds", $COLOR_SUCCESS)
	
	Return $aFinalResults
EndFunc   ;==>GetLocationBuildingML

; Analyze image quality metrics
Func AnalyzeImageQuality()
	Local $aQualityMetrics[4] ; [brightness, contrast, sharpness, noise]
	
	; Call DLL function to analyze image quality
	Local $aResult = DllCallMyBot("AnalyzeImageQuality", "handle", $g_hHBitmap2)
	If @error = 0 And IsArray($aResult) And UBound($aResult) >= 4 Then
		$aQualityMetrics[0] = Number($aResult[0]) ; Brightness (0-1)
		$aQualityMetrics[1] = Number($aResult[1]) ; Contrast (0-1)  
		$aQualityMetrics[2] = Number($aResult[2]) ; Sharpness (0-1)
		$aQualityMetrics[3] = Number($aResult[3]) ; Noise level (0-1)
	Else
		; Default values if analysis fails
		$aQualityMetrics[0] = 0.5
		$aQualityMetrics[1] = 0.5
		$aQualityMetrics[2] = 0.5
		$aQualityMetrics[3] = 0.3
	EndIf
	
	SetDebugLog("Image Quality - Brightness: " & $aQualityMetrics[0] & ", Contrast: " & $aQualityMetrics[1] & ", Sharpness: " & $aQualityMetrics[2] & ", Noise: " & $aQualityMetrics[3], $COLOR_DEBUG)
	Return $aQualityMetrics
EndFunc   ;==>AnalyzeImageQuality

; Predict likely building locations based on base patterns
Func PredictBuildingLocations($iBuildingType, $aBaseContext)
	Local $aPredictions[0]
	
	; Use pattern recognition to predict locations
	Switch $iBuildingType
		Case $eBldgTownHall
			; TH is usually in center or corner
			If $aBaseContext[0] = "war" Then ; War base
				_ArrayAdd($aPredictions, "440,350") ; Center
			Else ; Farming base
				_ArrayAdd($aPredictions, "700,200") ; Corner
				_ArrayAdd($aPredictions, "150,500") ; Corner
			EndIf
		Case $eBldgGoldMine, $eBldgElixirCollector
			; Collectors often on the edges
			_ArrayAdd($aPredictions, "200,300") ; Left side
			_ArrayAdd($aPredictions, "680,300") ; Right side
			_ArrayAdd($aPredictions, "440,180") ; Top
			_ArrayAdd($aPredictions, "440,520") ; Bottom
		Case $eBldgXBow, $eBldgInferno
			; Defenses usually inside walls
			_ArrayAdd($aPredictions, "400,320") ; Center-left
			_ArrayAdd($aPredictions, "480,320") ; Center-right
			_ArrayAdd($aPredictions, "440,280") ; Center-top
			_ArrayAdd($aPredictions, "440,360") ; Center-bottom
	EndSwitch
	
	Return $aPredictions
EndFunc   ;==>PredictBuildingLocations

; Performance-optimized detection with caching and parallel processing
Func GetLocationBuildingOptimized($iBuildingType, $iAttackingTH = $g_iMaxTHLevel, $bForceCaptureRegion = True)
	Local $hTimer = __TimerInit()
	
	; Check cache first
	Local $sCacheKey = CreateCacheKey($iBuildingType, $iAttackingTH, $g_hHBitmap2)
	Local $aCachedResult = GetCachedDetection($sCacheKey)
	If UBound($aCachedResult) > 0 Then
		SetDebugLog("Using cached detection result", $COLOR_SUCCESS)
		Return $aCachedResult
	EndIf
	
	; Parallel template matching for different building levels
	Local $aThreadResults[0]
	Local $maxLevel = _ObjGetValue($g_oBldgLevels, $iBuildingType)[$iAttackingTH - 1]
	
	; Split search by level ranges for parallel processing
	Local $iLevelChunk = Max(1, Int($maxLevel / 3)) ; Divide into 3 chunks
	Local $aLevelRanges[3][2] = [[0, $iLevelChunk], [$iLevelChunk + 1, $iLevelChunk * 2], [$iLevelChunk * 2 + 1, $maxLevel]]
	
	For $i = 0 To 2
		Local $iMinLvl = $aLevelRanges[$i][0]
		Local $iMaxLvl = $aLevelRanges[$i][1]
		
		; Async search for each level range
		Local $hThread = CreateDetectionThread($iBuildingType, $iMinLvl, $iMaxLvl, $directory, $fullCocAreas, $redLines)
		_ArrayAdd($aThreadResults, $hThread)
	Next
	
	; Collect results from all threads
	Local $aCombinedResults[0]
	For $i = 0 To UBound($aThreadResults) - 1
		Local $aThreadResult = WaitForDetectionThread($aThreadResults[$i])
		If UBound($aThreadResult) > 0 Then
			_ArrayConcatenate($aCombinedResults, $aThreadResult)
		EndIf
	Next
	
	; Cache the results for future use
	CacheDetectionResult($sCacheKey, $aCombinedResults)
	
	Local $iTime = __TimerDiff($hTimer) * 0.001
	SetDebugLog("Optimized detection completed in: " & Round($iTime, 2) & " seconds", $COLOR_SUCCESS)
	
	Return $aCombinedResults
EndFunc   ;==>GetLocationBuildingOptimized

; Create cache key for detection results
Func CreateCacheKey($iBuildingType, $iAttackingTH, $hBitmap)
	Local $sImageHash = GetImageHash($hBitmap) ; Simple hash of current image
	Return $iBuildingType & "_" & $iAttackingTH & "_" & $sImageHash
EndFunc   ;==>CreateCacheKey

; Simple image hashing for cache validation
Func GetImageHash($hBitmap)
	; Create a simple hash based on key pixels
	Local $aPixels[10]
	$aPixels[0] = _GetPixelColor(100, 100, False)
	$aPixels[1] = _GetPixelColor(200, 200, False)
	$aPixels[2] = _GetPixelColor(300, 300, False)
	$aPixels[3] = _GetPixelColor(400, 400, False)
	$aPixels[4] = _GetPixelColor(500, 500, False)
	$aPixels[5] = _GetPixelColor(600, 300, False)
	$aPixels[6] = _GetPixelColor(300, 600, False)
	$aPixels[7] = _GetPixelColor(150, 450, False)
	$aPixels[8] = _GetPixelColor(750, 150, False)
	$aPixels[9] = _GetPixelColor(440, 350, False)
	
	Local $sHash = ""
	For $i = 0 To UBound($aPixels) - 1
		$sHash &= StringMid($aPixels[$i], 3, 2) ; Take 2 hex digits from each pixel
	Next
	
	Return $sHash
EndFunc   ;==>GetImageHash


