# This is for Speech Alpha.
#
# Example shell script to submit a Speech request, using the contents of the audio
# file given on the command line as the POST data. This is for Speech Alpha.
#
# The curl executable will need to be installed somewhere in the PATH variable
# or alternatively you can supply the absolute path below
#
# You will need to replace the ACCESS_TOKEN with the access_token you retrieve 
# from OAuth request
#
# Usage: speech_alpha.sh <filename>
#

if [ "$#" != "1" ]; then
    echo "Usage: $0 <filename>"
    exit
fi

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
  --header "Accept: application/json" \
  --header "Content-type: multipart/x-srgs-audio" \
  --header "Authorization: Bearer ACCESS_TOKEN" \
  --form "x-dictionary=@speech_alpha.pls;type=application/pls+xml" \
  --form "x-grammar=@speech_alpha.srgs;filename=prefix.srgs;type=application/srgs+xml" \
  --form "x-voice=@$FILE;type=$TYPE" \
  https://api.foundry.att.com/a1/speechalpha/inlinehints
