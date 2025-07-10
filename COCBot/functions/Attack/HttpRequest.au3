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
    Local $hOpen, $hConnect, $hRequest
    Local $sResponse = ""
    
    ; Parse URL
    Local $aUrl = StringRegExp($sUrl, "(?i)https?://([^/]+)(.*)", 3)
    If @error Or UBound($aUrl) < 2 Then
        SetLog("Invalid URL format: " & $sUrl, $COLOR_ERROR)
        Return ""
    EndIf
    
    Local $sServer = $aUrl[0]
    Local $sPath = $aUrl[1]
    If $sPath = "" Then $sPath = "/"
    
    Local $iPort = StringInStr($sUrl, "https://") = 1 ? 443 : 80
    
    ; Initialize WinHttp
    $hOpen = DllCall("winhttp.dll", "handle", "WinHttpOpen", _
        "wstr", "MyBot HTTP Client", _
        "dword", 1, _ ; WINHTTP_ACCESS_TYPE_DEFAULT_PROXY
        "ptr", 0, _
        "ptr", 0, _
        "dword", 0)
    
    If @error Or $hOpen[0] = 0 Then
        SetLog("Failed to initialize WinHttp", $COLOR_ERROR)
        Return ""
    EndIf
    $hOpen = $hOpen[0]
    
    ; Connect to server
    $hConnect = DllCall("winhttp.dll", "handle", "WinHttpConnect", _
        "handle", $hOpen, _
        "wstr", $sServer, _
        "word", $iPort, _
        "dword", 0)
    
    If @error Or $hConnect[0] = 0 Then
        SetLog("Failed to connect to server: " & $sServer, $COLOR_ERROR)
        DllCall("winhttp.dll", "bool", "WinHttpCloseHandle", "handle", $hOpen)
        Return ""
    EndIf
    $hConnect = $hConnect[0]
    
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
        SetLog("Failed to create HTTP request", $COLOR_ERROR)
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
        Local $tData = DllStructCreate("byte[" & StringLen($sData) & "]")
        DllStructSetData($tData, 1, StringToBinary($sData))
        $pData = DllStructGetPtr($tData)
        $iDataLen = DllStructGetSize($tData)
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
        SetLog("Failed to send HTTP request", $COLOR_ERROR)
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
        SetLog("Failed to receive HTTP response", $COLOR_ERROR)
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
    If $g_bDebugSetLog Then SetDebugLog("GenerateAIStrategy() called with mode: " & $iMatchMode & ", dropOrder: " & $iDropOrder & ", sides: " & $iNbSides, $COLOR_DEBUG)
    
    ; Prepare request data
    Local $sRequestData = '{'
    $sRequestData &= '"matchMode": ' & $iMatchMode & ','
    $sRequestData &= '"dropOrder": ' & $iDropOrder & ','
    $sRequestData &= '"nbSides": ' & $iNbSides & ','
    $sRequestData &= '"availableTroops": "' & $sAvailableTroops & '",'
    $sRequestData &= '"targetInfo": "' & $sTargetInfo & '"'
    $sRequestData &= '}'
    
    ; Prepare headers
    Local $aHeaders[2] = ["Content-Type: application/json", "Accept: application/json"]
    
    ; Make HTTP request to AI server
    Local $sResponse = HttpRequest("http://localhost:3000/api/generate-strategy", "POST", $sRequestData, $aHeaders)
    
    If $sResponse = "" Then
        SetLog("Failed to get AI strategy response, using fallback", $COLOR_ERROR)
        Return GetFallbackStrategy($iMatchMode, $iDropOrder, $iNbSides)
    EndIf
    
    If $g_bDebugSetLog Then SetDebugLog("AI Response: " & $sResponse, $COLOR_DEBUG)
    
    ; Parse JSON response
    Local $sStrategy = ParseAIStrategyResponse($sResponse)
    If $sStrategy = "" Then
        SetLog("Failed to parse AI strategy, using fallback", $COLOR_ERROR)
        Return GetFallbackStrategy($iMatchMode, $iDropOrder, $iNbSides)
    EndIf
    
    SetLog("AI Strategy generated successfully", $COLOR_SUCCESS)
    Return $sStrategy
EndFunc   ;==>GenerateAIStrategy

; Parse AI strategy response
Func ParseAIStrategyResponse($sResponse)
    ; Simple JSON parsing for the strategy array
    ; Look for "strategy" field in the response
    Local $iPos = StringInStr($sResponse, '"strategy"')
    If $iPos = 0 Then
        SetDebugLog("No strategy field found in response", $COLOR_ERROR)
        Return ""
    EndIf
    
    ; Find the array start
    Local $iArrayStart = StringInStr($sResponse, "[", 0, 1, $iPos)
    If $iArrayStart = 0 Then
        SetDebugLog("No array found in strategy response", $COLOR_ERROR)
        Return ""
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
        SetDebugLog("Could not find end of strategy array", $COLOR_ERROR)
        Return ""
    EndIf
    
    ; Extract the strategy array
    Local $sStrategyArray = StringMid($sResponse, $iArrayStart, $iArrayEnd - $iArrayStart + 1)
    
    ; Convert to AutoIt array format
    Return ConvertJSONToAutoItArray($sStrategyArray)
