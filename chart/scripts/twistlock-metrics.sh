#!/bin/bash
#######################################
# Creates a metrics users - script is a modified copy of the user creation script
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_METRICS_USER - username for metrics user
#   TWISTLOCK_METRICS_PASSWORD - password for metrics user
#######################################
# shellcheck disable=SC1091,SC2016

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Convert string to array
callapi "GET" "users"
existing_users="$RESP"

username=$TWISTLOCK_METRICS_USER
role="auditor"
authType="basic"
password=$TWISTLOCK_METRICS_PASSWORD

# Check if user already exists
existing_user=$(jq ".[] | select (.username == \"$username\")" < <(echo "$existing_users"))

if [ -z "$existing_user" ]; then
  echo -n "Creating"
  req="POST"
else
  echo -n "Ensuring"
  req="PUT"
fi
echo -n " default metrics service account user '$username' ... "

# Build JSON
args=("-c" "-n")
filter=("{}")
args+=("--arg" "username" "$username"); filter+=('| .username=$username');
args+=("--arg" "role" "$role"); filter+=('| .role=$role');
args+=("--arg" "authType" "$authType"); filter+=('| .authType=$authType');
if [ -n "$password" ]; then args+=("--arg" "password" "$password"); filter+=('| .password=$password'); fi
args+=("${filter[*]}")
DATA=$(jq "${args[@]}")

# Merge existing and new data
DATA=$(jq -c -s add < <(echo "$existing_user" "$DATA"))

# Add user
callapi "$req" "users" "$DATA"
logok
