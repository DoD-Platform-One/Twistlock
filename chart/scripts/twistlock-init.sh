#!/bin/bash
#######################################
# Main script to initialize Twistlock
# - Checks for prerequisites
# - Validates Twistlock console is up
# - Calls other scripts to complete setup
# Globals:
#   TWISTLOCK_URL - the Twistlock endpoint
#######################################
# shellcheck disable=SC1091

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

# Check for prerequisities
TOOLS=(jq curl sed grep kubectl)
for TOOL in "${TOOLS[@]}"; do
  hash "$TOOL" 2>/dev/null || logerror1 "This script requires $TOOL, but it is not installed."
done

# Wait for istio sidecar to be available
if [ -n "$ISTIO_SIDECAR" ]; then
  echo "Waiting for Istio sidecar."
  status=$( timeout 300 bash -c "until curl -fs -o /dev/null -w '%{http_code}' http://localhost:15021/healthz/ready; do sleep 3; done" || true )
  if [ "${status: -3}" != "200" ]; then
    logerror1 "Problem connecting to Istio sidecar (Status code: ${status: -3})"
  else
    echo -n "Istio sidecar ... "
    logok
  fi
fi

# Wait for twistlock endpoint to be available
echo "Waiting for $TWISTLOCK_URL to be up."
status=$( timeout 300 bash -c "until curl -fs -o /dev/null -w '%{http_code}' $TWISTLOCK_URL; do sleep 3; done" || true )
if [ "${status: -3}" != "200" ]; then
  logerror1 "Problem connecting to $TWISTLOCK_URL (Status code: ${status: -3})"
else
  echo -n "Connected to $TWISTLOCK_URL ... "
  logok
fi

# Retrieve auth token.  A valid token is required for all API calls
source "$MYDIR/twistlock-auth.sh"

# Apply/check License.  A valid license is required for all other configuration
source "$MYDIR/twistlock-license.sh"

# Add console users
if [ -n "$TWISTLOCK_USERS" ]; then
  source "$MYDIR/twistlock-users.sh"
fi

# Defender Deployment
if [ "$TWISTLOCK_DEFENDER_ENABLED" == "true" ]; then
  source "$MYDIR/twistlock-defenders.sh"
else
  echo "Skipping Defender deployment."
fi

# Monitoring user creation
if [ "$TWISTLOCK_MONITORING" == "true" ]; then
  source "$MYDIR/twistlock-metrics.sh"
else
  echo "Skipping metrics user creation."
fi

# Policies Deployment
if [ "$TWISTLOCK_POLICY_ENABLED" == "true" ]; then
  source "$MYDIR/twistlock-policies.sh"
else
  echo "Skipping policy configuration."
fi

# Misc Options
if [ "$TWISTLOCK_OPTIONS_ENABLED" == "true" ]; then
  source "$MYDIR/twistlock-options.sh"
else
  echo "Skipping options configuration."
fi

# Terminate istio sidecar
terminate_istio