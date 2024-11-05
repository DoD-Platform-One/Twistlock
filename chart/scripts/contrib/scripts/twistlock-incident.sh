#!/bin/bash
#######################################
#   Helps manage and respond to incidents
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_LICENSE (optional) - the Twistlock license key
#######################################

set -e

#############################
# Use to check the status and acknowledge incidents
# Flags used by incidents
# Examples:
#
# Get usage:
# $> twistlock-incident.sh -h
#
# Get all incidents from the All collection
# $> twistlock-incident.sh -c All
#
# Get message of a single incident by ID
# $> twistlock-incident.sh -i <incident id or unique portion of>
#
# Get all container incidents that match search term (hostname) 'ip-10-199-99-99.us-gov-west-1.compute.internal'
# - The search term matches audit ID, hostname, and image name
# $> twistlock-incident.sh -t container -i ip-10-199-99-99.us-gov-west-1.compute.internal
#
# Get all incidents in a date range. The -s is the starting date. The default end date is the current date/time.
# $> twistlock-incident.sh -s10-22-22
#
# Get up to 100 incidents that have 'Cron app anacron' in the message:
# $> twistlock-incident.sh -l 100 -m "Cron app anacron"
#
# If is recommended to filter by a search term, etc when possible, in addition to the message filter
# Acknowlege all incidents matching incident search term (image 'istio/proxyv2') and
#   message "iptables-restore launched" and category Altered Binary
# $> twistlock-incident.sh -i istio/proxyv2 -d alteredBinary -m "iptables-restore launched" -A
#
# Get list of incident IDs and associated offsets (for each set) that match a search
# $> twistlock-incident.sh -t container -d suspiciousBinary -m "python3.9 wrote a suspicious packed/encrypted binary to /tmp/pip-target" -R
#
# Get a full incident record based on search criteria. If you know the incident id, use it with -i
# $> twistlock-incident.sh -t container -i gitlab-runner-helper -m "Suspected malicious ELF file" -I
#
# Get full incident record by id and shows 10 forensic events
# $> twistlock-incident.sh -i <incident id or unique portion of> -F 10
#
# Acknowledge all incidents in a date range that are not in portScanning category (note preceding hyphen)
# $> twistlock-incident.sh -s 10-22-22 -e 10-23-22 -d -portScanning -A
#
# Restore (unarchive) an incident by ID
# $> twistlock-incident.sh -i <incident id or unique portion of> -a -A


# Import common environment variables and functions
if [[ $OSTYPE == 'darwin'* ]]; then
  MYDIR="$(dirname "$(greadlink -f "$0")")"
else
  MYDIR="$(dirname "$(readlink -f "$0")")"
fi

# shellcheck source=twistlock-auth.sh
source "$MYDIR/twistlock-auth.sh"

# shellcheck source=twistlock-common.sh
source "$MYDIR/twistlock-common.sh"

# shellcheck source=twistlock-collections.sh
source "$MYDIR/twistlock-collections.sh"

ACKNOWLEDGED="&acknowledged=false"
INTEGER='^[1-9][0-9]*$'
DATE='^[1-2][0-9]{3}-[0-1][0-9]-[0-3][0-9]$' # close enough for sanity checking YYYY-MM-DD
CATEGORIES="portScanning hijackedProcess dataExfiltration kubernetes backdoorAdministrativeAccount backdoorSSHAccess cryptoMiner lateralMovement bruteForce customRule alteredBinary suspiciousBinary executionFlowHijackAttempt reverseShell malware cloudProvider"
TYPES="container host function app-embedded"
MAX_API_LIMIT=50 # max number of records per API call

NEXT_OFFSET=0
CHAR_LIMIT=100


