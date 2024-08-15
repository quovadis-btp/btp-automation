#!/bin/bash

set -e -o pipefail 
ISSUER=$(jq -r '{url: "\(.url)", username: "\(.username)", password: "\(.password)", globalaccount: "\(.globalaccount)" }' )
LOGIN=$(btp login \
--url $(jq  -r '. | .url' <<< $ISSUER ) \
--subdomain $(jq  -r '. | .globalaccount' <<< $ISSUER ) \
--user $(jq  -r '. | .username' <<< $ISSUER ) \
--password $(jq  -r '. | .password | tostring' <<< $ISSUER ))
QUOTA=$(btp assign accounts/entitlement --to-subaccount $(btp list accounts/subaccount | jq -r '.value[] | select(.displayName == "trial") | .guid ') --for-service kymaruntime --plan trial --amount 0)
jq -n --arg quota "$QUOTA" --arg issuer "$ISSUER" --arg login "$LOGIN"  '{"quota": $quota, "issuer": $issuer, "login": $login }'
