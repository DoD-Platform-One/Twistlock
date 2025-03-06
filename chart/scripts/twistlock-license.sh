#!/bin/bash
#######################################
# Installs and validates Twistlock license
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_LICENSE (optional) - the Twistlock license key
#######################################
# shellcheck disable=SC1091

set -e
#set -v
#set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Apply License
if [ -z "$TWISTLOCK_LICENSE" ]; then
  echo "Twistlock license not supplied.  Skipping license update."
else
  LICENSE="{\"key\":\"$TWISTLOCK_LICENSE\"}"
  echo -n "Adding Twistlock license ... "
  callapi "POST" "settings/license" "$LICENSE"
  logok
fi

# Validate license
NOW=$(date -Isec)
echo -n "Checking Twistlock license validity ... "
callapi "GET" "settings/license" "true"
EXPIRE=$(echo "$RESP" | jq -r .expiration_date)
if [ -z "$EXPIRE" ] || [ "$EXPIRE" == "null" ]; then
  echo "Not found."
  # Don't exit with error on install where configuration isn't setup yet
  logerror0 "No license installed.  License must be configured (manually or through values) to configure Twistlock."
elif [[ "$EXPIRE" > "$NOW" ]]; then
  logok "(Expiration: $EXPIRE)"
else
  echo "Expired."
  logerror1 "License expired on $EXPIRE.  License must be valid to configure Twistlock."
fi
