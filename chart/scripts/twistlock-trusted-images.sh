#!/bin/bash
#######################################
# Adds default trusted image policy
# NOTE: Loading from exporter .json files is dangerous
# because it will override everything for the policy.
# Here we build the JSON with only the settings we want
# to control, then overlay it on the existing policies.
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_TRUSTED_IMAGE_REGISTRIES - list of registry wildcards to trust (i.e. registry1.dso.mil/ironbank/*)
#   TWISTLOCK_TRUSTED_IMAGE_NAME - the name to use for the trusted registry (i.e BigBang-Trusted)
#   TWISTLOCK_TRUSTED_IMAGE_EFFECT - the effect to apply for images outside of the trusted group (alert OR block)
#######################################
# shellcheck disable=SC1091,SC2016,SC2034

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Convert string to array
readarray -t TWISTLOCK_TRUSTED_IMAGE_REGISTRIES < <(echo "$TWISTLOCK_TRUSTED_IMAGE_REGISTRIES")

#######################################
# Retrieves existing trusted rules/groups
# Arguments (positional):
#   1) endpoint - the endpoint to query for existing rules/groups
# Returns:
#   rules - the JSON rules
#   groups - the JSON groups
#######################################
base_trusted_policy() {
  local endpoint="$1"

  # Get existing trust data
  callapi "GET" "$endpoint"

  # Find existing rules (this always exists, even as an empty default)
  rules=$(jq -c ".policy.rules" < <(echo "$RESP"))

  # Find existing groups (this may or may not exist)
  groups=$(jq -c ".groups" < <(echo "$RESP"))

  # If no groups exist, build an empty list for adding onto
  if [[ -z "$groups" || "$groups" == "null" ]]; then
    groups="[]"
  fi
}

#######################################
# Adds a trusted rule
# Arguments (positional):
#   1) name - the name of the rule/group
#   2) effect - the default effect to use for the new rule
# Returns:
#   rules - the JSON rule (updated with new rule)
#######################################
add_rule() {
  local name="$1"
  local group="$1"
  local effect="$2"

  # If existing rule, delete it (based off name)
  rules=$(echo "${rules}" | jq -c "del(.[] | select(.name==\"${name}\"))")

  # Add new/updated rules
  local args=("-c" "-n")
  args+=("--argjson" "new_rule" "{\"name\":\"${name}\",\"allowedGroups\":[\"${group}\"],\"collections\":[{\"name\":\"All\"}],\"effect\":\"${effect}\"}")
  local filter=('[$new_rule] +')
  filter+=(" $rules")
  args+=("${filter[*]}")
  rules=$(jq "${args[@]}")
}

#######################################
# Adds a trusted group
# Arguments (positional):
#   1) name - the group name to add
#   2) registries - the list of registry wildcards
# Returns:
#   groups - the JSON groups (updated with new group)
#######################################
add_group() {
  local name="$1"
  # Shift arguments to capture list of registries
  shift
  local registries=("$@")

  # If existing group, delete it (based off name)
  groups=$(echo "${groups}" | jq -c "del(.[] | select(._id==\"${name}\"))")

  # Add new/updated group
  local args=("-c" "-n"); local filter=("$groups")
  registry_list=""
  for registry in "${registries[@]}"; do
    if [[ "${registry_list}" == "" ]]; then
      registry_list="\"${registry}\""
    else
      registry_list="${registry_list}, \"${registry}\""
    fi
  done
  args+=("--argjson" "new_group" "{\"_id\":\"${name}\",\"images\":[${registry_list}]}")
  filter+=(' + [$new_group]')
  args+=("${filter[*]}")
  groups=$(jq "${args[@]}")
}

endpoint="trust/data"

echo -n "Configuring trusted image policy ... "

# Get current rules/groups
base_trusted_policy $endpoint

# Modify to add new rule/group
add_rule "${TWISTLOCK_TRUSTED_IMAGE_NAME}" "${TWISTLOCK_TRUSTED_IMAGE_EFFECT}"
add_group "${TWISTLOCK_TRUSTED_IMAGE_NAME}" "${TWISTLOCK_TRUSTED_IMAGE_REGISTRIES[@]}"

# Build updated policy
args=("-c" "-n")
filter=("{}")
args+=("--argjson" "rules" "$rules"); filter+=('| .policy.rules=$rules')
args+=("--arg" "id" "trust"); filter+=('| .policy._id=$id')
args+=("--arg" "enabled" true); filter+=('| .policy.enabled=($enabled | test("true"))')
args+=("--argjson" "groups" "$groups"); filter+=('| .groups=$groups')
args+=("${filter[*]}")
data=$(jq "${args[@]}")

# Submit trusted policy
callapi "PUT" "$endpoint" "$data"
logok
