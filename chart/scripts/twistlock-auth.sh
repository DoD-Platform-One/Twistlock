#!/bin/bash
#######################################
# Authenticates with API to get bearer token
# This will create the user if this is an initial install
# Globals:
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_USERNAME - the username to use for logging in to the API
#   TWISTLOCK_PASSWORD - the password to use for logging in to the API
# Returns:
#   TOKEN - the authz token for API access
#######################################
# shellcheck disable=SC1091,SC2016

set -e
#set -v
#set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Cannot continue if credentials are not provided
if [ -z "$TWISTLOCK_USERNAME" ] || [ -z "$TWISTLOCK_PASSWORD" ]; then
  logerror1 "Cannot initialize Twistlock without credentials!"
fi

# Build credentials JSON
args=("-c" "-n")
args+=("--arg" "username" "$TWISTLOCK_USERNAME")
args+=("--arg" "password" "$TWISTLOCK_PASSWORD")
args+=('{} | .username = $username | .password = $password')
DATA=$(jq "${args[@]}")

echo -n "Checking if Twistlock has been initialized ... "
callapi "GET" "settings/initialized"
if [ "$(echo "$RESP" | jq -r .initialized)" == "true" ]; then
  logok
  echo "Skipping admin account creation."
else
  # Create initial user
  echo "Not initialized".
  echo -n "Adding initial Twistlock user named '$TWISTLOCK_USERNAME' ... "
  callapi "POST" "signup" "$DATA"
  logok
fi

# Authenticate
echo -n "Logging in as $TWISTLOCK_USERNAME ... "
callapi "POST" "authenticate" "$DATA" "true"
TOKEN=$(echo "$RESP" | jq -r .token)
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Denied."
  # Exit with 0 in case user hasn't configured credentials on upgrade
  logerror0 "Authentication failed.  Cannot configure Twistlock without valid credentials."
else
  logok
fi
