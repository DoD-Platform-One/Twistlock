#!/bin/bash
#######################################
# Adds additional groups
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_GROUPS - array of groups to add
#   - Newline separates one group from the next
#   - Space delimits fields
#   - Fields (in order) are "group role authType" where:
#     - group: desired group name
#     - role: role assigned to the group; out of the box roles and their associated display name:
#       - "admin" | Administrator
#       - "operator" | Operator
#       - "cloudAccountManager" | Cloud Account Manager
#       - "auditor" | Auditor
#       - "devSecOps" | DevSecOps User
#       - "vulnerabilityManager" | Vulnerability Manager
#       - "devOps" | DevOps User
#       - "defenderManager" | Defender Manager
#       - "user" | Access User
#       - "ci" | CI User
#     - authType: one of the following sso types:
#       - "ldapGroup"
#       - "samlGroup"
#       - "oauthGroup"
#       - "oidcGroup"
#       NOTE: authType must already be configured as an identity provider in Twistlock as
#             SSO groups are hidden until the associated authType is configured
#######################################
# shellcheck disable=SC1091,SC2016

set -e
#set -v
#set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Convert string to array
readarray -t TWISTLOCK_GROUPS < <(echo "$TWISTLOCK_GROUPS")

for TWISTLOCK_GROUPS in "${TWISTLOCK_GROUPS[@]}"; do
  # Split string into variables
  read -r groupName role authType < <(echo "$TWISTLOCK_GROUPS")

  echo -n "Creating group: $groupName | role: $role | authType: $authType..."

  # Build JSON
  args=("-c" "-n")
  filter=("{}")
  args+=("--arg" "groupName" "$groupName"); filter+=('| .groupName=$groupName');
  args+=("--arg" "role" "$role"); filter+=('| .role=$role');
  # could make this optional if we want to support configuring non-sso-able groups
  args+=("--arg" "authType" "$authType"); filter+=("| .$authType=true");
  args+=("${filter[*]}")
  DATA=$(jq "${args[@]}")

  # Add group
  callapi "POST" "groups" "$DATA"
  logok
done
