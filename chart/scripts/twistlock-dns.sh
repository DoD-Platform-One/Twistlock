#!/bin/bash
#######################################
# Check the current DNS SANs listed, and add any if needed
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the internal (http) Twistlock endpoint
#   TWISTLOCK_ISTIO_URL - the external (https) Istio virtual service Twistlock endpoint
#######################################
# shellcheck disable=SC1091

set -e
#set -v
#set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# get the DNS SANs
GETDNS="$(curl -L -X GET "http://$TWISTLOCK_URL/api/v1/settings/certs" \
-H 'Accept: application/json' -H "Authorization: Bearer $TOKEN")"

# Check if the value is in the consoleSAN array
if ! echo "$GETDNS" | jq -e --arg value "$TWISTLOCK_ISTIO_URL" '.consoleSAN | index($value)' > /dev/null; then
    # If the value is not in the array, add it and remove specified keys
    NEWDNS=$(echo "$GETDNS" | jq --arg value "$TWISTLOCK_ISTIO_URL" '
        .consoleSAN += [$value] |
        del(.caExpiration, .defenderOldCAExpiration)
    ')

    # POST the DNS SANs
    curl -L -X POST "http://$TWISTLOCK_URL/api/v1/settings/certs" \
    -H 'Content-Type: application/json' \
    --data-raw "$NEWDNS" \
    -H "Authorization: Bearer $TOKEN"
fi
