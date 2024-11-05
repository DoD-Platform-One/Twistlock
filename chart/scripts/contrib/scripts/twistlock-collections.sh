#!/bin/bash
#######################################
# Creates the collections (with specific ns as specified in values.yaml
# All the images in the respective namespaces are added to the collection.
# A user is created for each collection.
#
# Operations:
# GET gathers informaiton
# PUT Updates Information
# POST creates new objects
# DELETE removes the collection

# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
#   TWISTLOCK_USERS - array of users to add
#   - Newline separates one user from the next
#   - Space delimits fields
#   - Fields (in order) are "user role authtype password"
#   TWISTLOCK_USERS_UPDATE - boolean to toggle updating user if it already exists
#   TWISTLOCK_COLLECTIONS - List of Collections to add
#   - Creates the collection based on Workload namespaces
#   - Appends the Workload Twistlock DevSecOps user to the TWISTLOCK_USERS
#   - If WAAS is enabled updates the collection with the images used in the namespace
#######################################
# shellcheck disable=SC1091,SC2016

set -e
# set -v
# set -x

# Import common environment variables and functions
# The sourcing auth gets a fresh token and also sources twistlock-common.sh
if [[ $OSTYPE == 'darwin'* ]]; then
    MYDIR="$(dirname "$(greadlink -f "$0")")"
    else
    MYDIR="$(dirname "$(readlink -f "$0")")"
    fi
source "$MYDIR/twistlock-auth.sh"
source "$MYDIR/twistlock-common.sh"


main(){
    # collection backup
    # collection restore anchore
    # collection create anchore
    # collection update kiali
    #collection DELETE  anchore
    # get_collection_namespaces kiali < - not working
    # get_cluster_namespaces
    # get_namespace_images kiali
    # add_collection_user anchore anchore
    # create_custom_role
    # verify_collection All
    # collection names
    # find_unused_collections

    echo
}

collection(){
    local request=$1
    local collection_name="$2"
    local collection_namespaces="$3"
    local collection_role=$4
    #IFS=','
    # account for the "/" between collections and the target name
    # Verify collection name is valid
    if [[ -z $collection_name  ]]; then
        true
    else
        check_collection_name "$collection_name"
        collection_param="/$collection_name"
    fi

    # Get the entire array of collections or, if a collection name is specified, get the usage
    # The GET operation will fail if collection name is specified without a usage
    # The PUT operations updates a collection
    # POST creates a collection
    # DELETE removes a collection
    # For differing workflows $op is used as a alias

    if [[ $request == 'backup' ]]; then
        op=GET
            if [[ -z $collection_name  ]]; then
                callapi "$op" "collections"
            else
                callapi "$op" "collections$collection_param/usages"
                return
            fi
            ##########################
            # Remove any existing backup file then
            # Filter out system resources, they can't be managed
            # anything created by "system" can't be manipulated.
            # for backup and restore "system"owned resources are filtered
    elif [[ $request == 'lookup' ]]; then
        op=GET
            if [[ -z $collection_name  ]]; then
                callapi "$op" "collections"
            else
                callapi "$op" "collections$collection_param/usages"
            fi
    elif [[ $request == 'names' ]]; then
        op=GET
            if [[ -z $collection_name  ]]; then
                callapi "$op" "collections"
            else
                callapi "$op" "collections$collection_param/usages"
            fi
            RESP=$(echo $RESP | jq '.[].name')

    elif [[ $request == 'update' ]]; then
        op=PUT
            while IFS= read -r row  ; do
                data+="$row"
            done  < <(cat "collection-name-$collection_name.json") # quoted for spellcheck
            callapi "$op" "collections$collection_param" "$data"
    elif [[ $request == 'restore' ]]; then
        op=POST  # This will restore from a file a collection based on namespace
            while IFS= read -r row  ; do
                data+="$row"
            done  < <(cat "collection-name-$collection_name.json")
            callapi "$op" "collections" "$data"

    elif [[ $request == 'create' ]]; then
        # This will create a collection based on namespace.
        # It builds an admin user and assigns the user to the collection.
        # If the collection exists it will stop execution,
        # The collection will need to be removed beore this will run
        op=POST
            check_collection_name "$collection_name"  # check for proper naming
            verify_collection "$collection_name"  # ensure the collection hasn't already been created
                # For new collections based on namespace.
                # Add the collection
                # Add a useraccount for that collection only
                # assign rules
                args=("-c" "-n")
                filter=("{}")
                args+=("--arg" "containers"  \*); filter+=('| .containers=[$containers]');
                args+=("--arg" "hosts"  \*); filter+=('| .hosts=[$hosts]');
                args+=("--arg" "images"  \*); filter+=('| .images=[$images]');
                args+=("--arg" "labels"  \*); filter+=('| .labels=[$labels]');
                args+=("--arg" "appIDs"  \*); filter+=('| .appIDs=[$appIDs]');
                args+=("--arg" "functions"  \*); filter+=('| .functions=[$functions]');
                args+=("--arg" "name" "$collection_name"); filter+=('| .name=$name');
                args+=("--arg" "namespaces" "$collection_namespaces"); filter+=('| .namespaces=[$namespaces]');
                args+=("--arg" "description" "$collection_name Collection"); filter+=('| .description=$description');
                args+=("--arg" "accountIDs"  \*); filter+=('| .accountIDs=[$accountIDs]');
                args+=("--arg" "codeRepos"  \*); filter+=('| .codeRepos=[$codeRepos]');
                args+=("--arg" "clusters"  \*); filter+=('| .clusters=[$clusters]');
                args+=("${filter[*]}")
                DATA=$(jq "${args[@]}")

                callapi "POST" "collections"  "$DATA"
                logok
                # create a user and role
                add_collection_user "$collection_name" "$collection_namespaces" "$collection_role"
    # This will delete the collection
    # The collection can't be deleted until it isn't being used by any policy or users
    elif [[ $request == 'DELETE' ]]; then
        op=DELETE
            echo "Deleting Collection $collection_name"
            # Remove User
            callapi "$op" "users/$collection_name-admin"
            callapi "$op" "collections$collection_param"
    else
        echo "Missing the correct operation"
    fi
}

