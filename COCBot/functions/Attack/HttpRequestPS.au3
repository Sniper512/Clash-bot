; Simple HTTP test using PowerShell from AutoIt
Func TestHTTPConnection()
    SetLog("Testing HTTP connection using PowerShell...", $COLOR_INFO)
    
    ; Create PowerShell command for HTTP request
    Local $sPSCommand = 'powershell.exe -Command "'
    $sPSCommand &= 'try {'
    $sPSCommand &= '$response = Invoke-RestMethod -Uri \"http://127.0.0.1:3000/api/health\" -Method GET;'
    $sPSCommand &= 'Write-Output $response'
    $sPSCommand &= '} catch {'
    $sPSCommand &= 'Write-Output \"ERROR: $($_.Exception.Message)\"'
    $sPSCommand &= '}'
    $sPSCommand &= '"'
    
    ; Execute the command
    Local $iPID = Run($sPSCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
    ProcessWaitClose($iPID)
    
    Local $sOutput = StdoutRead($iPID)
    SetLog("PowerShell HTTP test result: " & $sOutput, $COLOR_INFO)
    
    Return $sOutput
EndFunc

; HTTP Request using PowerShell
Func HttpRequestPS($sUrl, $sMethod = "GET", $sData = "", $aHeaders = 0)
    SetLog("HTTP REQUEST via PowerShell: " & $sUrl & " Method: " & $sMethod, $COLOR_DEBUG)
    
    ; Build PowerShell command
    Local $sPSCommand = 'powershell.exe -Command "'
    $sPSCommand &= 'try {'
    
    If $sMethod = "POST" Then
        $sPSCommand &= '$body = ' & "'" & $sData & "';"
        $sPSCommand &= '$response = Invoke-RestMethod -Uri \"' & $sUrl & '\" -Method POST -Body $body -ContentType \"application/json\";'
    Else
        $sPSCommand &= '$response = Invoke-RestMethod -Uri \"' & $sUrl & '\" -Method ' & $sMethod & ';'
    EndIf
    
    $sPSCommand &= 'Write-Output ($response | ConvertTo-Json -Compress)'
    $sPSCommand &= '} catch {'
    $sPSCommand &= 'Write-Output \"ERROR: $($_.Exception.Message)\"'
    $sPSCommand &= '}'
    $sPSCommand &= '"'
    
    SetLog("Executing PowerShell command...", $COLOR_DEBUG)
    
    ; Execute the command
    Local $iPID = Run($sPSCommand, "", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
    ProcessWaitClose($iPID)
    
    Local $sOutput = StdoutRead($iPID)
    SetLog("PowerShell response: " & StringLeft($sOutput, 200) & "...", $COLOR_DEBUG)
    
    Return $sOutput
EndFunc
