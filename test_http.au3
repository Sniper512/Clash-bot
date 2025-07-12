#include "COCBot\functions\Attack\HttpRequest.au3"

; Simple test script to verify HTTP functionality
ConsoleWrite("Testing HTTP Request functionality..." & @CRLF)

; Test the basic HTTP request function
Local $sResponse = HttpRequest("http://localhost:3000/api/health", "GET")
ConsoleWrite("Health check response: " & $sResponse & @CRLF)

; Test the AI strategy generation
Local $sAIResponse = GenerateAIStrategy(0, "LavaLoon", 4, "Barbarian,Archer,Giant", "Dead base")
ConsoleWrite("AI Strategy response: " & $sAIResponse & @CRLF)

ConsoleWrite("Test completed." & @CRLF)
