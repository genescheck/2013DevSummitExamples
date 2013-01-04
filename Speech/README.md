Speech
=======

AT&T DevSummit repository for AT&T Speech API sample apps.

In order to use the Speech API, you will need to request an Access Token if
you do not have one already. You can use the oauth* scripts below to obtain
The Access Token. You will need to substitute your client_id and client_secret
for the CLIENT_ID and CLIENT_SECRET in the oauth*.txt files.

You will need different Access Tokens for production and Alpha Speech requests.

Once you have an Access Token, replace the ACCESS_TOKEN in the speech scripts
with the actual Access Token value obtained from above.

The scripts use the freely avaible command line program curl, available here
http://curl.haxx.se/. The user can use any language or tool they want, but
the below scripts will give them an idea on how to construct the requests.

Examples scripts for access to production Speech API (https://api.att.com)
---------------------------------------------------------------------------
oauth.bat - Windows BAT file to send OAuth request
oauth.sh - Shell script to send OAuth request
oauth.txt - POST body for the OAuth request
speech.bat - Windows BAT file to send Speech request
speech.sh - Shell script to send Speech request
speech_ex.amr - example AMR audio file
speech_ex.wav - example WAV audio file

Examples scripts for access to Alpha Speech API (https://api.foundry.att.com)
-----------------------------------------------------------------------------
oauth_alpha.bat - Windows BAT file to send OAuth request
oauth_alpha.sh - Shell script to send OAuth request
oauth_alpha.txt - POST body for the OAuth request
speech_alpha.bat - Windows BAT file to send Speech request
speech_alpah.sh - Shell script to send Speech request
speech_alpha.pls - PLS for the Inline hints request for Alpha
speech_alpha.srgs - SRGS for the Inline Hints request for Alpha
speech_alpha.wav - example WAV audio file