# delete_collection(collection_name)
# Deletes collection by name, if it is unused
delete_collection() {
    check_collection_name "$1"

    callapi "GET" "collections/$(urlencode "$1")/usages"
    if [ "$RESP" = "null" ]; then
        callapi "DELETE" "collections/$(urlencode "$1")"
    else
        logerror "Cannot delete collection '$1': used by $RESP"
    fi
}

find_unused_collections() {
    local current_collection_names

    collection lookup
    current_collection_names=$(echo "$RESP" | \
        jq -c \
        '[ .[] | select(.owner != "system").name ]' \
    )
    #echo "[DEBUG] Current collection names: $current_collection_names"

    if [ "$(echo "$current_collection_names" | jq '. | length')" -eq 0 ]; then
        echo "[INFO] No collections found to check usages"
    else
        echo "[INFO] Finding collections with no usages"

        local i; local last_index; local name
        last_index=$(echo "$current_collection_names" | jq '. | length - 1')
        for i in $(seq 0 "$last_index"); do
            name=$(echo "$current_collection_names" | \
                jq -r --arg index "$i" '.[$index|tonumber]' \
            )
            #echo; echo "[DEBUG] Checking collection '$name'"
            callapi "GET" "collections/$(urlencode "$name")/usages"
            if [ "$RESP" = "null" ]; then
                echo "$name"
            fi
        done
        logok
    fi
}

# Prints all images found within the collection namespaces
# get_collection_namespaces_images(collection_name, [collection])
# - collection is optional and is a JSON string. If not provided
#   the lastest collection information will be requested via an API call
# '*' or '' is printed, respectively if namespaces has either of
# those for its value
get_collection_namespaces_images() {
    local collection_name; collection_name="$1"
    local namespaces; local images; local sorted_images

    namespaces=$(get_collection_namespaces "$collection_name" "$2")

    if [ -z "$namespaces" ] || [ "$namespaces" == '*' ]; then
        echo "$namespaces"
    else
        images=""
        for ns in $namespaces
        do
        images+=$(printf "%s\n" "$(get_namespace_images "$ns")")
        # newline does not appear between sets, so a space marker is added
        images+=$(printf " ")
        done
        # convert space marker to newline, sort, and
        # remove trailing newline that is sorted to top
        sorted_images=$(echo "$images" | tr ' ' '\n' | sort -u | tail -n +2)
        #add_images_to_collection "$collection_name" "$sorted_images"
        echo "$sorted_images"
    fi
}

