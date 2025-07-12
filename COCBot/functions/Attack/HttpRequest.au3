; #FUNCTION# ====================================================================================================================
; Name ..........: HttpRequest
; Description ...: HTTP Client functions for making requests to external APIs
; Syntax ........: HttpRequest($sUrl, $sMethod, $sData, $aHeaders)
; Parameters ....: $sUrl - The URL to make the request to
;                  $sMethod - The HTTP method (GET, POST, etc.)
;                  $sData - The request body data (for POST requests)
;                  $aHeaders - Array of headers
; Return values .: HTTP response text
; Author ........: Auto-generated

; PowerShell-based HTTP functions as fallback
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2025
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

#include-once

; HTTP Request function using WinHttp
Func HttpRequest($sUrl, $sMethod = "GET", $sData = "", $aHeaders = 0)
    ; Initialize color constants with safe fallbacks
    Local $iColorDebug = 0xFF00FF
    If IsDeclared("COLOR_DEBUG") Then $iColorDebug = $COLOR_DEBUG
    
    Local $iColorError = 0xFF0000
    If IsDeclared("COLOR_ERROR") Then $iColorError = $COLOR_ERROR
    
    Local $iColorInfo = 0x0000FF
    If IsDeclared("COLOR_INFO") Then $iColorInfo = $COLOR_INFO
    
    SetLog("HTTP REQUEST CALLED: " & $sUrl & " Method: " & $sMethod, $iColorDebug)
    Local $hOpen, $hConnect, $hRequest
    Local $sResponse = ""
    
    ; Parse URL
    Local $aUrl = StringRegExp($sUrl, "(?i)https?://([^/]+)(.*)", 3)
    If @error Or UBound($aUrl) < 2 Then
        SetLog("Invalid URL format: " & $sUrl, $iColorError)
        Return ""
    EndIf
    
    Local $sServerAndPort = $aUrl[0]
    Local $sPath = $aUrl[1]
    If $sPath = "" Then $sPath = "/"
    
    ; Extract server and port
    Local $sServer = $sServerAndPort
    Local $iPort = StringInStr($sUrl, "https://") = 1 ? 443 : 80
    
    ; Check if port is specified in the URL
    If StringInStr($sServerAndPort, ":") > 0 Then
        Local $aServerPort = StringSplit($sServerAndPort, ":", 2)
        If UBound($aServerPort) >= 2 Then
            $sServer = $aServerPort[0]
            $iPort = Int($aServerPort[1])
        EndIf
    EndIf
    
    SetLog("Connecting to server: " & $sServer & " port: " & $iPort, $iColorDebug)
    
    ; Initialize WinHttp
    SetLog("Initializing WinHttp...", $iColorDebug)
    $hOpen = DllCall("winhttp.dll", "handle", "WinHttpOpen", _
        "wstr", "MyBot HTTP Client", _
        "dword", 1, _ ; WINHTTP_ACCESS_TYPE_DEFAULT_PROXY
        "ptr", 0, _
        "ptr", 0, _
        "dword", 0)
    
    If @error Then
        SetLog("WinHttpOpen DLL call failed with error: " & @error, $iColorError)
        Return ""
    EndIf
    
    If $hOpen[0] = 0 Then
        SetLog("WinHttpOpen returned null handle", $iColorError)
        Return ""
    EndIf
    $hOpen = $hOpen[0]
    SetLog("WinHttp initialized successfully", $iColorDebug)
    
    ; Connect to server
    SetLog("Connecting to server: " & $sServer & " on port " & $iPort, $iColorDebug)
    $hConnect = DllCall("winhttp.dll", "handle", "WinHttpConnect", _
        "handle", $hOpen, _
        "wstr", $sServer, _
        "word", $iPort, _
        "dword", 0)
    
    If @error Then
        SetLog("WinHttpConnect DLL call failed with error: " & @error, $iColorError)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
        Return ""
    EndIf
    
    If $hConnect[0] = 0 Then
        SetLog("WinHttpConnect returned null handle for " & $sServer & ":" & $iPort, $iColorError)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
        Return ""
    EndIf
    $hConnect = $hConnect[0]
    SetLog("Connected to server successfully", $iColorDebug)
    
    ; Create request
    Local $dwFlags = StringInStr($sUrl, "https://") = 1 ? 0x00800000 : 0 ; WINHTTP_FLAG_SECURE
    $hRequest = DllCall("winhttp.dll", "handle", "WinHttpOpenRequest", _
        "handle", $hConnect, _
        "wstr", $sMethod, _
        "wstr", $sPath, _
        "ptr", 0, _
        "ptr", 0, _
        "ptr", 0, _
        "dword", $dwFlags)
    
    If @error Or $hRequest[0] = 0 Then
        SetLog("Failed to create HTTP request", $iColorError)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hConnect)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
        Return ""
    EndIf
    $hRequest = $hRequest[0]
    
    ; Add headers
    If IsArray($aHeaders) Then
        For $i = 0 To UBound($aHeaders) - 1
            DllCall("winhttp.dll", "bool", "WinHttpAddRequestHeaders", _
                "handle", $hRequest, _
                "wstr", $aHeaders[$i], _
                "dword", -1, _
                "dword", 0x80000000) ; WINHTTP_ADDREQ_FLAG_ADD
        Next
    EndIf
    
    ; Send request
    Local $pData = 0
    Local $iDataLen = 0
    If $sData <> "" Then
        SetLog("🔍 WinHttp: Preparing to send data: " & $sData, $iColorDebug)
        SetLog("🔍 WinHttp: Data length: " & StringLen($sData), $iColorDebug)
        Local $tData = DllStructCreate("byte[" & StringLen($sData) & "]")
        DllStructSetData($tData, 1, StringToBinary($sData))
        $pData = DllStructGetPtr($tData)
        $iDataLen = DllStructGetSize($tData)
        SetLog("🔍 WinHttp: Binary data size: " & $iDataLen, $iColorDebug)
    Else
        SetLog("🔍 WinHttp: No data to send (sData is empty)", $iColorError)
    EndIf
    
    Local $bResult = DllCall("winhttp.dll", "bool", "WinHttpSendRequest", _
        "handle", $hRequest, _
        "ptr", 0, _
        "dword", 0, _
        "ptr", $pData, _
        "dword", $iDataLen, _
        "dword", $iDataLen, _
        "dword_ptr", 0)
    
    If @error Or Not $bResult[0] Then
        SetLog("Failed to send HTTP request", $iColorError)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hRequest)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hConnect)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
        Return ""
    EndIf
    
    ; Receive response
    $bResult = DllCall("winhttp.dll", "bool", "WinHttpReceiveResponse", _
        "handle", $hRequest, _
        "ptr", 0)
    
    If @error Or Not $bResult[0] Then
        SetLog("Failed to receive HTTP response", $iColorError)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hRequest)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hConnect)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
        Return ""
    EndIf
    
    ; Read response data
    Local $iAvailable, $iRead
    Do
        $iAvailable = DllCall("winhttp.dll", "bool", "WinHttpQueryDataAvailable", _
            "handle", $hRequest, _
            "dword*", 0)
        
        If @error Or Not $iAvailable[0] Then ExitLoop
        
        $iAvailable = $iAvailable[2]
        If $iAvailable = 0 Then ExitLoop
        
        Local $tBuffer = DllStructCreate("byte[" & $iAvailable & "]")
        $iRead = DllCall("winhttp.dll", "bool", "WinHttpReadData", _
            "handle", $hRequest, _
            "ptr", DllStructGetPtr($tBuffer), _
            "dword", $iAvailable, _
            "dword*", 0)
        
        If @error Or Not $iRead[0] Then ExitLoop
        
        $iRead = $iRead[4]
        If $iRead > 0 Then
            $sResponse &= BinaryToString(DllStructGetData($tBuffer, 1))
        EndIf
    Until $iRead = 0
    
    ; Cleanup
    DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hRequest)
    DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hConnect)
    DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
    
    Return $sResponse
