#!/bin/bash
#######################################
# Restores twistlock configuration for:
#   - Alert profiles
#   - Custom runtime rules
#   - Collections
#   - Container runtime policies
#   - Host runtime policies
#
# The two main capabilities by function are to:
#   1. restore_runtime_configuration
#   2. restore_alert_profiles
#
# Both functions are destructive in that existing resources are torn down and
# brought back up. This helps to ensure that what is deployed matches the
# backup and that all resource dependencies are properly considered.
#
# You can choose to attempt to restore or clear the individual resources,
# but you then you have to take into account the dependencies yourself.
#
# Runtime policies depend on both collections and custom rules,
# so you cannot remove a collection or custom rule that is being used.
# Conversely, you cannot add a runtime policy that depends on a
# custom rule or collection that does not exist.
#
# Alert profiles depend on runtime policies that they trigger on.
# Runtime policies can be removed even if an alert profile depends on it, but
# this will modify the alert trigger. Once all policies that trigger an alert
# are removed, then at best the alert is set to trigger on ANY runtime policy.
# More typically, however, the alert profile triggers must be restored before
# they will work again.
#
# When restoring an alert profile, if a trigger is set to `true`, either
# `allRules` must be `true`, or there must be at least one rule specified
# in `rules[]`. Otherwise, it will not restore properly.
#
# Globals (REQUIRED):
#   - TWISTLOCK_COLLECTION_PREFIX
#   - TWISTLOCK_ALERT_PERIOD_SECONDS
#   - TWISTLOCK_ALERT_WEBHOOK (if any webhook alerts are enabled)
#######################################

set -e

BACKUP_DIR=${1:-"$(pwd)"}

if [ ! -d "$BACKUP_DIR" ] || [ ! -r "$BACKUP_DIR" ] || [ ! -x "$BACKUP_DIR" ]; then
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
    function_menu

    # restore_runtime_configuration
    # restore_collections
    # restore_collections_by_prefix
    # restore_custom_rules
    # restore_alert_profiles
    # clear_alert_profiles
    # clear_container_runtime_policies
    # clear_host_runtime_policies
    # clear_custom_rules
    # clear_stale_collections_by_prefix
    # nuke_runtime_configuration

    #restore_container_runtime_policies "$BACKUP_DIR/runtime-container-policies-backup.json".new
    #restore_host_runtime_policies "$BACKUP_DIR/runtime-host-policies-backup.json".new
}

