#!/bin/bash
#######################################
# Installs Twislock Defenders on each node
# Globals:
#   TOKEN - the authz token for API access
#   TWISTLOCK_URL - the Twistlock endpoint
# See https://prisma.pan.dev/api/cloud/cwpp/defenders#operation/post-defenders-daemonset.yaml for definitions of the following
#   TWISTLOCK_CLUSTER                   (optional)
#   TWISTLOCK_COLLECT_LABELS            (optional)
#   TWISTLOCK_CONSOLE_SERVICE
#   TWISTLOCK_RUNTIME
#   TWISTLOCK_DOCKER_SOCKET             (optional)
#   TWISTLOCK_DEFENDER_IMAGE            (optional)
#   TWISTLOCK_DEFENDER_NODE_SELECTOR    (optional)
#   TWISTLOCK_MONITOR_ISTIO             (optional)
#   TWISTLOCK_NAMESPACE
#   TWISTLOCK_ORCHESTRATION
#   TWISTLOCK_PRIVILEGED                (optional)
#   TWISTLOCK_PROXY_ADDR                (optional)
#   TWISTLOCK_PROXY_CA                  (optional)
#   TWISTLOCK_PROXY_PASSWORD            (optional)
#   TWISTLOCK_PROXY_USERNAME            (optional)
#   TWISTLOCK_PULL_SECRET               (optional)
#   TWISTLOCK_SELINUX                   (optional)
#   TWISTLOCK_MONITOR_SERVICE_ACCOUNTS  (optional)
#   TWISTLOCK_UNIQUE_HOSTS              (optional)
#   TWISTLOCK_PRIORITY_CLASS            (optional)
#######################################
# shellcheck disable=SC1091,SC2016

set -e
# set -v
# set -x

TWISTLOCK_DEFENDER_WSS_TARGET=${TWISTLOCK_DEFENDER_WSS_TARGET:-"$TWISTLOCK_CONSOLE_SERVICE"}

echo "TWISTLOCK_CONSOLE_SERVICE: $TWISTLOCK_CONSOLE_SERVICE"
echo "Defenders will point to: $TWISTLOCK_DEFENDER_WSS_TARGET"

# Import common environment variables and functions
if [[ $OSTYPE == 'darwin'* ]]; then
    MYDIR="$(dirname "$(greadlink -f "$0")")"
    SED="gsed"
else
    MYDIR="$(dirname "$(readlink -f "$0")")"
    SED="sed"
fi

# shellcheck source=twistlock-common.sh
source "$MYDIR/twistlock-common.sh"

# Check for prerequisities
TOOLS=(jq curl "$SED" grep kubectl)
for TOOL in "${TOOLS[@]}"; do
  hash "$TOOL" 2>/dev/null || logerror1 "This script requires $TOOL, but it is not installed."
done

# Login to API and generate TOKEN
# shellcheck source=twistlock-auth.sh
source "$MYDIR/twistlock-auth.sh"