# get_forensics(rec, limit)
# Gets up to 'limit' forensics events associated with an incident record 'rec'
# For a limit of 1, only the availability of forensics is reported
# Note: the API appears to only change the output for even limits
#   (e.g., limits of 5 and 6 would return up to 4 and 6 results, respectively)
get_forensics() {
  local rec="$1"
  local limit

  if [ -n "$2" ] && [[ $2 =~ $INTEGER ]] && [ "$2" -gt 1 ]; then
    limit="$2"
    echo "Attempting to get up to $limit forensic events..."
  else
    limit=1 # api at most would return empty array, so we just report availability
    echo -n "Checking if forensics are available... "
  fi

  local host; host=$(echo "$rec" | jq -r '.hostname')
  local incidentID; incidentID=$(echo "$rec" | jq -r '._id')
  local eventTime; eventTime=$(echo "$rec" | jq -r '.time')
  local profileID; profileID=$(echo "$rec" | jq -r '.profileID')
  local incidentType; incidentType=$(echo "$rec" | jq -r '.type')

  if [ "$incidentType" = "container" ] || [ "$incidentType" = "host" ]; then
    callapi "GET" "profiles/$incidentType/$profileID/forensic?eventTime=${eventTime}&hostname=${host}&incidentID=${incidentID}&limit=${limit}"

    if [ "$limit" -eq 1 ]; then
      logok
    else
      echo "$RESP" | jq .
    fi
  else
    logerror0 "Getting forensics only supported on 'container' or 'host' type incidents"
  fi
}


get_incidents() {
  TOTAL_FOUND=0
  get_next_limit
  local messages='[]'
  local acknowledged
  local count="$limit"
  local prev_limit="$limit"
  local matched_records
  local ids

  while { [ -z "$LIMIT" ] || [ "$TOTAL_FOUND" -lt "$LIMIT" ]; } \
    && [ "$count" -ge "$prev_limit" ] \
    && [ "$limit" -gt 0 ]
  do
    acknowledged=0
    prev_limit="$limit"

    callapi "GET" "audits/incidents?${ACKNOWLEDGED}${category}${collection}${type}&limit=${limit}${search}${from}${to}${offset}"
    count=$(echo "$RESP" | jq -r '. | length')
    #echo "[DEBUG] count: $count"

    if [ -z "$RESP" ] || [ "$RESP" = "null" ];then
      echo "No incidents returned..."
      break
    fi

    matched_records=$(echo "$RESP" | jq -c \
      --arg msg "$message" \
      '[ .[] | select(.audits != null and (.audits[].msg | test($msg)) ) ] | unique' \
    )
    TOTAL_FOUND=$((TOTAL_FOUND + $(echo "$matched_records" | jq -r '. | length') ))
    echo "[INFO] TOTAL_FOUND: $TOTAL_FOUND  //  offset: $NEXT_OFFSET"

    if [ "$SINGLE_INCIDENT_REC" = true ] || [ -n "$FORENSICS_LIMIT" ]; then
      if [ "$TOTAL_FOUND" -gt 0 ]; then
        local rec; rec=$(echo "$matched_records" | jq -c '.[0]')
        echo "$rec" | jq .
        echo; echo
        get_forensics "$rec" "$FORENSICS_LIMIT"
        exit 0
      fi
    elif [ "$REVERSE_ID_LOOKUP" = true ]; then
      echo "$matched_records" | jq -r '[ .[]._id ] | join(" ")'
    elif [ "$ACK" = "true" ]; then
      ids=$(echo "$matched_records" | jq -r '[ .[]._id ] | join(" ")')
      for id in $ids; do
        if [ -z "$LIMIT" ] || [ "$acknowledged" -lt "$LIMIT" ]; then
          acknowledge_incident "$id"
          acknowledged=$((acknowledged + 1))
        fi
      done
    else
      local new_messages
      # get messages that match, truncate them, and unique them
      new_messages=$(echo "$matched_records" | jq -c \
        --arg msg "$message" \
        --arg char_limit "$CHAR_LIMIT" \
        '[ .[].audits[].msg | select(contains($msg)) | .[0:$char_limit|tonumber] ] | unique' \
      )

      #echo "[DEBUG]     messages: $messages"
      #echo "[DEBUG] new_messages: $new_messages"

      # Print new messages not already cached (TODO - Fix)
      #echo "$new_messages" | jq --arg msgs "$messages" '.[] | select(contains($msgs)|not)'

      # Add new messages to messages cache
      new_messages=$(echo "$new_messages" | jq -r '.[]')
      messages=$(echo "$messages" | jq -c --arg new "$new_messages" '. + ($new|split("\n")) | unique')
    fi

    NEXT_OFFSET=$((NEXT_OFFSET + count - acknowledged))
    offset="&offset=$NEXT_OFFSET"
    get_next_limit
  done
  echo "[INFO]     messages: $(echo "$messages" | jq .)" # only needed until intermediate print fixed
}