EndFunc   ;==>HttpRequest

; Generate AI Strategy function
Func GenerateAIStrategy($iMatchMode, $iDropOrder, $iNbSides, $sAvailableTroops = "", $sTargetInfo = "")
    ; Initialize color constants with safe fallbacks
    Local $iColorInfo = 0x0000FF
    If IsDeclared("COLOR_INFO") Then $iColorInfo = $COLOR_INFO
    
    Local $iColorDebug = 0xFF00FF
    If IsDeclared("COLOR_DEBUG") Then $iColorDebug = $COLOR_DEBUG
    
    Local $iColorError = 0xFF0000
    If IsDeclared("COLOR_ERROR") Then $iColorError = $COLOR_ERROR
    
    Local $iColorSuccess = 0x00FF00
    If IsDeclared("COLOR_SUCCESS") Then $iColorSuccess = $COLOR_SUCCESS
    
    SetLog("🤖 Attempting to generate AI strategy...", $iColorInfo)
    SetLog("📊 Parameters: Mode=" & $iMatchMode & ", DropOrder=" & $iDropOrder & ", Sides=" & $iNbSides, $iColorDebug)
    
    ; Debug each parameter
    SetLog("🔍 Debug - iMatchMode: " & $iMatchMode & " (type: " & VarGetType($iMatchMode) & ")", $iColorDebug)
    SetLog("🔍 Debug - iDropOrder: " & $iDropOrder & " (type: " & VarGetType($iDropOrder) & ")", $iColorDebug)
    SetLog("🔍 Debug - iNbSides: " & $iNbSides & " (type: " & VarGetType($iNbSides) & ")", $iColorDebug)
    SetLog("🔍 Debug - sAvailableTroops: " & $sAvailableTroops & " (type: " & VarGetType($sAvailableTroops) & ")", $iColorDebug)
    SetLog("🔍 Debug - sTargetInfo: " & $sTargetInfo & " (type: " & VarGetType($sTargetInfo) & ")", $iColorDebug)
    
    ; Prepare request data with safe string conversion
    Local $sRequestData = '{'
    $sRequestData &= '"matchMode": ' & Number($iMatchMode) & ','
    $sRequestData &= '"dropOrder": "' & String($iDropOrder) & '",'
    $sRequestData &= '"nbSides": ' & Number($iNbSides) & ','
    $sRequestData &= '"availableTroops": "' & String($sAvailableTroops) & '",'
    $sRequestData &= '"targetInfo": "' & String($sTargetInfo) & '"'
    $sRequestData &= '}'
    
    SetLog("📤 Request data prepared: " & $sRequestData, $iColorDebug)
    
    ; Prepare headers
    Local $aHeaders[3] = ["Content-Type: application/json", "Accept: application/json", "Content-Length: " & StringLen($sRequestData)]
    
    SetLog("🌐 Making HTTP request to server...", $iColorInfo)
    ; Try PowerShell approach first for POST requests with JSON data
    Local $sResponse = ""
    ; Always use POST method for AI strategy generation
    SetLog("🔄 Using PowerShell approach for POST request...", $iColorDebug)
    $sResponse = HttpRequestPS("http://127.0.0.1:3000/api/generate-strategy", "POST", $sRequestData)
    SetLog("🔍 PowerShell response status: " & ($sResponse = "" ? "EMPTY" : "GOT_DATA"), $iColorDebug)
    SetLog("🔍 PowerShell response length: " & StringLen($sResponse), $iColorDebug)
    
    ; If PowerShell fails, try WinHttp approach
    If $sResponse = "" Then
        SetLog("🔄 Trying WinHttp approach...", $iColorDebug)
        $sResponse = HttpRequest("http://127.0.0.1:3000/api/generate-strategy", "POST", $sRequestData, $aHeaders)
        SetLog("🔍 WinHttp response status: " & ($sResponse = "" ? "EMPTY" : "GOT_DATA"), $iColorDebug)
        SetLog("🔍 WinHttp response length: " & StringLen($sResponse), $iColorDebug)
    EndIf
    
    If $sResponse = "" Then
        SetLog("❌ Failed to get AI strategy response, server may be down", $iColorError)
        Return ""
    EndIf
    
    SetLog("✅ Received response from server: " & StringLeft($sResponse, 100) & "...", $iColorSuccess)
    If IsDeclared("g_bDebugSetLog") And $g_bDebugSetLog Then SetDebugLog("Full AI Response: " & $sResponse, $iColorDebug)
    
    SetLog("AI Strategy generated successfully", $iColorSuccess)
    Return $sResponse
