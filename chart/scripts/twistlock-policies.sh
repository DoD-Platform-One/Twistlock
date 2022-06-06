#!/bin/bash
#######################################
# Adds default defender policy rules
# NOTE: Loading from exporter .json files is dangerous
# because it will override everything for the policy.
# Here we build the JSON with only the settings we want
# to control, then overlay it on the existing policies.
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_POLICY_COMPLIANCE_ALERT_THRESHOLD
#   TWISTLOCK_POLICY_COMPLIANCE_ENABLED
#   TWISTLOCK_POLICY_COMPLIANCE_TEMPLATES
#   TWISTLOCK_POLICY_ENABLED
#   TWISTLOCK_POLICY_NAME
#   TWISTLOCK_POLICY_RUNTIME_ENABLED
#   TWISTLOCK_POLICY_VULNERABILITIES_ALERT_THRESHOLD
#   TWISTLOCK_POLICY_VULNERABILITIES_ENABLED
#######################################
# shellcheck disable=SC1091,SC2016,SC2034

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

#######################################
# Retrieves an existing rule or default rule to update
# Arguments (positional):
#   1) name - the name of the rule to find
#   2) endpoint - the endpoint to query for existing rules
# Returns:
#   rule - the JSON rule
#######################################
base_rule() {
  local name=$1
  local endpoint=$2

  # Get existing policy
  callapi "GET" "$endpoint"

  # Find existing rule
  rule=$(jq -c ".rules[] | select(.name == \"$name\")" < <(echo "$RESP"))

  # If existing rule is not found, build default using jq
  if [ -z "$rule" ]; then
    local args=("-c" "-n"); local filter=('{}')
    args+=("--arg" "name" "$name"); filter+=('| .name=$name')
    # Collections default to All since that is guaranteed to be there
    args+=("--argjson" "collections" '[{"name":"All"}]'); filter+=('| .collections=$collections')
    # Various alerting effects must be set.  API is tolerant enough to ignore settins that don't apply.
    args+=("--argjson" "processes" '{"effect":"alert"}'); filter+=('| .processes=$processes')
    args+=("--argjson" "network" '{"effect":"alert","denyListEffect":"alert","customFeed":"alert","intelligenceFeed":"alert"}'); filter+=('| .network=$network')
    args+=("--argjson" "dns" '{"effect":"alert","denyListEffect":"alert","intelligenceFeed":"alert"}'); filter+=('| .dns=$dns')
    args+=("--argjson" "filesystem" '{"effect":"alert"}'); filter+=('| .filesystem=$filesystem')
    args+=("--argjson" "antiMalware" '{"deniedProcesses":{"effect":"alert"},"cryptoMiner":"alert","serviceUnknownOriginBinary":"alert","userUnknownOriginBinary":"alert","encryptedBinaries":"alert","suspiciousELFHeaders":"alert","tempFSProc":"alert","reverseShell":"alert","webShell":"alert","executionFlowHijack":"alert","customFeed":"alert","intelligenceFeed":"alert","wildFireAnalysis":"alert"}'); filter+=('| .antiMalware=$antiMalware')
    args+=("--arg" "wildfire" "alert"); filter+=('| .wildFireAnalysis=$wildfire')
    args+=("${filter[*]}")
    rule=$(jq "${args[@]}")
  fi
}

#######################################
# Creates a vulnerability rule in JSON based on the alert threshold
# Arguments (positional):
#   1) baserule - the base rule to overlay changes onto
#   2) threshold - the min. threshold to alert. Valid values are "low", "medium", "high", or "critical"
#   Note: Invalid threshold values will trigger a program exit
# Returns:
#   rule - the JSON rule
#######################################
vulnerability_threshold_rule() {
  local baserule=$1
  local threshold=$2
  local args=("-c" "-n")
  local filter=("$baserule")
  args+=("--argjson" "threshold")
  if [ "${threshold,,}" == "low" ]; then
    args+=("1")
  elif [ "${threshold,,}" == "medium" ]; then
    args+=("4")
  elif [ "${threshold,,}" == "high" ]; then
    args+=("7")
  elif [ "${threshold,,}" == "critical" ]; then
    args+=("9")
  else
    logerror1 "'$threshold' is not a valid value for alert threshold."
  fi
  filter+=('| .alertThreshold.value=$threshold')
  args+=("--argjson" "fixed" "true"); filter+=('| .onlyFixed=$fixed')
  args+=("[${filter[*]}]")
  rule=$(jq "${args[@]}")
}

