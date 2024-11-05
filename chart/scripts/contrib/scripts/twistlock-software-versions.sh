#!/bin/bash
#######################################
#   View software versions in images and hosts from twistlock
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_LICENSE (optional) - the Twistlock license key
#######################################

# https://pan.dev/prisma-cloud/api/cwpp/get-images/
# https://pan.dev/prisma-cloud/api/cwpp/get-hosts-info/
#
# data fields of interest for software list
# - _id / hostname
# - cloudMetadata
# - clusters, collections
# - distro, osDistro, osDistroRelease
# - scanBuildDate,scanID,scanTime,scanVersion
# BUT primarily:
# - packages,applications
#
# of those, only these are available for individual fields:
#callapi "GET" "hosts?limit=1&offset=0&reverse=true&sort=vulnerabilityRiskScore&fields=hostname,cloudMetadata,clusters,collections,distro,osDistro,osDistroRelease,scanID"
#echo "$RESP" > host-software.json
#
# most useful thing for host profiles is the listening ports
#callapi "GET" "profiles/host?limit=1&offset=0"
#echo "$RESP" > hosts-profile.json


set -e

# Import common environment variables and functions
if [[ $OSTYPE == 'darwin'* ]]; then
  MYDIR="$(dirname "$(greadlink -f "$0")")"
else
  MYDIR="$(dirname "$(readlink -f "$0")")"
fi

# shellcheck source=twistlock-common.sh
source "$MYDIR/twistlock-common.sh"

INTEGER='^[1-9][0-9]*$'
DATE='^[1-2][0-9]{3}-[0-1][0-9]-[0-3][0-9]$' # close enough for sanity checking YYYY-MM-DD
TYPES="images hosts"
MAX_API_LIMIT=50 # max number of records per API call
SORT="&reverse=true&sort=complianceRiskScore" # TODO break this out into its own option

DATA_DIR=$(pwd)


authenticate() {
  # shellcheck source=twistlock-auth.sh
  source "$MYDIR/twistlock-auth.sh"
}


get_next_limit() {
  # Always use max limit when doing secondary filtering beyond API to avoid excessive API calls
  if [ -z "$LIMIT" ]; then
    limit="$MAX_API_LIMIT"
  else
    local results_desired; results_desired=$((LIMIT - TOTAL_FOUND))
    if [ "$results_desired" -lt "$MAX_API_LIMIT" ]; then
      limit="$results_desired"
    else
      limit="$MAX_API_LIMIT"
    fi
  fi
}


select_and_download_data() {
  if [ -z "$type" ] && [ -z "$PRINT_IMG_AGE" ]; then # default
    local starting_offset="$offset"
    download_data "images" "$IMAGES_DATA"

    offset="$starting_offset"
    download_data "hosts" "$HOSTS_DATA"
  elif [ -n "$PRINT_IMG_AGE" ] || [ "$type" = "images" ]; then
    download_data "images" "$IMAGES_DATA"
  elif [ "$type" = "hosts" ]; then
    download_data "hosts" "$HOSTS_DATA"
  else
    logerror1 "Invalid download selection type '$type'"
  fi

  download_compliance_stats
}


# download_data(type, output)
# downloads data of 'images' or 'hosts' type to output
download_data() {
  NEXT_OFFSET=0
  TOTAL_FOUND=0
  get_next_limit
  local type="$1"
  local output="$2"
  local count="$limit"
  local prev_limit="$limit"

  echo "[INFO] Downloading '$type' data to '$output'..."
  echo "" > "$output"

  while { [ -z "$LIMIT" ] || [ "$TOTAL_FOUND" -lt "$LIMIT" ]; } \
    && [ "$count" -ge "$prev_limit" ] \
    && [ "$limit" -gt 0 ]
  do
    prev_limit="$limit"

    echo "[DEBUG] callapi GET ${type}?limit=${limit}${offset}${compact}${collection}${clusters}${host_name}${SORT}"
    callapi "GET" "${type}?limit=${limit}${offset}${compact}${collection}${clusters}${host_name}${SORT}"
    count=$(echo "$RESP" | jq -cr '. | length')
    #echo "[DEBUG] count: $count"

    if [ -z "$RESP" ] || [ "$RESP" = "null" ];then
      if [ "$TOTAL_FOUND" = "0" ]; then
        logerror1 "No records returned...try adjusting the search parameters"
      else
        echo "No more records to search for..."
        break
      fi
    fi

    TOTAL_FOUND=$((TOTAL_FOUND + $(echo "$RESP" | jq -cr '. | length') ))
    echo "[INFO] TOTAL_FOUND: $TOTAL_FOUND  //  offset: $NEXT_OFFSET"

    echo "$RESP" | jq -c '.[]' >> "$output"

    NEXT_OFFSET=$((NEXT_OFFSET + count))
    offset="&offset=$NEXT_OFFSET"
    get_next_limit
  done

  jq -s '.' "$output" > "$output".tmp && mv "$output".tmp "$output"
}


