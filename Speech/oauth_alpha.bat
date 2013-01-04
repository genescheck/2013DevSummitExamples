@echo off
REM This is for Speech Alpha access.
REM
REM Example BAT script in submit an OAuth request, using the contents of 
REM oauth_alpha.txt as the POST data. This is for Speech Alpha access.
REM
REM The curl executable will need to be installed somewhere in the PATH variable
REM or alternatively you can supply the absolute path below
REM
REM You will need to replace the CLIENT_ID and CLIENT_SECRET in the oauth.txt
REM file with your specific client_id and client_secret

curl --insecure --data @oauth_alpha.txt https://auth.tfoundry.com/oauth/token