#######################################
# Creates a compliance rule in JSON based on matching a template
# Arguments (positional):
#   1) baserule - the base rule to overlay changes onto
#   2) template - name of the template to match
#   3) types - comma separated list of types to match
#   4) allvulns - list of all vulnerabilities that can be alerted on
# Returns:
#   rule - the JSON rule
#######################################
compliance_template_rule() {
  local baserule=$1
  local template=$2
  local types=$3
  local allvulns=$4
  local ids=()

  # Retrieve list of IDs that are included in the template
  # local ids=($(jq ".complianceVulnerabilities[] | select(.templates[]? | contains(\"$template\")) | select(.type == ($types)) | .id" < <(echo $allvulns)))
  mapfile -t ids < <(jq ".complianceVulnerabilities[] | select(.templates[]? | contains(\"$template\")) | select(.type == ($types)) | .id" < <(echo "$allvulns"))

  # Build compliance rule with ids
  compliance_rule "$baserule" "${ids[@]}"
}

#######################################
# Creates a compliance rule in JSON based on the alert threshold
# Arguments (positional):
#   1) baserule - the base rule to overlay changes onto
#   2) threshold - the min. threshold to alert. Valid values are "low", "medium", "high", or "critical"
#   Note: Invalid threshold values will trigger a program exit
#   3) types - comma separated list of types to match
#   4) allvulns - list of all vulnerabilities that can be alerted on
# Returns:
#   rule - the JSON rule
#######################################
compliance_threshold_rule() {
  local baserule=$1
  local threshold=$2
  local types=$3
  local allvulns=$4
  local ids=()

  # Threshold criteria
  if [ "${threshold,,}" == "low" ]; then
    thresholds='"low", "medium", "high", "critical"'
  elif [ "${threshold,,}" == "medium" ]; then
    thresholds='"medium", "high", "critical"'
  elif [ "${threshold,,}" == "high" ]; then
    thresholds='"high", "critical"'
  elif [ "${threshold,,}" == "critical" ]; then
    thresholds='"critical"'
  else
    logerror1 "'$threshold' is not a valid value for alert threshold."
  fi

  # Retrieve list of IDs that are >= threshold
  # local ids=($(jq ".complianceVulnerabilities[] | select(.severity == ($thresholds)) | select(.type == ($types)) | .id" < <(echo $allvulns)))
  mapfile -t ids < <(jq ".complianceVulnerabilities[] | select(.severity == ($thresholds)) | select(.type == ($types)) | .id" < <(echo "$allvulns"))

  # Build compliance rule with ids
  compliance_rule "$baserule" "${ids[@]}"
}

#######################################
# Creates a compliance rule in JSON
# Arguments (positional):
#   1) baserule - the base rule to overlay changes onto
#   2) ids - array of ids to add to the compliance rule
# Returns:
#   rule - the JSON rule
#######################################
compliance_rule() {
  local baserule=$1
  shift
  local ids=("$@")
  unset rule

  # Only create rule if we have IDs
  if [ "${#ids[@]}" != "0" ]; then

    # Build array of vulnerabilities
    local overlay="{}"
    for id in "${ids[@]}"; do
      local args=("-c" "-n")
      local filter=("$overlay")
      args+=("--argjson" "id" "$id"); filter+=('| .condition.vulnerabilities[.condition.vulnerabilities | length] |= . + {"id":$id}')
      args+=("${filter[*]}")
      overlay=$(jq "${args[@]}")
    done

    # Arrays of maps require special merging since a unique key must be identified for matching duplicates
    # Merge vulnerabilities arrays based on ID, favoring overlay
    args=('-c' '-s' '[[.[].condition.vulnerabilities] | add | group_by(.id)[] | add]')
    local vulns; vulns=$(jq "${args[@]}" < <(echo "$baserule" "$overlay"))
    args=('-c' '-n' "--argjson" "vulns" "$vulns" "[$baserule | .condition.vulnerabilities=\$vulns]")
    rule=$(jq "${args[@]}")
  fi
}


