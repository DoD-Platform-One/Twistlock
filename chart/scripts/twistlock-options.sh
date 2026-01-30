#!/bin/bash
#######################################
# Configures additional misc. settings
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#######################################
# shellcheck disable=SC1091,SC2016

set -e
#set -v
#set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Monitoring network
echo -n "Setting network monitoring to '$TWISTLOCK_NETWORK_CONTAINER' for containers and '$TWISTLOCK_NETWORK_HOST' for hosts ... "
args=("-c" "-n"); filter=('{}')
args+=("--argjson" "container" "$TWISTLOCK_NETWORK_CONTAINER"); filter+=('| .containerEnabled=$container')
args+=("--argjson" "host" "$TWISTLOCK_NETWORK_HOST"); filter+=('| .hostEnabled=$host')
args+=("${filter[*]}")
data=$(jq "${args[@]}")
callapi "PUT" "policies/firewall/network" "$data"
logok

# Logging to stdout and Prometheus metrics
echo -n "Setting logging to '$TWISTLOCK_LOGGING' and monitoring to '$TWISTLOCK_MONITORING' ... "
args=("-c" "-n"); filter=('{}')
args+=("--argjson" "logging" "$TWISTLOCK_LOGGING"); filter+=('| .stdout.enabled=$logging')
args+=("--argjson" "monitoring" "$TWISTLOCK_MONITORING"); filter+=('| .enableMetricsCollection=$monitoring')
args+=("${filter[*]}")
data=$(jq "${args[@]}")
callapi "POST" "settings/logging" "$data"
logok

# Telemetry
echo -n "Setting telemetry to '$TWISTLOCK_TELEMETRY' ... "
args=("-c" "-n"); filter=('{}')
args+=("--argjson" "enabled" "$TWISTLOCK_TELEMETRY"); filter+=('| .enabled=$enabled')
args+=("${filter[*]}")
data=$(jq "${args[@]}")
callapi "POST" "settings/telemetry" "$data"
logok

# Intelligence settings
echo -n "Setting intelligence settings to uploadDisabled=$TWISTLOCK_INTELLIGENCE_UPLOAD_DISABLED ... "
callapi "GET" "settings/intelligence"
args=("-c"); filter=('.')
args+=("--argjson" "uploadDisabled" "$TWISTLOCK_INTELLIGENCE_UPLOAD_DISABLED"); filter+=('| .uploadDisabled=$uploadDisabled')
args+=("${filter[*]}")
data=$(echo "$RESP" | jq "${args[@]}")
callapi "POST" "settings/intelligence" "$data"
logok

# Scan settings
echo -n "Setting scan settings to scanRunningImages=$TWISTLOCK_SCAN_SCAN_RUNNING_IMAGES ... "
callapi "GET" "settings/scan"
args=("-c"); filter=('.')
args+=("--argjson" "scanRunningImages" "$TWISTLOCK_SCAN_SCAN_RUNNING_IMAGES"); filter+=('| .scanRunningImages=$scanRunningImages')
args+=("${filter[*]}")
data=$(echo "$RESP" | jq "${args[@]}")
callapi "POST" "settings/scan" "$data"
logok

# Logon settings
echo -n "Setting logon settings to useSupportCredentials=$TWISTLOCK_LOGON_USE_SUPPORT_CREDENTIALS, strongPassword=$TWISTLOCK_LOGON_REQUIRE_STRONG_PASSWORD, basicAuthDisabled=$TWISTLOCK_LOGON_BASIC_AUTH_DISABLED ... "
callapi "GET" "settings/logon"
args=("-c"); filter=('.')
args+=("--argjson" "useSupportCredentials" "$TWISTLOCK_LOGON_USE_SUPPORT_CREDENTIALS"); filter+=('| .useSupportCredentials=$useSupportCredentials')
args+=("--argjson" "strongPassword" "$TWISTLOCK_LOGON_REQUIRE_STRONG_PASSWORD"); filter+=('| .strongPassword=$strongPassword')
args+=("--argjson" "basicAuthDisabled" "$TWISTLOCK_LOGON_BASIC_AUTH_DISABLED"); filter+=('| .basicAuthDisabled=$basicAuthDisabled')
args+=("${filter[*]}")
data=$(echo "$RESP" | jq "${args[@]}")
callapi "POST" "settings/logon" "$data"
logok
