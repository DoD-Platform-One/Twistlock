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
#   TWISTLOCK_CRI                       (optional)
#   TWISTLOCK_DOCKER_SOCKET             (optional)
#   TWISTLOCK_DEFENDER_IMAGE            (optional)
#   TWISTLOCK_MONITOR_ISTIO             (optional)
#   TWISTLOCK_NAMESPACE
#   TWISTLOCK_NODE_SELECTOR             (optional)
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
#######################################
# shellcheck disable=SC1091,SC2016

set -e
# set -v
# set -x

# Import common environment variables and functions
MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR/twistlock-common.sh"

echo -n "Retrieving Defender manifests ... "

# Build Defender JSON.  Orchestration, Namespace, and Console Address are required.
args=("-c" "-n")
filter=("{}")
if [ -n "$TWISTLOCK_CLUSTER" ]; then args+=("--arg" "cluster" "$TWISTLOCK_CLUSTER"); filter+=('| .cluster=$cluster'); fi
if [ -n "$TWISTLOCK_COLLECT_LABELS" ]; then args+=("--argjson" "collectPodLabels" "$TWISTLOCK_COLLECT_LABELS"); filter+=('| .collectPodLabels=$collectPodLabels'); fi
args+=("--arg" "consoleAddr" "$TWISTLOCK_CONSOLE_SERVICE"); filter+=('| .consoleAddr=$consoleAddr')
if [ -n "$TWISTLOCK_CRI" ]; then args+=("--argjson" "cri" "$TWISTLOCK_CRI"); filter+=('| .cri=$cri'); fi
if [ -n "$TWISTLOCK_DOCKER_SOCKET" ]; then args+=("--arg" "dockerSocketPath" "$TWISTLOCK_DOCKER_SOCKET"); filter+=('| .dockerSocketPath=$dockerSocketPath'); fi
if [ -n "$TWISTLOCK_DEFENDER_IMAGE" ]; then args+=("--arg" "image" "$TWISTLOCK_DEFENDER_IMAGE"); filter+=('| .image=$image'); fi
if [ -n "$TWISTLOCK_MONITOR_ISTIO" ]; then args+=("--argjson" "istio" "$TWISTLOCK_MONITOR_ISTIO"); filter+=('| .istio=$istio'); fi
args+=("--arg" "namespace" "$TWISTLOCK_NAMESPACE"); filter+=('| .namespace=$namespace')
if [ -n "$TWISTLOCK_NODE_SELECTOR" ]; then args+=("--arg" "nodeSelector" "$TWISTLOCK_NODE_SELECTOR"); filter+=('| .nodeSelector=$nodeSelector'); fi
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
args+=("${filter[*]}")
DATA=$(jq "${args[@]}")

# Retrieve manifests from API
callapi "POST" "defenders/daemonset.yaml" "$DATA"
logok

# Add tolerations (if specified in .Values.defender.tolerations) to Defender Daemonset
if [ -n "$TWISTLOCK_DEFENDER_TOLERATIONS" ]; then
  RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_TOLERATIONS") yq e 'select(.kind == "DaemonSet").spec.template.spec.tolerations += (env(item))' | sed 's/{}//g')
fi

# Add security context capabilities drop (if specified in .Values.defender.securityCapabilitiesDrop) to Defender Daemonset
if [ -n "$TWISTLOCK_DEFENDER_SECURITYCONTEXT_DROP_CAPABILITIES" ]; then
  RESP=$(echo -e "$RESP" | item=$(echo -e "$TWISTLOCK_DEFENDER_SECURITYCONTEXT_DROP_CAPABILITIES") yq e 'select(.kind == "DaemonSet").spec.template.spec.containers[].securityContext.capabilities.drop += (env(item))' | sed 's/{}//g')
fi

# Deploy Defender
echo "Deploying Defenders ..."
echo "$RESP" | kubectl apply -f -
# Name of daemonset pulled from manifests
TWISTLOCK_DEFENDER_DAEMONSET=$(echo "$RESP" | sed -ne '/kind: DaemonSet/,$ p' | grep -m 1 -oP "(?<=name: ).*")
if kubectl rollout status daemonset -n "$TWISTLOCK_NAMESPACE" "$TWISTLOCK_DEFENDER_DAEMONSET"; then
  echo -n "Defenders deployed. "
  logok
else
  logerror "Problem deploying defenders."
fi

callapi "GET" "version"
TWISTLOCK_DEFENDER_VER=$(echo "$RESP" | tr -d '"')
echo "Defender Version: $TWISTLOCK_DEFENDER_VER"