@echo off
REM This is for Speech Alpha.
REM
REM Example BAT script to submit a Speech request, using the contents of the audio
REM file given on the command line as the POST data. This is for Speech Alpha.
REM
REM The curl executable will need to be installed somewhere in the PATH variable
REM or alternatively you can supply the absolute path below
REM
REM You will need to replace the ACCESS_TOKEN with the access_token you retrieve 
REM from OAuth request
REM
REM Usage: speech_alpha.bat <filename>
REM

set FILE=%1

if "%FILE%"=="" (
    echo "Usage: %0 <filename>"
    exit /b
)

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
  --header "Accept: application/json" ^
  --header "Content-type: multipart/x-srgs-audio" ^
  --header "Authorization: Bearer ACCESS_TOKEN" ^
  --form "x-dictionary=@speech_alpha.pls;type=application/pls+xml" ^
  --form "x-grammar=@speech_alpha.srgs;filename=prefix.srgs;type=application/srgs+xml" ^
  --form "x-voice=@%FILE%;type=%TYPE%" ^
  https://api.foundry.att.com/a1/speechalpha/inlinehints
