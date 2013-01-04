# Example shell script to submit an OAuth request, using the contents of oauth.txt
# as the POST data
#
# The curl executable will need to be installed somewhere in the PATH variable
# or alternatively you can supply the absolute path below
#
# You will need to replace the CLIENT_ID and CLIENT_SECRET in the oauth.txt
# file with your specific client_id and client_secret

curl --insecure --data @oauth.txt https://api.att.com/oauth/token
