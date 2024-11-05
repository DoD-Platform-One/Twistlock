#!/bin/bash
#######################################
#   Get minimal vulnerability stats
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_LICENSE (optional) - the Twistlock license key
#######################################

# Import common environment variables and functions
if [[ $OSTYPE == 'darwin'* ]]; then
  MYDIR="$(dirname "$(greadlink -f "$0")")"
else
  MYDIR="$(dirname "$(readlink -f "$0")")"
fi

usage() {
  echo "$0 <outputfile.json>"
  echo
  echo "Get vulnerability stats for images and hosts, and dump the response to JSON outputfile"
  echo
  echo "Field notes:"
  echo "  - count     :  total CVEs"
  echo "  - impacted  :  count of images impacted by cves of a particular severity"
  echo "  - cves      :  count of unique cves for each severity"
}

[ $# -eq 0 ] && usage && exit 0
[ $# -ne 1 ] && usage && exit 1

if [ ! -w "$1" ]; then
  touch "$1"
  if [ "$?" -ne 0 ]; then
    echo "[ERROR] Output file must be writable"
    usage
    exit 1
  fi
fi

# shellcheck source=twistlock-auth.sh
source "$MYDIR/twistlock-auth.sh"

# shellcheck source=twistlock-common.sh
source "$MYDIR/twistlock-common.sh"

# Limit determines number of vulnerability entries to get details on
# These are not needed, but the minimum is 1, so that field is later deleted
echo "callapi GET 'stats/vulnerabilities?limit=1&offset=0&reverse=false'"
callapi "GET" 'stats/vulnerabilities?limit=1&offset=0&reverse=false'
echo "$RESP" \
  | jq '.[-1] | {images, containers, hosts} | del(.images.vulnerabilities) | del(.containers.cves) | del(.hosts.vulnerabilities)' \
  | tee "$1"