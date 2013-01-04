@echo off
REM Example BAT script to submit a Speech request, using the contents of the
REM audio file specified on the command line as the POST data
REM
REM The curl executable will need to be installed somewhere in the PATH variable
REM or alternatively you can supply the absolute path below
REM
REM You will need to replace the ACCESS_TOKEN with the access_token you retrieve 
REM from OAuth request
REM
REM Usage: speech.bat <filename>
REM

set EXT=%~x1

if "%EXT%"==".wav" (
    set TYPE=audio/wav
)
if "%EXT%"==".amr" (
    set TYPE=audio/amr
)
if "%EXT%"==".spx" (
    set TYPE=audio/x-speex
)

curl --insecure ^
  --data-binary @%1 ^
  --header "X-SpeechContext: SMS" ^
  --header "Accept: application/json" ^
  --header "Content-type: %TYPE%" ^
  --header "Authorization: Bearer ACCESS_TOKEN" ^
  https://api.att.com/rest/2/SpeechToText