# Exits program with error if input data file (images or hosts) appears to be compact vs. full
# Compact files never include package information
# is_compact_data_file(input_file)
error_on_compact_data_file() {
  if [ "$(jq '.[0].packages == null' "$1")" != "false" ]; then
    logerror1 "Cannot parse required data from compact data file. Resync to pull fresh data"
  fi
}


# Saves json array of images with tags to $IMG_LIST and cats file
print_image_list() {
  echo -n "[INFO] Saving image list to '$IMG_LIST'..."
  callapi "GET" "images/names"
  logok
  echo "$RESP" | jq . > "$IMG_LIST"
  cat "$IMG_LIST"
}


print_image_age() {
  echo "[INFO] Saving list of images sorted by age to '$DATA_DIR/images-by-age.txt'..."
  if [ -z "$NS_PRINT_LIMIT" ]; then
    NS_PRINT_LIMIT=3
    echo "[INFO] No Namespace Limit specified, using default ($NS_PRINT_LIMIT)"
  fi
  echo "[INFO] Printing only top 20 oldest images"
  echo

  if [ -n "$IMAGES_DATA" ] && [ -r "$IMAGES_DATA" ]; then
    error_on_compact_data_file "$IMAGES_DATA"
    jq --arg ns_limit $NS_PRINT_LIMIT -r '[.[] | {age: [.history[].created] | map(select(. > 0)) | min, image_path: "\(.repoTag.registry)/\(.repoTag.repo):\(.repoTag.tag)", namespaces}] | sort_by(.age) | [.[] | {age: .age | todateiso8601, image_path, namespaces: .namespaces[0:($ns_limit | tonumber)] | (join(", ")? // "")}] | [.[] | with_entries(.key |= ascii_downcase)] | (.[0] | keys_unsorted | (., map(length*"-")) | @tsv), (.[] | map(.) | @tsv)' "$IMAGES_DATA" | column -ts $'\t' > "$DATA_DIR/images-by-age.txt"
    head -n 22 "$DATA_DIR/images-by-age.txt"
  else
    logerror1 "Cannot read cached data at '$IMAGES_DATA'"
  fi
}


print_vuln_summary() {
  echo "TODO - print_vuln_summary()"
  # There are multiple vuln summaries that could be printed
  # 1) List of the top Vulns (vuln explorer table) - use vuln stats with Limit set to number of vulns to display up to 100
  # 2) Vuln metrics (input data for line charts) - use vuln stats with Limit 1 and ignore the 1 vuln info downloaded
  #    see get-vuln-stats.sh script
  # 3) List of the top Vuln images
  # Get 'compact' images set or reuse images data
  # jq '.[0] | { scanTime, creationTime, repoTag, clusters, namespaces, vulnerabilitiesCount, vulnerabilityDistribution, vulnerabilityRiskScore }' images.json
}


# Downloads all compliance stats for images and hosts and prints a summary
# The JSON download can be further parsed for category or template specific stats
download_compliance_stats() {
  authenticate
  echo -n "[INFO] Saving list of compliance stats to '$COMPLIANCE_STATS'..."
  callapi "GET" "stats/compliance"
  logok
  echo "$RESP" | jq . > "$COMPLIANCE_STATS"
  echo
  jq  '. | { "available_checks": .ids | length, "summary": .daily[-1], rules, "templates": [ .templates[].name ], "categories": [ .categories[].name ] }' \
    "$COMPLIANCE_STATS"
  echo
}


# Parses compliance stats for benchmark checks, saves the JSON list, and outputs number of checks
get_compliance_checks() {
  if [ -n "$COMPLIANCE_STATS" ] && [ ! -r "$COMPLIANCE_STATS" ]; then
    download_compliance_stats
  fi

  echo "[INFO] Saving list of compliance benchmark checks to '$COMPLIANCE_CHECKS'..."
  jq '[ .ids[] | del(.failed, .total) ] | sort_by(.id)' "$COMPLIANCE_STATS" > "$COMPLIANCE_CHECKS"
  echo "$(jq '. | length' "$COMPLIANCE_CHECKS") benchmark checks found"
}