EndFunc   ;==>ParseAIStrategyResponse

; Convert JSON array to AutoIt array declaration
Func ConvertJSONToAutoItArray($sJSONArray)
    ; Remove the outer brackets
    $sJSONArray = StringTrimLeft($sJSONArray, 1)
    $sJSONArray = StringTrimRight($sJSONArray, 1)
    $sJSONArray = StringStripWS($sJSONArray, 3)
    
    If $sJSONArray = "" Then Return ""
    
    ; Split by inner arrays (each strategy entry)
    Local $aEntries = StringSplit($sJSONArray, "],", 1)
    Local $sAutoItArray = ""
    Local $iCount = 0
    
    For $i = 1 To $aEntries[0]
        Local $sEntry = $aEntries[$i]
        If $i < $aEntries[0] Then $sEntry &= "]" ; Add back the bracket if not the last entry
        
        ; Clean up the entry
        $sEntry = StringReplace($sEntry, "[", "")
        $sEntry = StringReplace($sEntry, "]", "")
        $sEntry = StringReplace($sEntry, """", "")
        $sEntry = StringStripWS($sEntry, 3)
        
        If $sEntry <> "" Then
            Local $aValues = StringSplit($sEntry, ",", 2)
            If UBound($aValues) >= 5 Then
                If $iCount > 0 Then $sAutoItArray &= " _" & @CRLF & "						, "
                $sAutoItArray &= "[" & StringStripWS($aValues[0], 3) & ", " & StringStripWS($aValues[1], 3) & ", " & StringStripWS($aValues[2], 3) & ", " & StringStripWS($aValues[3], 3) & ", " & StringStripWS($aValues[4], 3) & "]"
                $iCount += 1
            EndIf
        EndIf
    Next
    
    If $iCount = 0 Then Return ""
    
    ; Create the complete array declaration
    Local $sResult = "Local $listInfoDeploy[" & $iCount & "][5] = [" & $sAutoItArray & "]"
    
    Return $sResult
EndFunc   ;==>ConvertJSONToAutoItArray

; Fallback strategy when AI fails
Func GetFallbackStrategy($iMatchMode, $iDropOrder, $iNbSides)
    If $g_bDebugSetLog Then SetDebugLog("Using fallback strategy for mode: " & $iMatchMode, $COLOR_DEBUG)
    
    ; Return a basic strategy based on the mode
    Switch $iDropOrder
        Case 0
            Return "Local $listInfoDeploy[10][5] = [[$eGiant, " & $iNbSides & ", 1, 1, 2] _" & @CRLF & _
                   "						, [$eSGiant, " & $iNbSides & ", 1, 1, 2] _" & @CRLF & _
                   "						, [""CC"", 1, 1, 1, 1] _" & @CRLF & _
                   "						, [$eWall, " & $iNbSides & ", 1, 1, 1] _" & @CRLF & _
                   "						, [$eSWall, " & $iNbSides & ", 1, 1, 1] _" & @CRLF & _
                   "						, [$eBarb, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eSBarb, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eArch, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eSArch, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [""HEROES"", 1, 2, 1, 1]]"
        Case 1
            Return "Local $listInfoDeploy[10][5] = [[$eBarb, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eSBarb, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eArch, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eSArch, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eGobl, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eSGobl, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eMini, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [$eSMini, " & $iNbSides & ", 1, 1, 0] _" & @CRLF & _
                   "						, [""CC"", 1, 1, 1, 1] _" & @CRLF & _
                   "						, [""HEROES"", 1, 2, 1, 1]]"
        Case Else
            Return "Local $listInfoDeploy[10][5] = [[$eGiant, " & $iNbSides & ", 1, 1, 2] _" & @CRLF & _
                   "						, [$eSGiant, " & $iNbSides & ", 1, 1, 2] _" & @CRLF & _
                   "						, [""CC"", 1, 1, 1, 1] _" & @CRLF & _
                   "						, [$eBarb, " & $iNbSides & ", 1, 2, 0] _" & @CRLF & _
                   "						, [$eSBarb, " & $iNbSides & ", 1, 2, 0] _" & @CRLF & _
                   "						, [$eWall, " & $iNbSides & ", 1, 1, 1] _" & @CRLF & _
                   "						, [$eSWall, " & $iNbSides & ", 1, 1, 1] _" & @CRLF & _
                   "						, [$eArch, " & $iNbSides & ", 1, 2, 0] _" & @CRLF & _
                   "						, [$eSArch, " & $iNbSides & ", 1, 2, 0] _" & @CRLF & _
                   "						, [""HEROES"", 1, 2, 1, 1]]"
    EndSwitch
EndFunc   ;==>GetFallbackStrategy
