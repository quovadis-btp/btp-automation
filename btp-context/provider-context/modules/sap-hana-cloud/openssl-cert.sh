#!/bin/bash

set -e -o pipefail 
#ISSUER=$(terraform output -json hc_credentials_x509 | jq -r '.uaa | {clientid, key, certificate, url: (.certurl+ "/oauth/token") }' ) 
ISSUER=$(jq -r '{clientid: "\(.clientid)", key: "\(.key)", certificate: "\(.certificate)", url: "\(.url)", location: "\(.location)" }' )
KEYSTORE=$(cat | openssl pkcs12 -export \
-in <(echo "$(jq  -r '. | .certificate' <<< $ISSUER )") \
-inkey <(echo "$(jq  -r '. | .key' <<< $ISSUER )") \
-passout pass:Password1 | base64) 
#echo $KEYSTORE 
#openssl pkcs12 -nokeys -info -in <(echo -n $KEYSTORE | base64 -d) -passin pass:Password1 
#jq -n --arg keystore "$KEYSTORE" '{"Name": "hc-x509.p12", "Type": "CERTIFICATE", "Content":$keystore}'
LOCATION=$(echo "$(jq  -r '. | .location' <<< $ISSUER )")
jq -n --arg location "$LOCATION" --arg keystore "$KEYSTORE" '{"Name": $location, "Type": "CERTIFICATE", "Content":$keystore}'
