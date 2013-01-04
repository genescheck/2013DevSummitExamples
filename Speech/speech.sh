# Example shell script to submit a Speech request, using the contents of the audio
# file given on the command line as the POST data
#
# The curl executable will need to be installed somewhere in the PATH variable
# or alternatively you can supply the absolute path below
#
# You will need to replace the ACCESS_TOKEN with the access_token you retrieve 
# from OAuth request
#
# Usage: speech.sh <filename>
#

FILE=$1
EXT=${FILE#*.}
if [ "$EXT" = "wav" ]; then
    TYPE=audio/wav
fi

if [ "$EXT" = "amr" ]; then
    TYPE=audio/amr
fi
if [ "$EXT" = "spx" ]; then
    TYPE=audio/x-speex
fi

curl --insecure \
  --data-binary @$FILE \
  --header "X-SpeechContext: SMS" \
  --header "Accept: application/json" \
  --header "Content-type: $TYPE" \
  --header "Authorization: Bearer ACCESS_TOKEN" \
  https://api.att.com/rest/2/SpeechToText