function_menu() {
    ##########################
    # Function menu to aid in manually restoring
    #
    local function_list; local function_choice
    local function_int; local function_to_run
    function_list=(\
        restore_runtime_configuration \
        restore_collections \
        restore_collections_by_prefix \
        restore_custom_rules \
        restore_container_runtime_policies \
        restore_host_runtime_policies \
        restore_alert_profiles \
        clear_alert_profiles \
        clear_container_runtime_policies \
        clear_host_runtime_policies \
        clear_custom_rules \
        clear_stale_collections_by_prefix \
        nuke_runtime_configuration \
        relearn_containers \
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


clear_alert_profiles() {
    local alert_names
    callapi "GET" "alert-profiles/names"
    alert_names=$(echo "$RESP" | jq -c '.')
    #echo "[DEBUG] Alert profile names: $alert_names"

    if [ "$(echo "$alert_names" | jq '. | length')" -eq 0 ]; then
        echo "[INFO] No alert profiles found to delete"
    else
        echo -n "[INFO] Deleting all alert profiles"

        local i; local last_index; local name
        last_index=$(echo "$alert_names" | jq '. | length - 1')
        for i in $(seq 0 "$last_index"); do
            echo -n "."
            name=$(echo "$alert_names" | \
                jq -r --arg index "$i" '.[$index|tonumber]' \
            )
            #echo; echo "[DEBUG] Deleting alert profile '$name'"
            callapi "DELETE" "alert-profiles/$(urlencode "$name")"
        done
        logok
    fi
}


clear_runtime_policies() {
    local type=$1
    echo -n "[INFO] clearing runtime policies for $1..."

    if [ "$type" != "container" ] && [ "$type" != "host" ]; then
        logerror1 "Invalid runtime policy type '$type'"
    fi

    callapi "PUT" "policies/runtime/$type" "{}"
    logok
}

clear_container_runtime_policies() { clear_runtime_policies container ; }
clear_host_runtime_policies() { clear_runtime_policies host ; }


# Deletes all non-system custom rules
# ASSUMPTIONS: none of the rules are being used
#   - Clearing runtime policies, etc first can ensure this is the case
clear_custom_rules() {
    local rule_ids; local id
    echo -n "[INFO] clearing non-system custom rules..."
    callapi "GET" "custom-rules"
    rule_ids=$(echo "$RESP" | jq -r '[ .[] | select(.owner!="system") | ._id ] | @sh')

    for id in $rule_ids ; do
        echo -n "."
        callapi "DELETE" "custom-rules/$id"
    done
    logok
}


# Deletes all collections that are not in backup and
# whose name starts with prefix (TWISTLOCK_COLLECTION_PREFIX)
clear_stale_collections_by_prefix() {
    local current_collection_names; local backup_collection_names
    local backup
    backup="$BACKUP_DIR/collections-backup.json"

    if [ -z "$TWISTLOCK_COLLECTION_PREFIX" ]; then
        logerror1 "Cannot clear collections by prefix: input TWISTLOCK_COLLECTION_PREFIX required"
    fi

    if [ ! -f "$backup" ] || [ ! -r "$backup" ]; then
        logerror1 "Cannot clear collections by prefix: '$backup' not found"
    fi

    collection lookup
    current_collection_names=$(echo "$RESP" | \
        jq -c --arg prefix "$TWISTLOCK_COLLECTION_PREFIX" \
        '[ .[] | select(.owner != "system" and (.name | startswith($prefix))).name ]' \
    )
    #echo "[DEBUG] Current collection names: $current_collection_names"

    backup_collection_names=$( \
        jq -c --arg prefix "$TWISTLOCK_COLLECTION_PREFIX" \
        '[ .[] | select(.owner != "system" and (.name | startswith($prefix))).name ]' \
        "$backup"
    )
    #echo "[DEBUG] Backup collection names: $backup_collection_names"

    if [ "$(echo "$current_collection_names" | jq '. | length')" -eq 0 ]; then
        echo "No collections with name prefix '$TWISTLOCK_COLLECTION_PREFIX' found"
    else
        echo -n "[INFO] Deleting collections not in backup with prefix '$TWISTLOCK_COLLECTION_PREFIX'"

        local i; local last_index; local name; local found
        last_index=$(echo "$current_collection_names" | jq '. | length - 1')
        for i in $(seq 0 "$last_index"); do
            echo -n "."
            name=$(echo "$current_collection_names" | \
                jq -r --arg index "$i" '.[$index|tonumber]' \
            )
            #echo; echo "[DEBUG] collection name: '$name'"

            found=$(echo "$backup_collection_names" | jq --arg name "$name" '. | index($name)')
            if [ "$found" == "null" ]; then # collection not in backup --> DELETE
                #echo "[DEBUG] Deleting collection '$name'"
                delete_collection "$name"
            fi
        done
        logok
    fi
}


clear_all_collections() {
    local current_collection_names

    collection lookup
    current_collection_names=$(echo "$RESP" | \
        jq -c \
        '[ .[] | select(.owner != "system").name ]' \
    )
    #echo "[DEBUG] Current collection names: $current_collection_names"

    if [ "$(echo "$current_collection_names" | jq '. | length')" -eq 0 ]; then
        echo "[INFO] No collections found to delete"
    else
        echo -n "[INFO] Deleting ALL collections"

        local i; local last_index; local name
        last_index=$(echo "$current_collection_names" | jq '. | length - 1')
        for i in $(seq 0 "$last_index"); do
            echo -n "."
            name=$(echo "$current_collection_names" | \
                jq -r --arg index "$i" '.[$index|tonumber]' \
            )
            #echo; echo "[DEBUG] Deleting collection '$name'"
            delete_collection "$name"
        done
        logok
    fi
}


nuke_runtime_configuration() {
    clear_container_runtime_policies
    clear_host_runtime_policies
    clear_custom_rules
    clear_all_collections
}


# Sets NEXT_CUSTOM_RULE_ID to current max id + 1 and echos the value
get_next_custom_rule_id() {
    echo -n "[INFO] Getting next custom rule id..."
    callapi "GET" "custom-rules"
    NEXT_CUSTOM_RULE_ID=$(( $(echo "$RESP" | jq '[.[]._id] | max') + 1 ))
    echo "$NEXT_CUSTOM_RULE_ID"
}


# For each custom rule in custom rules backup file:
#   - replace ID in custom rules and policy files copies with next available ID
#   - install custom rule using new ID
# ASSUMPTIONS:
#   - backup files exist for runtime policies and custom rules
#   - system custom runtime rules have consistent IDs between environments
#     (this is not true for Waas rules, so ID translation would be needed for them)
#   - user custom runtime rules have already been deleted
#     (no checking for name collisions)
# Rules and policy file copies that contain the updated IDs have filenames that
# end with '.new'
restore_custom_rules() {
    local rule_ids; local id; local payload
    local rule_backup; local container_policy_backup; local host_policy_backup
    rule_backup="$BACKUP_DIR/custom-rules-backup.json"
    container_policy_backup="$BACKUP_DIR/runtime-container-policies-backup.json"
    host_policy_backup="$BACKUP_DIR/runtime-host-policies-backup.json"

    # Establish files to save updated IDs
    echo "" > "$rule_backup".new
    cp "$container_policy_backup" "$container_policy_backup".new
    cp "$host_policy_backup" "$host_policy_backup".new

    rule_ids=$(jq -r '[.[]._id] | @sh' "$rule_backup")

    if [ -z "$rule_ids" ]; then
        echo "[INFO] No custom rules found to restore"
    else
        get_next_custom_rule_id

        echo -n "[INFO] Restoring custom rules"
        for id in $rule_ids ; do
            echo -n "."
            #echo; echo "[DEBUG] Update ID: $id --> $NEXT_CUSTOM_RULE_ID"

            # Replace ID in custom rule payload with new ID
            payload=$(
                jq --arg id "$id" --arg newid "$NEXT_CUSTOM_RULE_ID" \
                '.[] | select(._id==($id | tonumber)) + {"_id": ($newid | tonumber)}' \
                "$rule_backup"
            )
            echo "$payload" >> "$rule_backup".new

            # Update IDs in policy files
            # Note: they are replaced with a string version to mark them as
            # replaced, so that they do not get replaced again in future loops
            if [ "$id" != "$NEXT_CUSTOM_RULE_ID" ]; then
                jq --arg id "$id" --arg newid "$NEXT_CUSTOM_RULE_ID" \
                '(.rules[].customRules[] | select( ._id==($id | tonumber) )._id)=$newid' \
                "$container_policy_backup".new > "$container_policy_backup".updated
                mv "$container_policy_backup".updated "$container_policy_backup".new

                jq --arg id "$id" --arg newid "$NEXT_CUSTOM_RULE_ID" \
                '(.rules[].customRules[] | select( ._id==($id | tonumber) )._id)=$newid' \
                "$host_policy_backup".new > "$host_policy_backup".updated
                mv "$host_policy_backup".updated "$host_policy_backup".new
            fi

            callapi "PUT" "custom-rules/$NEXT_CUSTOM_RULE_ID" "$payload"
            sleep 0.02
            NEXT_CUSTOM_RULE_ID=$(( "$NEXT_CUSTOM_RULE_ID" + 1 ))
        done

        # Ensure policies are in array
        jq -s '.' "$rule_backup".new > "$rule_backup".updated
        mv "$rule_backup".updated "$rule_backup".new

        # Convert string IDs back to numbers
        jq '.rules[].customRules[]._id |= tonumber' \
        "$container_policy_backup".new > "$container_policy_backup".updated
        mv "$container_policy_backup".updated "$container_policy_backup".new

        jq '.rules[].customRules[]._id |= tonumber' \
        "$host_policy_backup".new > "$host_policy_backup".updated
        mv "$host_policy_backup".updated "$host_policy_backup".new

        logok
    fi
}


# restore_collections(prefix)
# Restores collections with names matching prefix from backup file.
# The prefix is optional; if not provided, then all collections in backup
# will be restored. Only collections specified in backup file will be changed.
restore_collections() {
    local prefix; prefix="$1"
    local current_collection_names
    local backup_file; local backup_json
    backup_file="$BACKUP_DIR/collections-backup.json"

    if [ ! -f "$backup_file" ] || [ ! -r "$backup_file" ]; then
        logerror1 "Cannot restore collections: '$backup_file' not found"
    fi

    backup_json=$(
        jq -c --arg prefix "$prefix" \
        '[ .[] | select(.name | startswith($prefix)) ]' \
        "$backup_file"
    )

    if [ "$(echo "$backup_json" | jq '. | length')" -eq 0 ]; then
        echo "[INFO] No collections found to restore"
    else
        collection lookup
        current_collection_names=$(echo "$RESP" | jq -c '[ .[] | select(.owner != "system").name ]')
        #echo "[DEBUG] Current collection names: $current_collection_names"

        echo -n "[INFO] Restoring collections"

        # for each collection with valid name in backup json
        #   - if collection exists, PUT update (TODO check if it changed)
        #   - else POST new collection
        local i; local last_index; local name; local collection; local found
        last_index=$(echo "$backup_json" | jq '. | length - 1')
        for i in $(seq 0 "$last_index"); do
            echo -n "."
            collection=$(echo "$backup_json" | jq -c --arg index "$i" '.[$index|tonumber]')
            name=$(echo "$collection" | jq -r .name)
            #echo; echo "[DEBUG] collection name: '$name'"
            check_collection_name "$name"

            #echo "[DEBUG] collection: $collection"

            found=$(echo "$current_collection_names" | jq --arg name "$name" '. | index($name)')
            if [ "$found" != "null" ]; then # collection exists --> PUT update
                callapi "PUT" "collections/$(urlencode "$name")" "$collection"
            else # collection does not exist --> POST new collection
                callapi "POST" "collections" "$collection"
            fi

            sleep 0.1
        done
        logok
    fi
}

restore_collections_by_prefix(){ restore_collections "$TWISTLOCK_COLLECTION_PREFIX" ; }


# restore_runtime_policy(type, [backup_filepath])
# ASSUMPTIONS:
#   - dependent collections exist
#   - dependent custom rules exist
restore_runtime_policy() {
    local type="$1"
    local backup=${2:-"$BACKUP_DIR/runtime-$type-policies-backup.json"}

    if [ "$type" != "container" ] && [ "$type" != "host" ]; then
        logerror1 "Invalid runtime policy type '$type'"
    fi

    if [ ! -f "$backup" ] || [ ! -r "$backup" ]; then
        logerror1 "Cannot restore runtime $type policy: Cannot read backup file"
    fi

    echo -n "[INFO] Restoring runtime policies for $1 from backup..."
    callapi "PUT" "policies/runtime/$type" "$(jq -rc . "$backup")"
    logok
}

# backup_filepath is optional argument
restore_container_runtime_policies() { restore_runtime_policy container "$1" ; }
restore_host_runtime_policies() { restore_runtime_policy host "$1" ; }


relearn_containers() {
    echo -n "[INFO] Initiating container relearning..."
    callapi "POST" "profiles/container/learn"
    logok
}


restore_runtime_configuration() {
    clear_container_runtime_policies
    clear_host_runtime_policies
    clear_custom_rules
    clear_stale_collections_by_prefix

    restore_collections_by_prefix
    restore_custom_rules
    restore_container_runtime_policies "$BACKUP_DIR/runtime-container-policies-backup.json".new
    restore_host_runtime_policies "$BACKUP_DIR/runtime-host-policies-backup.json".new
    relearn_containers
}


# Clears all alert profiles, restores profiles from backup file, and
# sets the alert aggegration period to TWISTLOCK_ALERT_PERIOD_SECONDS
# If webhooks are enabled, then the url fields are replaced with TWISTLOCK_ALERT_WEBHOOK
restore_alert_profiles() {
    local backup
    backup="$BACKUP_DIR/alert-profiles-backup.json"

    if [ ! -f "$backup" ] || [ ! -r "$backup" ]; then
        logerror1 "Cannot restore alert profiles: '$backup' not found"
    fi

    if [ "$(jq '. | length' "$backup")" -eq 0 ]; then
        echo "[INFO] No alert profiles found to restore"
    elif [ -z "$TWISTLOCK_ALERT_WEBHOOK" ] && \
        [ "$(echo "$RESP" | jq '. | any(.webhook.enabled)?')" != "false" ]; then
        logerror1 "Restoring alert profiles aborted. Missing required environment variable 'TWISTLOCK_ALERT_WEBHOOK' and webhooks alerts enabled"
    else
        clear_alert_profiles
        echo -n "[INFO] Restoring alert profiles"

        # POST the profile for each alert profile in backup file
        local i; local last_index; local name; local profile
        last_index=$(jq '. | length - 1' "$backup")
        for i in $(seq 0 "$last_index"); do
            echo -n "."
            profile=$(jq -c \
                --arg index "$i" \
                --arg url "$TWISTLOCK_ALERT_WEBHOOK" \
                '.[$index|tonumber] | select(.webhook.enabled).webhook.url=$url' \
                "$backup" \
            )
            name=$(echo "$profile" | jq -r .name)
            #echo; echo "[DEBUG] alert profile name: '$name'"

            #echo "[DEBUG] alert profile: $profile"
            callapi "POST" "alert-profiles" "$profile"
            sleep 0.1
        done
        logok

        set_alert_aggregation_period
    fi
}


# Sets alert aggregation period to TWISTLOCK_ALERT_PERIOD_SECONDS
set_alert_aggregation_period() {
    local current_period; local option_payload
    local sec; sec="$TWISTLOCK_ALERT_PERIOD_SECONDS"
    callapi "GET" "settings/alerts"
    current_period="$(echo "$RESP" | jq '.aggregationPeriodMs')"
    echo "[INFO] Current alert aggregation period (in ms): $current_period"

    local re; re='^[1-9][0-9]*$'
    if [ -n "$sec" ] && [[ "$sec" =~ $re ]]; then
        if [ "$current_period" -ne $(( sec * 1000 )) ]; then
            echo -n "[INFO] Setting aggregation period to $sec seconds..."
            option_payload=$(echo "$RESP" | \
                jq --arg seconds "$sec" '.aggregationPeriodMs=($seconds | tonumber * 1000)' \
            )
            callapi "POST" "settings/alerts" "$option_payload"
            logok
        else
            echo "[INFO] Current aggregation period is already correct"
        fi
    else
        logerror "Failed to set alert aggregation period: TWISTLOCK_ALERT_PERIOD_SECONDS must be a positive integer"
    fi
}


main