convert_date_format() {
  local INPUT_DATE="$1"
  local queryClock; queryClock="T00:00:00Z"
  local dateIn="$INPUT_DATE$queryClock"

  QUERY_TIME=$(jq -r --arg date "$dateIn" -n '$date| fromdate | strftime("%Y-%m-%dT%I:%M:%S.000Z")')
}


acknowledge_incident() {
  local id=$1
  if [ "$ACKNOWLEDGED" = "&acknowledged=false" ]; then
    echo -n "Acknowledging incident '$id' "
    callapi "PATCH" "audits/incidents/acknowledge/$id" '{"acknowledged":true}' ignorestatus
  else
    echo -n "Restoring incident '$id' "
    callapi "PATCH" "audits/incidents/acknowledge/$id" '{"acknowledged":false}' ignorestatus
  fi

  logok
}


get_next_limit() {
  # Always use max limit when doing secondary filtering beyond API to avoid excessive API calls
  if [ -z "$LIMIT" ] || [ -n "$message" ]; then
    limit="$MAX_API_LIMIT"
  else
    local results_desired; results_desired=$((LIMIT - TOTAL_FOUND))
    if [ "$results_desired" -lt 50 ]; then
      limit="$results_desired"
    else
      limit="$MAX_API_LIMIT"
    fi
  fi
}


############################### MAIN #################################

