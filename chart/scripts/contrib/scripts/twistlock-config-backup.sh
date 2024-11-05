#!/bin/bash
#######################################
# Backs up twistlock configuration
#   - Alert profiles
#   - Custom runtime rules
#   - Collections
#   - Container runtime policies
#   - Host runtime policies
#######################################

set -e

BACKUP_DIR=${1:-"$(pwd)"}

if [ ! -d "$BACKUP_DIR" ] || [ ! -w "$BACKUP_DIR" ] || [ ! -x "$BACKUP_DIR" ]; then
    echo "[ERROR] Cannot write to backup directory '$BACKUP_DIR'"
    echo
    echo "Usage: $0 [backup dir (Default: CWD)]"
    exit 1
else
    echo "Selected backup directory: $BACKUP_DIR"
    echo
fi

# Import common environment variables and functions
# The sourcing auth gets a fresh token and also sources twistlock-common.sh
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


main() {
    # backup_alert_profiles
    # backup_custom_rules
    # backup_runtime_policy container
    # backup_runtime_policy host
    # backup_collections

    function_menu
}

function_menu() {
    ##########################
    # Function menu to aid in manually backing up
    #
    local function_list; local function_choice
    local function_int; local function_to_run
    function_list=(\
        backup_all \
        backup_alert_profiles \
        backup_custom_rules \
        backup_collections \
        backup_container_runtime_policy \
        backup_host_runtime_policy \
    )

    # Loop through the functions; add an int for easy user selection
    function_int=1
    for func in "${function_list[@]}"; do
        echo "($function_int) $func"
        ((function_int=function_int+1))
    done
    printf "(Q) To quit \n\n"
    read -r -p "[INPUT] Select from one of the above functions: " function_choice
    printf "\n"

    # Set the function_int to be one less so it equals the length of the function list
    ((function_int=function_int-1))
    re='^[1-9][0-9]*$'
    if [[ $function_choice =~ $re ]] && [[ $function_choice -le $function_int ]]; then
        function_to_run=${function_list[function_choice-1]}
        printf "[INFO] Running the %s function... \n\n" "$function_to_run"
        $function_to_run
    elif [[ $function_choice =~ $re ]] && [[ $function_choice -gt $function_int ]]; then
        printf "[ERROR] The number you entered is too high, make a different selection. \n\n"
        function_menu
    elif [[ $function_choice =~ ^[Qq]$ ]]; then
        printf "[INFO] Exiting... \n"
        exit 1
    else
        printf "[ERROR] %s is not a valid selection. Please try again. \n\n" "$function_choice"
        function_menu
    fi
}

backup_all() {
    backup_alert_profiles
    backup_custom_rules
    backup_collections
    backup_container_runtime_policy
    backup_host_runtime_policy
}

backup_alert_profiles() {
    echo -n "[INFO] backing up alert profiles..."

    callapi "GET" "alert-profiles"
    if [ -n "$RESP" ] && [ "$RESP" != "null" ]; then
        if [ -z "$TWISTLOCK_ALERT_WEBHOOK" ] && [ "$(echo "$RESP" | jq '. | any(.webhook.enabled)?')" != "false" ]; then
            logerror "Backup aborted. Missing required environment variable 'TWISTLOCK_ALERT_WEBHOOK' and webhooks alerts enabled"
        else
            echo "$RESP" | jq \
                '[ .[] | select(.webhook.enabled).webhook.url="TWISTLOCK_WEBHOOK_URL" ]' \
                > "$BACKUP_DIR/alert-profiles-backup.json"
            logok
        fi
    else
        echo "null" > "$BACKUP_DIR/alert-profiles-backup.json"
        logok
    fi
}

#######################################
# Backs up non-system collections to file
#######################################
backup_collections() {
    echo -n "[INFO] backing up collections..."
    echo -n "" > "$BACKUP_DIR/collections-backup.json"

    callapi "GET" "collections"
    echo "$RESP" | jq '[ .[] | select(.owner!="system") ]' \
        > "$BACKUP_DIR/collections-backup.json"
    logok
}

#######################################
# Backs up host or container runtime policies to file
# Arguments:
#   policy type string ('container' or 'host')
# Outputs:
#   Writes log to STDOUT and policy JSON to backup file
#######################################
backup_runtime_policy() {
    local type=$1
    echo -n "[INFO] backing up runtime policies for $1..."

    if [ "$type" != "container" ] && [ "$type" != "host" ]; then
        logerror1 "Invalid runtime policy type '$type'"
    fi

    echo -n "" > "$BACKUP_DIR/runtime-$type-policies-backup.json"

    callapi GET "policies/runtime/$type"
    echo "$RESP" | jq '.' > "$BACKUP_DIR/runtime-$type-policies-backup.json"
    logok
}

backup_container_runtime_policy() {
    backup_runtime_policy container
}

backup_host_runtime_policy() {
    backup_runtime_policy host
}

#######################################
# Backs up non-system custom rules to file
#######################################
backup_custom_rules() {
    echo -n "[INFO] backing up custom rules..."
    echo -n "" > "$BACKUP_DIR/custom-rules-backup.json"

    callapi GET "custom-rules"
    echo "$RESP" | jq '[ .[] | select(.owner!="system") ]' \
        > "$BACKUP_DIR/custom-rules-backup.json"
    logok
}


main