get_defender_manifests() {
  echo -n "Retrieving Defender manifests ... "

  # Build Defender JSON.  Orchestration, Namespace, and Console Address are required.
  args=("-c" "-n")
  filter=("{}")
  if [ -n "$TWISTLOCK_CLUSTER" ]; then args+=("--arg" "cluster" "$TWISTLOCK_CLUSTER"); filter+=('| .cluster=$cluster'); fi
  if [ -n "$TWISTLOCK_COLLECT_LABELS" ]; then args+=("--argjson" "collectPodLabels" "$TWISTLOCK_COLLECT_LABELS"); filter+=('| .collectPodLabels=$collectPodLabels'); fi
  args+=("--arg" "consoleAddr" "$TWISTLOCK_DEFENDER_WSS_TARGET"); filter+=('| .consoleAddr=$consoleAddr')
  if [ -n "$TWISTLOCK_RUNTIME" ]; then args+=("--arg" "containerRuntime" "$TWISTLOCK_RUNTIME"); filter+=('| .containerRuntime=$containerRuntime'); fi
  if [ -n "$TWISTLOCK_DOCKER_SOCKET" ]; then args+=("--arg" "dockerSocketPath" "$TWISTLOCK_DOCKER_SOCKET"); filter+=('| .dockerSocketPath=$dockerSocketPath'); fi
  if [ -n "$TWISTLOCK_DEFENDER_IMAGE" ]; then args+=("--arg" "image" "$TWISTLOCK_DEFENDER_IMAGE"); filter+=('| .image=$image'); fi
  if [ -n "$TWISTLOCK_MONITOR_ISTIO" ]; then args+=("--argjson" "istio" "$TWISTLOCK_MONITOR_ISTIO"); filter+=('| .istio=$istio'); fi
  args+=("--arg" "namespace" "$TWISTLOCK_NAMESPACE"); filter+=('| .namespace=$namespace')
  if [ -n "$TWISTLOCK_DEFENDER_NODE_SELECTOR" ]; then args+=("--arg" "nodeSelector" "$TWISTLOCK_DEFENDER_NODE_SELECTOR"); filter+=('| .nodeSelector=$nodeSelector'); fi
  args+=("--arg" "orchestration" "$TWISTLOCK_ORCHESTRATION"); filter+=('| .orchestration=$orchestration')
  if [ -n "$TWISTLOCK_PRIVILEGED" ]; then args+=("--argjson" "privileged" "$TWISTLOCK_PRIVILEGED"); filter+=('| .privileged=$privileged'); fi
  if [ -n "$TWISTLOCK_PROXY_ADDR" ]; then
    if [ -n "$TWISTLOCK_PROXY_CA" ]; then args+=("--arg" "ca" "$TWISTLOCK_PROXY_CA"); filter+=('| .proxy.ca=$ca'); fi
    args+=("--arg" "httpProxy" "$TWISTLOCK_PROXY_ADDR"); filter+=('| .proxy.httpProxy=$httpProxy')
    if [ -n "$TWISTLOCK_PROXY_PASSWORD" ]; then args+=("--arg" "password" "$TWISTLOCK_PROXY_PASSWORD"); filter+=('| .proxy.password=$password'); fi
    if [ -n "$TWISTLOCK_PROXY_USERNAME" ]; then args+=("--arg" "user" "$TWISTLOCK_PROXY_USERNAME"); filter+=('| .proxy.user=$user'); fi
  fi
  if [ -n "$TWISTLOCK_PULL_SECRET" ]; then args+=("--arg" "secretsName" "$TWISTLOCK_PULL_SECRET"); filter+=('| .secretsName=$secretsName'); fi
  if [ -n "$TWISTLOCK_SELINUX" ]; then args+=("--argjson" "selinux" "$TWISTLOCK_SELINUX"); filter+=('| .selinux=$selinux'); fi
  if [ -n "$TWISTLOCK_MONITOR_SERVICE_ACCOUNTS" ]; then args+=("--argjson" "serviceAccounts" "$TWISTLOCK_MONITOR_SERVICE_ACCOUNTS"); filter+=('| .serviceAccounts=$serviceAccounts'); fi
  if [ -n "$TWISTLOCK_UNIQUE_HOSTS" ]; then args+=("--argjson" "uniqueHostName" "$TWISTLOCK_UNIQUE_HOSTS"); filter+=('| .uniqueHostName=$uniqueHostName'); fi
  if [ -n "$TWISTLOCK_PRIORITY_CLASS" ]; then args+=("--arg" "priorityClassName" "$TWISTLOCK_PRIORITY_CLASS"); filter+=('| .priorityClassName=$priorityClassName'); fi
  args+=("${filter[*]}")
  DATA=$(jq "${args[@]}")

  # Retrieve manifests from API
  callapi "POST" "defenders/daemonset.yaml" "$DATA"
  logok

  # Add pod labels for Kiali (if specified in .Values.defender.podLabels) to Defender DaemonSet
  if [ -n "$TWISTLOCK_DEFENDER_PODLABELS" ]; then
    RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_PODLABELS") yq e 'select(.kind == "DaemonSet").spec.template.metadata.labels += (env(item))' | "$SED" 's/{}//g')
  fi

  # Add resource requests and limits (if specified in .Values.defender.resources) to Defender DaemonSet
  if [ -n "$TWISTLOCK_DEFENDER_RESOURCES" ]; then
    RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_RESOURCES") yq e 'select(.kind == "DaemonSet").spec.template.spec.containers[]|= select(.name == "twistlock-defender").resources = (env(item))' | "$SED" 's/{}//g')
  fi

  # Add tolerations (if specified in .Values.defender.tolerations) to Defender Daemonset
  if [ -n "$TWISTLOCK_DEFENDER_TOLERATIONS" ]; then
    RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_TOLERATIONS") yq e 'select(.kind == "DaemonSet").spec.template.spec.tolerations += (env(item))' | "$SED" 's/{}//g')
  fi

  # Add security context capabilities drop (if specified in .Values.defender.securityCapabilitiesDrop) to Defender Daemonset
  if [ -n "$TWISTLOCK_DEFENDER_SECURITYCONTEXT_DROP_CAPABILITIES" ]; then
    RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_SECURITYCONTEXT_DROP_CAPABILITIES") yq e 'select(.kind == "DaemonSet").spec.template.spec.containers[].securityContext.capabilities.drop += (env(item))' | "$SED" 's/{}//g')
  fi

  # Add security context capabilities add (if specified in .Values.defender.securityCapabilitiesAdd) to Defender Daemonset
  if [ -n "$TWISTLOCK_DEFENDER_SECURITYCONTEXT_ADD_CAPABILITIES" ]; then
    RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_SECURITYCONTEXT_ADD_CAPABILITIES") yq e 'select(.kind == "DaemonSet").spec.template.spec.containers[].securityContext.capabilities.add += (env(item))' | "$SED" 's/{}//g')
  fi

  echo "$RESP" > ./twistlock-defenders.yaml
  echo "Defender ds stored at './twistlock-defenders.yaml'"
}


