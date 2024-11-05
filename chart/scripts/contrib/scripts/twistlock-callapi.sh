#!/bin/bash
#######################################
#   Run arbitrary API endpoint GET request and dump response to file
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
  echo "$0 '<api-request>' <outputfile>"
  echo
  echo "Run arbitrary API endpoint GET request and dump response to outputfile"
  echo "IMPORTANT: Wrap the API request in single quotes"
  echo
  echo "Example:"
  echo "    $(basename $0) 'audits/runtime/container/timeslice?buckets=100&from=2023-08-13T02:25:25.648Z&namespace=gitlab&offset=0&reverse=true' OUTPUT.json"
}

[ $# -eq 0 ] && usage && exit 0
[ $# -ne 2 ] && usage && exit 1

if [ ! -w "$2" ]; then
  touch "$2"
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

echo "callapi GET $1"
callapi "GET" "$1"
echo "$RESP" | tee "$2"