parse_host_compliance() {
  echo -n "[INFO] Saving host compliance data to '$HOST_COMPLIANCE'..."
  if [ -n "$HOSTS_DATA" ] && [ -r "$HOSTS_DATA" ]; then
    error_on_compact_data_file "$HOSTS_DATA"
    jq '[ .[] | { _id, complianceRiskScore, complianceDistribution, complianceIssues } ]' \
      "$HOSTS_DATA" > "$HOST_COMPLIANCE"
    logok
  else
    logerror1 "Cannot read cached host data at '$HOSTS_DATA'"
  fi
}


parse_image_compliance() {
  echo -n "[INFO] Saving image compliance data to '$IMAGE_COMPLIANCE'..."
  if [ -n "$IMAGES_DATA" ] && [ -r "$IMAGES_DATA" ]; then
    error_on_compact_data_file "$IMAGES_DATA"
    jq '[ .[] | { _id, repoTag, namespaces, complianceRiskScore, complianceDistribution, complianceIssues } ]' \
      "$IMAGES_DATA" > "$IMAGE_COMPLIANCE"
    logok
  else
    logerror1 "Cannot read cached image data at '$IMAGES_DATA'"
  fi
}


# parse compliance data out of image and/or host reports
# TODO: combine with Benchmark ID (when not null) into JSON or custom CSV output
build_compliance_report() {
  if [ -z "$type" ]; then # default
    parse_image_compliance
    parse_host_compliance
  elif [ "$type" = "images" ]; then
    parse_image_compliance
  elif [ "$type" = "hosts" ]; then
    parse_host_compliance
  else
    logerror1 "Invalid download selection type '$type'"
  fi
}


# find_software(type)
find_software() {
  # TODO: find software in host files
  # TODO: limit query by clusters, collections, etc

  if [ -z "$search" ]; then
    logerror1 "No input search term provided"
  fi

  echo "[INFO] finding software using search '$search'..."

  if [ -n "$IMAGES_DATA" ] && [ -r "$IMAGES_DATA" ]; then
    error_on_compact_data_file "$IMAGES_DATA"
    jq --arg searchstr "$search" \
    '{ search: ($searchstr), data: [ .[] | select([ .. | .name?,.path? | select(. != null and contains($searchstr))] | length > 0) | {_id, img: (.repoTag.repo), namespaces, clusters} ] }' \
    "$IMAGES_DATA" | tee "$DATA_DIR/results.json"
  else
    logerror1 "Cannot read cached data at '$IMAGES_DATA'"
  fi

  # Example queries
  # prints all name or path fields with ncurses in it
  #jq '[ .[] | .. | .name?,.path? | select(. != null and contains("ncurses"))  ]' images.json

  # does not work properly, but 'any' query should be much more efficient than what is currently used
  #jq '[ . | select(any(.. | .name?,.path? ; . != null and contains("SEARCHSTR")) ) // [] | .[] | {_id, namespaces, img: (.repoTag.repo)} ]' images.json
}


############################### MAIN #################################

