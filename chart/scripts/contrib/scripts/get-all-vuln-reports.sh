#!/bin/bash
############################################################
# Get all of the typical reports that a SCA or rep may want
#   - Vulnerability high level stats
#   - Vulnerability reports (CSV) for host and images
#   - Compliance Stats (NOTE: compliance checks on PCC are limited)
#   - SBOMs (hosts are generally the same so an SBoM is only provided for one host)
#   - Concise images list
#   - Images listed by Age
#   - Full images and hosts data set (vulns, compliance, packages, binaries, docker manifests, etc)
#
# The reports are dumped to the current working directory or a directory specificied by input argument

# Checking created file sizes along the way instead to ensure ERROR messages are clearly printed
#set -e

SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR=${1:-"$(pwd)"}
PREFIX=${PREFIX:-"twistlock-"} # Prepend each output file with this string
HOST_LIMIT=${HOST_LIMIT:-""}
DATE=$(date -u +'%Y_%m_%dT%H-%MZ')
COLLECTION_STR="" # will get set by COLLECTION env variable, if found and valid
HOST_LIMIT_STR="" # will get set by HOST_LIMIT env variable, if found and valid

# shellcheck source=twistlock-common.sh
source "$SCRIPTS_DIR/twistlock-common.sh"


authenticate() {
    # shellcheck source=twistlock-auth.sh
    source "$SCRIPTS_DIR/twistlock-auth.sh" 1> /dev/null
}

# check_is_positive_integer(number, description="Number")
# Exit with error if input number is not a positive integer
check_is_positive_integer() {
    local integer='^[1-9][0-9]*$'
    local description; description=${2:-"Number"}

    if ! [[ $1 =~ $integer ]]; then
        logerror1 "$description must be a positive integer"
    fi
}

# exit_if_file_not_min_size(file, min_size=500)
# Exit with error if file is not at least the min_size in bytes
exit_if_file_not_min_size() {
    local file="$1"
    local min_size=${2:-500} # bytes
    local size

    check_is_positive_integer "$min_size" "Minimum file size Limit"

    if [ ! -r "$file" ]; then
        logerror1 "File '$file' is not readable"
    fi

    size=$(stat -c %s  "$file")
    if [ "$size" -lt "$min_size" ]; then
        logerror1 "File '$file' is less than the minimum '$min_size' required bytes"
    fi
}

get_vuln_stats() {
    echo -n "Getting vuln stats ... "
    "$SCRIPTS_DIR/get-vuln-stats.sh" "$BACKUP_DIR/${PREFIX}vuln-stats_${DATE}.json" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}vuln-stats_${DATE}.json"
    logok
}

get_csv_vuln_reports() {
    echo -n "Getting images CSV Vuln report (wait for it...might take a minute) ... "
    "$SCRIPTS_DIR/twistlock-callapi.sh" "images/download$COLLECTION_STR" "$BACKUP_DIR/${PREFIX}images_${DATE}.csv" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}images_${DATE}.csv" 400000
    logok

    echo -n "Getting hosts CSV Vuln report ... "
    "$SCRIPTS_DIR/twistlock-callapi.sh" "hosts/download$HOST_LIMIT_STR" "$BACKUP_DIR/${PREFIX}hosts_${DATE}.csv" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}hosts_${DATE}.csv" 100000
    logok
}

get_sboms() {
    authenticate

    echo -n "Getting all image SBOMs ... "
    # Using a direct curl here since callapi does not support this request
    curl -k -s -L -H "Authorization: Bearer $TOKEN" \
        https://"$TWISTLOCK_URL/api/v1/sbom/download/images$COLLECTION_STR" \
        --output "$BACKUP_DIR/${PREFIX}SBOMs-images_${DATE}.tar.gz"
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}SBOMs-images_${DATE}.tar.gz" 400000
    logok

    echo -n "Getting a sample host SBOM JSON file ... "
    # Twistlock bug causes host sboms file names in archived to all be the same, so we only download a single SBOM (JSON)
    # This bug should be fixed in PCC Quinn update 2
    "$SCRIPTS_DIR/twistlock-callapi.sh" 'sbom/download/hosts?limit=1' "$BACKUP_DIR/${PREFIX}SBOM-host-sample_${DATE}.json" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}SBOM-host-sample_${DATE}.json" 100000
    logok
}

get_image_list() {
    authenticate

    echo -n "Getting concise images list ... "
    callapi "GET" "images/names$COLLECTION_STR"
    echo "$RESP" | jq . > "$BACKUP_DIR/${PREFIX}image-list_${DATE}.json"
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}image-list_${DATE}.json" 2000
    logok
}