#######################################
# Creates a runtime rule in JSON
# Arguments (positional):
#   1) baserule - the base rule to overlay changes onto
#   2) threshold - the min. threshold to alert. Valid values are "low", "medium", "high", or "critical"
#   Note: Invalid threshold values will trigger a program exit
# Returns:
#   rule - the JSON rule
#######################################
runtime_rule() {
  local baserule=$1
  local overlay=$2

  # Arrays of maps require special merging since a unique key must be identified for matching duplicates
  # Merge custom rules arrays based on ID, favoring overlay
  if [[ "$baserule $overlay" =~ "customRules" ]]; then
    local customRules; customRules=$(jq -c -s '[[.[].customRules] | add | group_by(._id)[] | add]' < <(echo "$baserule" "$overlay"))
    baserule=$(jq -c -n --argjson "customRules" "$customRules" "$baserule | .customRules=\$customRules")
    overlay=$(jq -c -n --argjson "customRules" "[]" "$overlay | .customRules=\$customRules")
  fi

  # Merge log inspection rules arrays based on path, favoring overlay
  if [[ "$baserule $overlay" =~ "logInspectionRules" ]]; then
    local logInspectionRules; logInspectionRules=$(jq -c -s '[[.[].logInspectionRules] | add | group_by(.path)[] | add]' < <(echo "$baserule" "$overlay"))
    baserule=$(jq -c -n --argjson "logInspectionRules" "$logInspectionRules" "$baserule | .logInspectionRules=\$logInspectionRules")
    overlay=$(jq -c -n --argjson "logInspectionRules" "[]" "$overlay | .logInspectionRules=\$logInspectionRules")
  fi

  # Merge all fields
  merge_json "$baserule" "$overlay"

  # Each custom rule requires default keys for "effect" and "action".  Add them if needed
  if [[ "$json" =~ "customRules" ]]; then
    json=$(jq -c '.customRules |= map( . + if has("action") then null else {"action": "incident"} end)' < <(echo "$json"))
    json=$(jq -c '.customRules |= map( . + if has("effect") then null else {"effect": "alert"} end)' < <(echo "$json"))
  fi

  rule="[$json]"
}

