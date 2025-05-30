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
DATE=$(date -u +'%Y_%m_%dT%H-%MZ')

# shellcheck source=twistlock-common.sh
source "$SCRIPTS_DIR/twistlock-common.sh"


authenticate() {
    # shellcheck source=twistlock-auth.sh
    source "$SCRIPTS_DIR/twistlock-auth.sh" 1> /dev/null
}

# exit_if_file_not_min_size(file, min_size=500)
# Exit with error if file is not at least the min_size in bytes
exit_if_file_not_min_size() {
    local file="$1"
    local min_size=${2:-500} # bytes
    local size
    local integer='^[1-9][0-9]*$'

    if ! [[ $min_size =~ $integer ]]; then
        logerror1 "Limit must be a positive integer"
    fi

    if [ ! -r "$file" ]; then
        logerror1 "File '$file' is not readable"
    fi

    size=$(stat -c %s  "$file")
    if [ "$size" -lt "$min_size" ]; then
        logerror1 "File '$file' is less than the minimum '$min_size' required bytes"
    fi
}

get_vuln_stats() {
    echo -n "Getting vuln stats ..."
    "$SCRIPTS_DIR/get-vuln-stats.sh" "$BACKUP_DIR/${PREFIX}vuln-stats_${DATE}.json" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}vuln-stats_${DATE}.json"
    logok
}

get_csv_vuln_reports() {
    echo -n "Getting images CSV Vuln report (wait for it...might take a minute) ... "
    "$SCRIPTS_DIR/twistlock-callapi.sh" 'images/download' "$BACKUP_DIR/${PREFIX}images_${DATE}.csv" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}images_${DATE}.csv" 400000
    logok

    echo -n "Getting hosts CSV Vuln report ... "
    "$SCRIPTS_DIR/twistlock-callapi.sh" 'hosts/download' "$BACKUP_DIR/${PREFIX}hosts_${DATE}.csv" 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}hosts_${DATE}.csv" 100000
    logok
}

get_sboms() {
    authenticate

    echo -n "Getting all image SBOMs ... "
    # Using a direct curl here since callapi does not support this request
    curl -k -s -L -H "Authorization: Bearer $TOKEN" \
        https://"$TWISTLOCK_URL"/api/v1/sbom/download/images \
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
    callapi "GET" 'images/names'
    echo "$RESP" | jq . > "$BACKUP_DIR/${PREFIX}image-list_${DATE}.json"
    exit_if_file_not_min_size "$BACKUP_DIR/${PREFIX}image-list_${DATE}.json" 2000
    logok
}

get_detailed_image_and_host_data() {
    echo -n "Getting detailed image data (wait for it...might take a couple minutes) ... "
    # Gets image data, creates image list sorted descending by age, and get compliance stats
    "$SCRIPTS_DIR/twistlock-software-versions.sh" -d "$BACKUP_DIR" -A -S 1> /dev/null
    exit_if_file_not_min_size "$BACKUP_DIR/images.json" 5000000
    exit_if_file_not_min_size "$BACKUP_DIR/images-by-age.txt" 4000
    logok

    echo -n "Getting detailed host data (wait for it...might take a minute) ... "
    # Gets hosts data (and get same compliance stats)
    "$SCRIPTS_DIR/twistlock-software-versions.sh" -d "$BACKUP_DIR" -t hosts -D 1> /dev/null
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
    echo "Usage: PREFIX='twistlock-' $0 [backup dir (Default: CWD)]"
    echo
    echo "       - PREFIX environment variable sets file prefix for all output files"
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
echo

if [ -z "$TWISTLOCK_CONSOLE_SERVICE" ]; then
    logerror "Twistlock console is not known. Did you source an env file?"
    usage
fi


get_vuln_stats
get_csv_vuln_reports
get_sboms
get_image_list
get_detailed_image_and_host_data
echo -n "All done " && logok