usage() { echo "$0 usage:" && grep " .)\ #" "$0" | grep -vi "TODO" ; exit 0; }
[ $# -eq 0 ] && usage


while getopts "AaBbC:c:d:DH:hIl:L:no:pPs:St:v:V" arg; do
  case $arg in
    A) # Print Age of images (sorted by oldest to youngest); Cannot be used with "type" other than "images"
      PRINT_IMG_AGE="true"
      FULL_DATA_REQ="true"
      ;;
    a) # TODO Search apps only (applications + packages, but not binaries; default: both)
      echo "-a TODO"
      ;;
    B) # Downloads compliance Benchmark stats
      GET_COMPLIANCE_CHECKS="true"
      ;;
    b) # TODO Search binaries (binaries + startup binaries, but no apps; default: both)
      echo "-b TODO"
      ;;
    C) # Collection to limit search; Enter "list" to see the collections and exit program
      collection="&collections=${OPTARG}"
      echo "[INFO] Collection:      '$collection'"
      ;;
    c) # Clusters to limit search (cluster1,cluster2)
      clusters="&clusters=${OPTARG}"
      echo "[INFO] Clusters:        '$clusters'"
      ;;
    d) # Data directory path (default: CWD)
      DATA_DIR="$OPTARG"
      ;;
    D) # Download raw data only and exit program
      DOWNLOAD_ONLY="true"
      ;;
    H) # hostname to limit search
      host_name="&hostname=${OPTARG}"
      echo "[INFO] Hostname:        '$host_name'"
      ;;
    h) # Display help"
      usage
      ;;
    I) # Downloads and prints Image list
      PRINT_IMG_LIST="true"
      ;;
    l) # Limit total number of records to download (Default: no limit)
      if [[ $OPTARG =~ $INTEGER ]]; then
        LIMIT="$OPTARG"
        echo "[INFO] Limit:            $LIMIT"
      else
        logerror1 "Limit must be a positive integer"
      fi
      ;;
    L) # Limit the amount of namespaces that get printed out
      if [[ $OPTARG =~ $INTEGER ]]; then
        NS_PRINT_LIMIT="$OPTARG"
        echo "[INFO] Namespace Limit:            $NS_PRINT_LIMIT"
      else
        logerror1 "Namespace limit must be a positive integer"
      fi
      ;;
    n) # TODO Search software names (default: names and path)
      echo "-n TODO"
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
    p) # TODO Search software paths (default: true)
      echo "-p TODO"
      ;;
    P) # Build Policy compliance report
      BUILD_COMPLIANCE_REPORT="true"
      FULL_DATA_REQ="true"
      ;;
    s) # Software search string (for searching within name and/or path)
      FULL_DATA_REQ="true"
      search="${OPTARG}"
      echo "[INFO] Search str:      '$search'"
      ;;
    S) # Sync twistlock data (download json data; default uses cached data)
      DOWNLOAD_DATA="true"
      ;;
    t) # Type is any if not specified. Otherwise, pick from "images", "hosts"
      if echo "$TYPES" | grep -qw -- "${OPTARG}"; then
        type="${OPTARG}"
        echo "[INFO] Type:            '$type'"
      else
        logerror1 "Type must be one of $TYPES"
      fi
      ;;
    v) # TODO Software version to search for in addition to name/path (implies -a and no -b)
      echo "-v TODO"
      ;;
    V) # (WIP) Print vulnerabilities summary (if sync selected, only syncs *compact* data set)
      PRINT_VULN_SUMMARY="true"
      ;;
    *)  # Display help"
      usage
      ;;
  esac
done


if [ ! -d "$DATA_DIR" ] || [ ! -w "$DATA_DIR" ] || [ ! -x "$DATA_DIR" ]; then
  logerror1 "Input data directory must be a valid directory (readable and writable)"
else
  echo "[INFO] Data dir:        '$DATA_DIR'"
  HOSTS_DATA="$DATA_DIR/hosts.json"
  IMAGES_DATA="$DATA_DIR/images.json"
  IMG_LIST="$DATA_DIR/image-list.json"
  COMPLIANCE_STATS="$DATA_DIR/compliance-stats.json"
  COMPLIANCE_CHECKS="$DATA_DIR/compliance-checks.json"
  HOST_COMPLIANCE="$DATA_DIR/host-compliance.json"
  IMAGE_COMPLIANCE="$DATA_DIR/image-compliance.json"
fi

if [ -n "$type" ] && [ "$type" != "images" ] && [ -n "$PRINT_IMG_AGE" ]; then
  logerror1 "Type input as '$type', but expected to be 'images' or omitted"
fi

if [ -n "$collection" ] && [ "$collection" == "&collections=list" ]; then
  authenticate

  # shellcheck source=twistlock-collections.sh
  source "$MYDIR/twistlock-collections.sh"

  echo; echo "Listing collections..."
  collection names
  echo "$RESP" | jq -r
  exit 0
fi

if [ -n "$PRINT_IMG_LIST" ]; then
  authenticate
  print_image_list
  exit 0
fi

if [ -n "$DOWNLOAD_ONLY" ]; then
  authenticate
  select_and_download_data
  exit 0
fi


# Functionality below requires cached or downloaded data

if [ -z "$FULL_DATA_REQ" ] && [ -n "$PRINT_VULN_SUMMARY" ]; then
    compact="&compact=true"
    # Note: compact info includes useful quick information such as scan info
    # that cannot be retrieved with specified fields using 'field' operator
fi

if [ -n "$DOWNLOAD_DATA" ]; then
  authenticate
  select_and_download_data
fi

if [ -n "$PRINT_IMG_AGE" ]; then print_image_age; fi
if [ -n "$PRINT_VULN_SUMMARY" ]; then print_vuln_summary; fi
if [ -n "$GET_COMPLIANCE_CHECKS" ]; then get_compliance_checks; fi
if [ -n "$BUILD_COMPLIANCE_REPORT" ]; then build_compliance_report; fi
if [ -n "$search" ]; then find_software "$type"; fi