#######################################
# Merges two JSON strings recursively
#  See https://stackoverflow.com/a/68362041
#  If key=value, 'overlay' is used over 'base' value
#  If key=array, arrays from 'base' and 'overlay' are added and duplicates removed
# Arguments (positional):
#   1) base - the base json
#   2) overlay - the overlay json
# Returns:
#   json - the merged json
#######################################
merge_json() {
  local base=$1
  local overlay=$2
  local args=("-c" "-s")
  args+=('
    def deepmerge(a;b):
      reduce b[] as $item (a;
        reduce ($item | keys_unsorted[]) as $key (.;
          $item[$key] as $val | ($val | type) as $type | .[$key] = if ($type == "object") then
            deepmerge({}; [if .[$key] == null then {} else .[$key] end, $val])
          elif ($type == "array") then
            (.[$key] + $val | unique)
          else
            $val
          end
        )
      ); deepmerge({}; .)')
  json=$(jq "${args[@]}" < <(echo "$base" "$overlay"))
}

#######################################
# Reads, updates, and writes the policy to the API
# Arguments (positional):
#   1) endpoint - the API endpoint to use for submission
#   2) newrules - the rules to add in the submission
#######################################
update_policy() {
  local endpoint=$1
  local newrules=$2

  echo -n "Updating $endpoint ... "

  # Get existing policy
  callapi "GET" "$endpoint"

  # Merge in newrules.  If rule with same name exists, give preference to new rule settings
  local rules; rules="$(jq -c .rules < <(echo "$RESP"))"
  rules=$(jq -c -s '[add | group_by(.name)[] | if .[1] then .[0] + .[1] else .[0] end]' < <(echo "$rules" "$newrules"))

  # Build updated policy
  local args=("-c" "-n")
  local filter=("$RESP")
  args+=("--argjson" "rules" "$rules"); filter+=('| .rules=$rules')
  args+=("${filter[*]}")
  local data; data=$(jq "${args[@]}")

  # Submit policy
  callapi "PUT" "$endpoint" "$data"
  logok
}

################### END OF FUNCTIONS ###################

##### Vulnerability Policies #####
if [ "$TWISTLOCK_POLICY_VULNERABILITIES_ENABLED" == "true" ]; then

  # Setup vulnerability touch points
  vulnerability_endpoints=(
    "host"
    "images"
    "serverless"
    "vms"
  )

  # Get existing or default rule, update it, then merge with policy
  for endpoint in "${vulnerability_endpoints[@]}"; do
    base_rule "$TWISTLOCK_POLICY_NAME" "policies/vulnerability/$endpoint"
    vulnerability_threshold_rule "$rule" "$TWISTLOCK_POLICY_VULNERABILITIES_ALERT_THRESHOLD"
    update_policy "policies/vulnerability/$endpoint" "$rule"
  done

fi

##### Compliance Policies #####
if [ "$TWISTLOCK_POLICY_COMPLIANCE_ENABLED" == "true" ]; then

  # Get list of vulnerabilities
  callapi "GET" "static/vulnerabilities"
  vulns="$RESP"

  compliance_endpoints=(
    "container"
    "host"
    "serverless"
    "vms"
  )

  # List of vulnerability types unique to each endpoint.  API throws error if you submit an incompatible type.
  container_types='"container", "image", "istio"'
  host_types='"daemon_config", "daemon_config_files", "docker_stig", "host_config", "k8s_federation", "k8s_master", "k8s_worker", "linux", "openshift_master", "openshift_worker", "security_operations", "windows"'
  serverless_types='"serverless"'
  vms_types='"daemon_config", "daemon_config_files", "host_config", "linux", "security_operations", "windows"'

  # Setup compliance rules (templates or alert threshold)
  for endpoint in "${compliance_endpoints[@]}"; do
    indirect_types="${endpoint}_types"
    unset rules

    # Convert string to array
    readarray -t TWISTLOCK_POLICY_COMPLIANCE_TEMPLATES < <(echo "$TWISTLOCK_POLICY_COMPLIANCE_TEMPLATES")

    # Each policy set needs its own rule
    for template in "${TWISTLOCK_POLICY_COMPLIANCE_TEMPLATES[@]}"; do
      base_rule "$TWISTLOCK_POLICY_NAME - $template" "policies/compliance/$endpoint"
      compliance_template_rule "$rule" "$template" "${!indirect_types}" "$vulns"

      # Only merge if a rule was created
      if [ -n "$rule" ]; then
        rules=$(jq -c -s add < <(echo "$rules" "$rule"))
      fi
    done

    # There were no matches for the template, so create a threshold rule and merge it instead
    if [ -z "$rules" ]; then
      base_rule "$TWISTLOCK_POLICY_NAME" "policies/compliance/$endpoint"
      compliance_threshold_rule "$rule" "$TWISTLOCK_POLICY_COMPLIANCE_ALERT_THRESHOLD" "${!indirect_types}" "$vulns"
      rules="$rule"
    fi

    update_policy "policies/compliance/$endpoint" "$rules"
  done

fi

##### Runtime Policies #####
if [ "$TWISTLOCK_POLICY_RUNTIME_ENABLED" == "true" ]; then

  # Custom endpoints are loaded from .json files
  runtime_endpoints=(
    "container"
    "host"
    "serverless"
  )

  for endpoint in "${runtime_endpoints[@]}"; do
    # Get existing rule or default
    base_rule "$TWISTLOCK_POLICY_NAME" "policies/runtime/$endpoint"
    indirect_rule="TWISTLOCK_RUNTIME_${endpoint^^}_POLICY_RULE_JSON"
    overlay="${!indirect_rule}"
    runtime_rule "$rule" "$overlay"
    update_policy "policies/runtime/$endpoint" "$rule"
  done
fi