EndFunc   ;==>GenerateAIStrategy

; Parse AI strategy response
Func ParseAIStrategyResponse($sResponse)
    ; Initialize color constants with safe fallbacks
    Local $iColorDebug = 0xFF00FF
    If IsDeclared("COLOR_DEBUG") Then $iColorDebug = $COLOR_DEBUG
    
    Local $iColorError = 0xFF0000
    If IsDeclared("COLOR_ERROR") Then $iColorError = $COLOR_ERROR
    
    Local $iColorInfo = 0x0000FF
    If IsDeclared("COLOR_INFO") Then $iColorInfo = $COLOR_INFO
    
    SetLog("Parsing AI strategy response...", $iColorDebug)
    SetLog("Raw response: " & StringLeft($sResponse, 200) & "...", $iColorDebug)
    
    ; The server now sends just the strategy array directly
    ; First, try to find the JSON array in the response
    Local $iArrayStart = StringInStr($sResponse, "[")
    If $iArrayStart = 0 Then
        SetLog("No array found in strategy response", $iColorError)
        Local $aEmpty[1][5] ; Return empty array
        SetLog("🔍 Returning empty array: UBound(aEmpty,1)=" & UBound($aEmpty,1) & ", UBound(aEmpty,2)=" & UBound($aEmpty,2), $iColorDebug)
        Return $aEmpty
    EndIf
    
    ; Find the matching closing bracket
    Local $iBracketCount = 0
    Local $iArrayEnd = 0
    For $i = $iArrayStart To StringLen($sResponse)
        Local $sChar = StringMid($sResponse, $i, 1)
        If $sChar = "[" Then
            $iBracketCount += 1
        ElseIf $sChar = "]" Then
            $iBracketCount -= 1
            If $iBracketCount = 0 Then
                $iArrayEnd = $i
                ExitLoop
            EndIf
        EndIf
    Next
    
    If $iArrayEnd = 0 Then
        SetLog("Could not find end of strategy array", $iColorError)
        Local $aEmpty[1][5] ; Return empty array
        SetLog("🔍 Returning empty array: UBound(aEmpty,1)=" & UBound($aEmpty,1) & ", UBound(aEmpty,2)=" & UBound($aEmpty,2), $iColorDebug)
        Return $aEmpty
    EndIf
    
    ; Extract the strategy array
    Local $sStrategyArray = StringMid($sResponse, $iArrayStart, $iArrayEnd - $iArrayStart + 1)
    SetLog("Extracted strategy array: " & $sStrategyArray, $iColorDebug)
    
    ; Convert to AutoIt array and return it
    Local $aResult = ConvertJSONToAutoItArray($sStrategyArray)
    
    ; DEBUG: Check dimensions of returned array
    SetLog("🔍 ParseAIStrategyResponse returning array: UBound(aResult,1)=" & UBound($aResult,1) & ", UBound(aResult,2)=" & UBound($aResult,2), $iColorDebug)
    If UBound($aResult,1) > 0 Then
        SetLog("🔍 First element structure: [0][0]=" & $aResult[0][0] & ", [0][1]=" & $aResult[0][1] & ", [0][2]=" & $aResult[0][2] & ", [0][3]=" & $aResult[0][3] & ", [0][4]=" & $aResult[0][4], $iColorDebug)
    EndIf
    
    Return $aResult