usage() { echo "$0 usage:" && grep " .)\ #" "$0"; exit 0; }
[ $# -eq 0 ] && usage

while getopts "Aac:d:e:F:Ii:l:m:o:p:Rs:t:h" arg; do
  case $arg in
    A) # Archive/Acknowledge (unarchive with -a) found incidents that match search parameters
      ACK="true"
      ;;
    a) # Process archived incidents (Default: process active incidents)
      ACKNOWLEDGED="&acknowledged=true"
      ;;
    c) # Collection Name Enter "list" to see the collections
      collection="&collections=${OPTARG}"
      echo "[INFO] Collection:      '$collection'"
      ;;
    d) # Category "portScanning","hijackedProcess","dataExfiltration","kubernetes","backdoorAdministrativeAccount","backdoorSSHAccess","cryptoMiner","lateralMovement","bruteForce","customRule","alteredBinary","suspiciousBinary","executionFlowHijackAttempt","reverseShell","malware","cloudProvider"
      NOT_CATEGORIES=$(echo -n "-$CATEGORIES" | jq -sRr '. | split(" ") | join(" -")')
      if echo "$CATEGORIES" | grep -qw -- "${OPTARG}" \
        || echo "$NOT_CATEGORIES" | grep -qw -- "${OPTARG}"; then
        category="&category=${OPTARG}"
        echo "[INFO] Category:        '$category'"
      else
        logerror1 "Category must be one of $CATEGORIES (prefaced with '-' optional)"
      fi
      ;;
    e) # End Range (optional) in YYYY-MM-DD format (Note: the time is set to 00:00:00)
      to=${OPTARG}
      if [[ $to =~ $DATE ]]; then
        convert_date_format "$to"
        to="&to=$QUERY_TIME"
        echo "[INFO] End Range:       '$to'"
      else
        logerror1 "End range must be in date format 'YYYY-MM-DD'"
      fi
      ;;
    F) # Number of forensic events to display for an incident. Implies -I (Default: 1 - only report forensics availability)
      if [[ $OPTARG =~ $INTEGER ]]; then
        FORENSICS_LIMIT=${OPTARG}
        echo "[INFO] Forensic events: '$FORENSICS_LIMIT'"
      else
        logerror1 "Forensic event limit must be a positive integer"
      fi
      ;;
    I) # Get full incident for first record matching search criteria. Overrides -A, -L (set to 1), and -R
      SINGLE_INCIDENT_REC="true"
      ;;
    i) # Incident search term. Use incident ID (or unique portion) to find single incident
      search="&search=${OPTARG}"
      echo "[INFO] Search term:     '$search'"
      ;;
    l) # Limit total number of incidents to return (Default: no limit)
      if [[ $OPTARG =~ $INTEGER ]]; then
        LIMIT="$OPTARG"
        echo "[INFO] Limit:            $LIMIT"
      else
        logerror1 "Limit must be a positive integer"
      fi
      ;;
    m) # Incident message search string for secondary search within returned results
      message="${OPTARG}"
      echo "[INFO] Message search:  '$message'"
      ;;
    o) # Starting offset for returned results (Default: 0)
      if [[ $OPTARG =~ $INTEGER ]]; then
        NEXT_OFFSET=${OPTARG}
        offset="&offset=$NEXT_OFFSET"
        echo "[INFO] Starting offset: '$offset'"
      else
        logerror1 "Starting offset must be a positive integer"
      fi
      ;;
    p) # Print this many message characters (Default: 100; Min: 20)
      if [[ $OPTARG =~ $INTEGER ]] && [ "$OPTARG" -ge 20 ]; then
        CHAR_LIMIT="$OPTARG"
        echo "[INFO] Msg Char Limit:   $CHAR_LIMIT"
      else
        logerror1 "Message Character Limit must be a positive integer >= 20"
      fi
      ;;
    R) # Reverse lookup of IDs based on search criteria. Overrides -A
      REVERSE_ID_LOOKUP="true"
      ;;
    s) # Start Range in YYYY-MM-DD format (Note: time is set to 00:00:00Z)
      from=${OPTARG}
      if [[ $from =~ $DATE ]]; then
        convert_date_format "$from"
        from="&from=$QUERY_TIME";
        echo "[INFO] Start Range:     '$from'"
      else
        logerror1 "Start range must be in date format 'YYYY-MM-DD'"
      fi
      ;;
    t) # Type is any if not specified. Otherwise, pick from "container", "host", "function", "app-embedded"
      if echo "$TYPES" | grep -qw -- "${OPTARG}"; then
        type="&type=${OPTARG}"
        echo "[INFO] Type:            '$type'"
      else
        logerror1 "Type must be one of $TYPES"
      fi
      ;;
    h | *) # Display help"
      usage
      ;;
  esac
done

if [ -n "$collection" ] && [ "$collection" == "&collections=list" ]; then
  echo; echo "Listing collections..."
  collection names
  echo "$RESP" | jq -r
  exit 0
fi

if [ "$ACKNOWLEDGED" = "&acknowledged=true" ]; then
  echo "[INFO] Processing archived incidents..."
fi

# Mutually exclusive modes of operation
if [ "$SINGLE_INCIDENT_REC" = true ] || [ -n "$FORENSICS_LIMIT" ]; then
  LIMIT=1
  echo "[INFO] Getting FULL record for single incident..."
elif [ "$REVERSE_ID_LOOKUP" = true ]; then
  echo "[INFO] Outputting incident IDs using reverse lookup..."
elif [ "$ACK" = true ]; then
  echo "[INFO] Acknowledging/Restoring incidents..."
else
  echo "[INFO] Outputting consolidated audit messages..."
fi

get_incidents