deploy_defenders() {
  # Deploy Defender
  echo "Deploying Defenders ..."
  # Vendor recommends deleting resources first, but it may not actually be needed
  #kubectl -n twistlock delete ds twistlock-defender-ds
  #kubectl -n twistlock delete sa twistlock-service
  #kubectl -n twistlock delete secret twistlock-secrets
  echo "$RESP" | kubectl apply -f -
  # Name of daemonset pulled from manifests
  TWISTLOCK_DEFENDER_DAEMONSET=$(echo "$RESP" | "$SED" -ne '/kind: DaemonSet/,$ p' | grep -m 1 -oP "(?<=name: ).*")
  if kubectl rollout status daemonset -n "$TWISTLOCK_NAMESPACE" "$TWISTLOCK_DEFENDER_DAEMONSET"; then
    echo -n "Defenders deployed. "
    logok
  else
    logerror "Problem deploying defenders."
  fi

  callapi "GET" "version"
  TWISTLOCK_DEFENDER_VER=$(echo "$RESP" | tr -d '"')
  echo "Defender Version: $TWISTLOCK_DEFENDER_VER"
}


get_defender_manifests

read -r -p "Deploy defenders? (N/y)  " deploy_defenders_ans

if [ "$deploy_defenders_ans" = "y" ] || \
   [ "$deploy_defenders_ans" = "yes" ] || \
   [ "$deploy_defenders_ans" = "Y" ] || \
   [ "$deploy_defenders_ans" = "Yes" ]; then
  deploy_defenders
else
  echo "Skipping defender deployment"
fi