EndFunc   ;==>ParseAIStrategyResponse

; Convert JSON array to AutoIt 2D array
Func ConvertJSONToAutoItArray($sJSONArray)
    ; Initialize color constants with safe fallbacks
    Local $iColorDebug = 0xFF00FF
    If IsDeclared("COLOR_DEBUG") Then $iColorDebug = $COLOR_DEBUG
    
    Local $iColorError = 0xFF0000
    If IsDeclared("COLOR_ERROR") Then $iColorError = $COLOR_ERROR
    
    Local $iColorSuccess = 0x00FF00
    If IsDeclared("COLOR_SUCCESS") Then $iColorSuccess = $COLOR_SUCCESS
    
    SetLog("Converting JSON to AutoIt array: " & StringLeft($sJSONArray, 100) & "...", $iColorDebug)
    
    ; Remove outer brackets and clean up
    $sJSONArray = StringReplace($sJSONArray, "[", "", 1)  ; Remove first [
    $sJSONArray = StringRegExpReplace($sJSONArray, "\]$", "")  ; Remove last ]
    $sJSONArray = StringStripWS($sJSONArray, 3)
    
    If $sJSONArray = "" Then 
        SetLog("Empty JSON array after cleanup", $iColorError)
        Local $aEmpty[1][5]
        SetLog("🔍 ConvertJSONToAutoItArray returning empty array: UBound(aEmpty,1)=" & UBound($aEmpty,1) & ", UBound(aEmpty,2)=" & UBound($aEmpty,2), $iColorDebug)
        Return $aEmpty
    EndIf
    
    SetLog("Cleaned JSON: " & $sJSONArray, $iColorDebug)
    
    ; Split by ],[  to get individual strategy entries
    Local $aRawEntries = StringSplit($sJSONArray, "],[", 1)
    Local $iEntryCount = $aRawEntries[0]
    
    SetLog("Found " & $iEntryCount & " raw entries", $iColorDebug)
    
    If $iEntryCount = 0 Then
        SetLog("No entries found in JSON", $iColorError)
        Local $aEmpty[1][5]
        SetLog("🔍 ConvertJSONToAutoItArray returning empty array (no entries): UBound(aEmpty,1)=" & UBound($aEmpty,1) & ", UBound(aEmpty,2)=" & UBound($aEmpty,2), $iColorDebug)
        Return $aEmpty
    EndIf
    
    ; Create result array
    Local $aResult[$iEntryCount][5]
    SetLog("🔍 Created result array: UBound(aResult,1)=" & UBound($aResult,1) & ", UBound(aResult,2)=" & UBound($aResult,2), $iColorDebug)
    
    ; Process each entry
    For $i = 1 To $iEntryCount
        Local $sEntry = $aRawEntries[$i]
        
        ; Clean up the entry (remove remaining brackets and quotes)
        $sEntry = StringReplace($sEntry, "[", "")
        $sEntry = StringReplace($sEntry, "]", "")
        $sEntry = StringStripWS($sEntry, 3)
        
        SetLog("Processing entry " & $i & ": " & $sEntry, $iColorDebug)
        
        ; Split by comma to get individual values
        Local $aValues = StringSplit($sEntry, ",", 2)  ; StringSplit with flag 2 returns 0-based array
        
        If UBound($aValues) >= 5 Then
            ; Clean and assign values - convert troop name to numeric constant
            Local $sTroopName = StringReplace(StringStripWS($aValues[0], 3), '"', '')  ; Remove quotes from troop name
            
            ; SAFE ARRAY ACCESS - Check bounds before assignment
            If $i-1 >= 0 And $i-1 < UBound($aResult, 1) Then
                $aResult[$i-1][0] = _ConvertTroopNameToConstant($sTroopName)
                $aResult[$i-1][1] = Int(StringStripWS($aValues[1], 3))
                $aResult[$i-1][2] = Int(StringStripWS($aValues[2], 3))
                $aResult[$i-1][3] = Int(StringStripWS($aValues[3], 3))
                $aResult[$i-1][4] = Int(StringStripWS($aValues[4], 3))
                
                SetLog("Entry " & $i & " parsed: " & $aResult[$i-1][0] & "," & $aResult[$i-1][1] & "," & $aResult[$i-1][2] & "," & $aResult[$i-1][3] & "," & $aResult[$i-1][4], $iColorDebug)
            Else
                SetLog("ERROR: Array bounds exceeded for entry " & $i & ", skipping", $iColorError)
            EndIf
        Else
            SetLog("Entry " & $i & " has insufficient values: " & UBound($aValues), $iColorError)
            ; Fill with safe defaults - SAFE ARRAY ACCESS
            If $i-1 >= 0 And $i-1 < UBound($aResult, 1) Then
                Local $eBarbDefault = 0
                If IsDeclared("eBarb") Then $eBarbDefault = $eBarb
                $aResult[$i-1][0] = $eBarbDefault
                $aResult[$i-1][1] = 1
                $aResult[$i-1][2] = 1
                $aResult[$i-1][3] = 1
                $aResult[$i-1][4] = 0
            Else
                SetLog("ERROR: Array bounds exceeded for default fill " & $i & ", skipping", $iColorError)
            EndIf
        EndIf
    Next
    
    SetLog("✅ Successfully converted JSON to " & $iEntryCount & "x5 AutoIt array", $iColorSuccess)
    SetLog("🔍 Final array dimensions: UBound(aResult,1)=" & UBound($aResult,1) & ", UBound(aResult,2)=" & UBound($aResult,2), $iColorDebug)
    
    ; Additional validation - check if array is properly 2D
    If UBound($aResult, 0) <> 2 Then
        SetLog("⚠️ WARNING: Result array is not 2D! Dimensions=" & UBound($aResult, 0), $iColorError)
    EndIf
    
    Return $aResult
EndFunc   ;==>ConvertJSONToAutoItArray

; PowerShell-based HTTP fallback functions
; HTTP Request using PowerShell as fallback
Func HttpRequestPS($sUrl, $sMethod = "GET", $sData = "", $aHeaders = 0)
    ; Initialize color constants with safe fallbacks
    Local $iColorDebug = 0xFF00FF
    If IsDeclared("COLOR_DEBUG") Then $iColorDebug = $COLOR_DEBUG
    
    Local $iColorError = 0xFF0000
    If IsDeclared("COLOR_ERROR") Then $iColorError = $COLOR_ERROR
    
    Local $iColorSuccess = 0x00FF00
    If IsDeclared("COLOR_SUCCESS") Then $iColorSuccess = $COLOR_SUCCESS
    
    SetLog("HTTP REQUEST via PowerShell: " & $sUrl & " Method: " & $sMethod, $iColorDebug)
    SetLog("🔍 PowerShell input data: " & $sData, $iColorDebug)
    SetLog("🔍 PowerShell input data length: " & StringLen($sData), $iColorDebug)
    
    ; Build PowerShell command
    Local $sPSCommand = 'powershell.exe -Command "'
    $sPSCommand &= 'try {'
    
    If $sMethod = "POST" Then
        ; Escape quotes in JSON data
        Local $sEscapedData = StringReplace($sData, '"', '""')
        SetLog("🔍 PowerShell escaped data: " & $sEscapedData, $iColorDebug)
        $sPSCommand &= '$body = ' & "'" & $sEscapedData & "';"
        $sPSCommand &= '$response = Invoke-RestMethod -Uri ""' & $sUrl & '"" -Method POST -Body $body -ContentType ""application/json"";'
    Else
        $sPSCommand &= '$response = Invoke-RestMethod -Uri ""' & $sUrl & '"" -Method ' & $sMethod & ';'
    EndIf
    
    $sPSCommand &= 'if ($response -is [array]) {'
    $sPSCommand &= '    Write-Output ($response | ConvertTo-Json -Compress -Depth 10)'
    $sPSCommand &= '} else {'
    $sPSCommand &= '    Write-Output ($response | ConvertTo-Json -Compress)'
    $sPSCommand &= '}'
    $sPSCommand &= '} catch {'
    $sPSCommand &= 'Write-Output ""ERROR: $($_.Exception.Message)""'
    $sPSCommand &= '}'
    $sPSCommand &= '"'
    
    SetLog("🔍 PowerShell command built: " & StringLeft($sPSCommand, 300) & "...", $iColorDebug)
    SetLog("Executing PowerShell HTTP request...", $iColorDebug)
    
    ; Execute the command and capture output
    Local $iPID = Run($sPSCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
    ProcessWaitClose($iPID, 10) ; 10 second timeout
    
    Local $sOutput = StdoutRead($iPID)
    Local $sError = StderrRead($iPID)
    
    If $sError <> "" Then
        SetLog("PowerShell stderr: " & $sError, $iColorError)
    EndIf
    
    If StringInStr($sOutput, "ERROR:") = 1 Then
        SetLog("PowerShell request failed: " & $sOutput, $iColorError)
        Return ""
    EndIf
    
    SetLog("PowerShell response received: " & StringLeft($sOutput, 200) & "...", $iColorSuccess)
    Return $sOutput
EndFunc   ;==>HttpRequestPS

; Convert troop name string constants to numeric constants
Func _ConvertTroopNameToConstant($sTroopName)
    ; Initialize color constants with safe fallbacks
    Local $iColorDebug = 0xFF00FF
    If IsDeclared("COLOR_DEBUG") Then $iColorDebug = $COLOR_DEBUG
    
    Local $iColorError = 0xFF0000
    If IsDeclared("COLOR_ERROR") Then $iColorError = $COLOR_ERROR
    
    SetLog("Converting troop name: " & $sTroopName, $iColorDebug)
    
    ; Handle special cases first
    If $sTroopName = "CC" Or $sTroopName = "HEROES" Then
        SetLog("Special troop: " & $sTroopName & " -> keeping as string", $iColorDebug)
        Return $sTroopName
    EndIf
    
    ; Convert string constants to numeric values
    Switch $sTroopName
        Case "$eBarb"
            If IsDeclared("eBarb") Then Return $eBarb
            Return 0
        Case "$eArch"
            If IsDeclared("eArch") Then Return $eArch
            Return 1
        Case "$eGiant"
            If IsDeclared("eGiant") Then Return $eGiant
            Return 2
        Case "$eGobl"
            If IsDeclared("eGobl") Then Return $eGobl
            Return 3
        Case "$eWiza"
            If IsDeclared("eWiza") Then Return $eWiza
            Return 4
        Case "$eBall"
            If IsDeclared("eBall") Then Return $eBall
            Return 5
        Case "$eWall"
            If IsDeclared("eWall") Then Return $eWall
            Return 6
        Case "$eLoon"
            If IsDeclared("eLoon") Then Return $eLoon
            Return 7
        Case "$eDrag"
            If IsDeclared("eDrag") Then Return $eDrag
            Return 8
        Case "$ePekk"
            If IsDeclared("ePekk") Then Return $ePekk
            Return 9
        Case "$eBabyD"
            If IsDeclared("eBabyD") Then Return $eBabyD
            Return 10
        Case "$eMine"
            If IsDeclared("eMine") Then Return $eMine
            Return 11
        Case "$eEDrag"
            If IsDeclared("eEDrag") Then Return $eEDrag
            Return 12
        Case "$eYeti"
            If IsDeclared("eYeti") Then Return $eYeti
            Return 13
        Case "$eDragR"
            If IsDeclared("eDragR") Then Return $eDragR
            Return 14
        Case "$eElem"
            If IsDeclared("eElem") Then Return $eElem
            Return 15
        Case "$eHeal"
            If IsDeclared("eHeal") Then Return $eHeal
            Return 16
        Case "$eLava"
            If IsDeclared("eLava") Then Return $eLava
            Return 17
        Case "$eBowl"
            If IsDeclared("eBowl") Then Return $eBowl
            Return 18
        Case "$eIceG"
            If IsDeclared("eIceG") Then Return $eIceG
            Return 19
        Case "$eHunt"
            If IsDeclared("eHunt") Then Return $eHunt
            Return 20
        Case "$eAppW"
            If IsDeclared("eAppW") Then Return $eAppW
            Return 21
        Case "$eDruid"
            If IsDeclared("eDruid") Then Return $eDruid
            Return 22
        Case "$eFurn"
            If IsDeclared("eFurn") Then Return $eFurn
            Return 23
        Case Else
            SetLog("Unknown troop name: " & $sTroopName & " -> using default", $iColorError)
            If IsDeclared("eBarb") Then Return $eBarb
            Return 0
    EndSwitch
EndFunc   ;==>_ConvertTroopNameToConstant
