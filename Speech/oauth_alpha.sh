# This is for Speech Alpha access.
#
# Example shell script to submit an OAuth request, using the contents of 
# oauth_alpha.txt as the POST data. This is for Speech Alpha access.
#
# The curl executable will need to be installed somewhere in the PATH variable
# or alternatively you can supply the absolute path below
#
# You will need to replace the CLIENT_ID and CLIENT_SECRET in the oauth.txt
# file with your specific client_id and client_secret

curl --insecure --data @oauth_alpha.txt https://auth.tfoundry.com/oauth/token