verify_collection() {
    local collection_name; collection_name=$1
    local collections; collections=$(get_collection_names)
    for c in $collections; do
        if [[ "$collection_name" == "$c" ]]; then
        echo "collection_name exists...Skipping "
        break
        fi
    done
}
# Returns list of namespaces found within an existing collection
# get_collection_namespaces(collection_name, [collection])
# - collection is optional and is a JSON string. If not provided
#   the lastest collection information will be requested via an API call
get_collection_namespaces() {
    # check_collection_name "$1"
    local coll; coll="$1"

    if [ "$coll" ]; then
        namespaces=$(echo "$coll" | jq -r --arg name "$coll" '.[] | select(.name == $name)')
    else
        coll=$(collection GET)
    fi
    # note, namespaces may just be "*"
    echo -n "$coll" | jq -rc '.namespaces[]' \
        || logerror1 "Invalid collection; Namespaces could not be retrieved"
}


# Prints a list of all cluster namespaces detected by PCC radar
get_cluster_namespaces() {
    callapi "GET" "radar/container/namespaces"
    echo "$RESP" | jq -r | tr -d '[' | tr -d ']' | tr -d ','
}


# Prints list of images found within a namespace
# get_namespace_images(namespace)
get_namespace_images() {
    local images
    images=$(kubectl get pod -n "$1" -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u)
    if [ -n "$images" ]; then
        echo "$images"
    else
        logerror0 "Failed to retrieve list of namespace images. Invalid namespace '$1'?"
    fi
}

# Logs an error if collection name has invalid characters
# Valid chars: ' A-Za-z0-9_:-'
# check_collection_name(collection_name)
check_collection_name() {
    local re; re='(^)[ a-zA-Z0-9_\:-]+($)'

    if [ -z "$1" ]; then
        logerror1 "Collection name is empty"
    elif ! [[ "$1" =~ $re ]]; then
        logerror1 "Invalid characters in collection name"
    fi
}

add_collection_user() {
    ###############
    # make a user for the new collection.
    # create a unique password
    # create a secret in the namespace of the workload
    # add the info to the TWISTLOCK_USER Variable
    local collection_name=$1
    local collection_namespace=$2
    local collection_role=$3

    if [ -z $collection_role ];then
        collection_role=devSecOps
    fi
    # create the User name and add it to the collection
    collection_user=$(echo "$collection_name-admin")
    collection_admin_password=$(head -c 32 /dev/random | base64)
    collection_role=$collection_role
    collection_authtype="basic"

    # Create a role if needed
    # The default will be devSecOps
    echo "[INFO} Checking Role"
    create_custom_role $collection_role

    $MYDIR/twistlock-users.sh $TWISTLOCK_USERS
    echo "[INFO} Creating Secret"
    declare -a SECRET_TEST="($(kubectl get secret -n "$collection_namespace" -o json | jq '.items[].metadata.name'))"
    for secret in "${SECRET_TEST[@]}";do
        if [ $secret == "$collection_name-twistlock-user" ]; then
            echo "Deleting the old secret"
            kubectl delete secret  -n "$collection_namespace" "$collection_name-twistlock-user"
        fi
    done
    kubectl create secret generic $collection_name-twistlock-user \
        --from-literal=username=$collection_user \
        --from-literal=password=$collection_admin_password \
        --namespace $collection_namespace

    echo $TWISTLOCK_USERS

    TWISTLOCK_USERS="${TWISTLOCK_USERS} $collection_user $collection_role $collection_authtype $collection_admin_password $collection_name" $MYDIR/twistlock-users.sh
}

create_custom_role(){
# When creating a user for a collection the user has to be added to a role.  This function will create a custom role that can be assigned to a user
    local collection_role=$1
    local collection_name=$2

    # Set default role name
    if [[ -z "$collection_role" ]]; then
        collection_role="devSecOps"
    fi

    # See if the role exists
    callapi GET "rbac/roles"
    existing_roles="$(echo "$RESP" | jq -c)"  # make the array pretty
    # get the role nameif it exists
    existing_name="$(jq -c --arg "name" "$collection_role" '.[] | select(.name==$name)' < <(echo $existing_roles))" 

            if [[ -n "$existing_name" ]];then
                echo "No need to make a role,  $collection_role exists"

            else
                echo "$collection_role Not there...creating"

                    while IFS= read -r row  ; do
                        callapi POST "rbac/roles" "$row"
                    done  < <(jq -c --arg name "$collection_role" '.name = $name' $MYDIR/../templates/console/user-roles-template.json)
            fi

}

# Prints the collections found as a JSON string
get_collections() {
    callapi "GET" "collections"
    #echo -n "$RESP"
}


# Prints the collection names separated by newlines
get_collection_names() {
    get_collections | jq -r '.[].name'
    echo $RESP
}


main