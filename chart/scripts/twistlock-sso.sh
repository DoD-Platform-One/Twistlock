#!/bin/bash
#######################################
# Configures SAML SSO
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_SSO_CLIENT_ID - SAML client ID
#   TWISTLOCK_SSO_PROVIDER_NAME - Provider Alias                    (optional)
#   TWISTLOCK_SSO_PROVIDER_TYPE - SAML Identity Provider (IdP)
#   TWISTLOCK_SSO_ISSUER_URI - Unique identifier of the IdP
#   TWISTLOCK_SSO_IDP_URL - IdP SSO URL
#   TWISTLOCK_SSO_CONSOLE_URL - Console URL of the Twistlock app    (optional)
#   TWISTLOCK_SSO_GROUPS - Groups Attribute                         (optional)
#   TWISTLOCK_SSO_CERT - X.509 Certificate from IdP
#######################################
# shellcheck disable=SC1091,SC2016

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

echo -n "Configuring SAML SSO ... "

# Build JSON
args=("-c" "-n")
filter=("{}")

args+=("--argjson" "enabled" "$TWISTLOCK_SSO_ENABLED"); filter+=('| .enabled=$enabled')
args+=("--arg" "audience" "$TWISTLOCK_SSO_CLIENT_ID"); filter+=('| .audience=$audience')
if [ -n "$TWISTLOCK_SSO_PROVIDER_NAME" ]; then args+=("--arg" "providerAlias" "$TWISTLOCK_SSO_PROVIDER_NAME"); filter+=('| .providerAlias=$providerAlias'); fi
args+=("--arg" "type" "$TWISTLOCK_SSO_PROVIDER_TYPE"); filter+=('| .type=$type')
args+=("--arg" "issuer" "$TWISTLOCK_SSO_ISSUER_URI"); filter+=('| .issuer=$issuer')
args+=("--arg" "url" "$TWISTLOCK_SSO_IDP_URL"); filter+=('| .url=$url')
if [ -n "$TWISTLOCK_SSO_CONSOLE_URL" ]; then args+=("--arg" "consoleURL" "$TWISTLOCK_SSO_CONSOLE_URL"); filter+=('| .consoleURL=$consoleURL'); fi
if [ -n "$TWISTLOCK_SSO_GROUPS" ]; then args+=("--arg" "groupAttributes" "$TWISTLOCK_SSO_GROUPS"); filter+=('| .groupAttributes=$groupAttributes'); fi
args+=("--arg" "cert" "$TWISTLOCK_SSO_CERT"); filter+=('| .cert=$cert')
args+=("${filter[*]}")
DATA=$(jq "${args[@]}")

# Configure SAML SSO
callapi "POST" "settings/saml" "$DATA"
logok
