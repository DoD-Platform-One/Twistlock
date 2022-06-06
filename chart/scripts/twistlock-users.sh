#!/bin/bash
#######################################
# Adds additional users
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_USERS - array of users to add
#   - Newline separates one user from the next
#   - Space delimits fields
#   - Fields (in order) are "user role authtype password"
#   TWISTLOCK_USERS_UPDATE - boolean to toggle updating user if it already exists
#######################################
# shellcheck disable=SC1091,SC2016

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Convert string to array
readarray -t TWISTLOCK_USERS < <(echo "$TWISTLOCK_USERS")

callapi "GET" "users"
existing_users="$RESP"

for TWISTLOCK_USER in "${TWISTLOCK_USERS[@]}"; do
  # Split string into variables
  read -r username role authType password < <(echo "$TWISTLOCK_USER")

  # Check if user already exists
  existing_user=$(jq ".[] | select (.username == \"$username\")" < <(echo "$existing_users"))

  if [ -z "$existing_user" ] || [ "$TWISTLOCK_USERS_UPDATE" == "true" ]; then
    if [ -z "$existing_user" ]; then
      echo -n "Adding"
      req="POST"
    else
      echo -n "Updating"
      req="PUT"
    fi
    echo -n " user '$username' (Role: $role, Auth: $authType) ... "

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
  else
    echo "User '$username' (Role: $role, Auth: $authType) already exists and update users is 'false'.  Skipping."
  fi
done