get_detailed_image_and_host_data() {
    echo -n "Getting detailed image data (wait for it...might take a couple minutes) ... "
    # Gets image data, creates image list sorted descending by age, and get compliance stats
    if [ -n "$COLLECTION" ]; then
        "$SCRIPTS_DIR/twistlock-software-versions.sh" -d "$BACKUP_DIR" -A -S -C "$COLLECTION" 1> /dev/null
        exit_if_file_not_min_size "$BACKUP_DIR/images.json" 100000
        exit_if_file_not_min_size "$BACKUP_DIR/images-by-age.txt" 100
    else
        "$SCRIPTS_DIR/twistlock-software-versions.sh" -d "$BACKUP_DIR" -A -S 1> /dev/null
        exit_if_file_not_min_size "$BACKUP_DIR/images.json" 5000000
        exit_if_file_not_min_size "$BACKUP_DIR/images-by-age.txt" 4000
    fi
    logok

    echo -n "Getting detailed host data (wait for it...might take a minute) ... "
    # Gets hosts data (and get same compliance stats)
    if [ -n "$HOST_LIMIT" ]; then
        "$SCRIPTS_DIR/twistlock-software-versions.sh" -d "$BACKUP_DIR" -t hosts -D -l "$HOST_LIMIT" 1> /dev/null
    else
        "$SCRIPTS_DIR/twistlock-software-versions.sh" -d "$BACKUP_DIR" -t hosts -D 1> /dev/null
    fi
    exit_if_file_not_min_size "$BACKUP_DIR/hosts.json" 1000000
    exit_if_file_not_min_size "$BACKUP_DIR/compliance-stats.json" 75000
    logok

    echo -n "Updating filenames ... "
    mv "$BACKUP_DIR/images.json" "$BACKUP_DIR/${PREFIX}images_${DATE}.json"
    mv "$BACKUP_DIR/images-by-age.txt" "$BACKUP_DIR/${PREFIX}images-by-age_${DATE}.txt"
    mv "$BACKUP_DIR/hosts.json" "$BACKUP_DIR/${PREFIX}hosts_${DATE}.json"
    mv "$BACKUP_DIR/compliance-stats.json" "$BACKUP_DIR/${PREFIX}compliance-stats_${DATE}.json"
    logok
}

usage() {
    echo
    echo "Usage: COLLECTION=All PREFIX='twistlock-' $0 [backup dir (Default: CWD)]"
    echo
    echo "       - PREFIX environment variable sets file prefix for all output files"
    echo "       - COLLECTION environment variable can scope operations (all image data requests but vuln stats)"
    echo "       - HOST_LIMIT environment variable can reduce host data to pull (e.g., set to 1 when all hosts are same)"
    echo "       - Twistlock console URL and credentials are inputted via standard environment variables"
    echo "         (See example env file)"
    echo
    exit 1
}


if [ ! -d "$BACKUP_DIR" ] || [ ! -w "$BACKUP_DIR" ] || [ ! -x "$BACKUP_DIR" ]; then
    logerror "Cannot write to backup directory '$BACKUP_DIR'"
    usage
else
    echo "Backup directory: $BACKUP_DIR"
fi

echo "Scripts dir:      $SCRIPTS_DIR"
echo "File Prefix:      $PREFIX"
[ -n "$COLLECTION" ] && echo "Collection :      $COLLECTION"
[ -n "$HOST_LIMIT" ] && echo "Host Limit :      $HOST_LIMIT"
echo

if [ -z "$TWISTLOCK_CONSOLE_SERVICE" ]; then
    logerror "Twistlock console is not known. Did you source an env file?"
    usage
fi

if [ -n "$COLLECTION" ]; then
    # shellcheck source=twistlock-collections.sh
    source "$SCRIPTS_DIR/twistlock-collections.sh"
    if [ "$(collection_exists "$COLLECTION")" != "true" ]; then
        logerror "Collection '$COLLECTION' does not exist"
        usage
    else
        COLLECTION_STR="?collections=$COLLECTION"
        #echo "COLLECTION_STR: '$COLLECTION_STR'"
    fi
fi

if [ -n "$HOST_LIMIT" ]; then
    check_is_positive_integer "$HOST_LIMIT" "Host Limit"
    HOST_LIMIT_STR="?limit=$HOST_LIMIT"
    #echo "HOST_LIMIT_STR: '$HOST_LIMIT_STR'"
fi

get_vuln_stats # cannot scope stats based on collection https://pan.dev/prisma-cloud/api/cwpp/get-stats-vulnerabilities/
get_csv_vuln_reports
get_sboms
get_image_list
get_detailed_image_and_host_data
echo -n "All done " && logok
