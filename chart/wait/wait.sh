#!/bin/bash
# interval and timeout are in seconds
interval=5
timeout=600
daemonset=twistlock-defender-ds
namespace=twistlock
counter=0
# need to remove the default "set -e" to allow commands to return nonzero exit codes without the script failing
set +e

# Give enough time for the defenders to show up in the Twistlock console
sleep 60

while true; do
   if [ "$(kubectl get daemonset -n $daemonset -n $namespace -o jsonpath='{.items[*].status.desiredNumberScheduled}')" == "$(kubectl get daemonset -n $daemonset -n $namespace -o jsonpath='{.items[*].status.numberReady}')" ]; then
      echo "$daemonset successfully deployed"
      break
   fi
   sleep $interval
   let counter++
   if [[ $(($counter * $interval)) -ge $timeout ]]; then
      echo "$daemonset timeout waiting $timeout seconds for creation, running describe..." 1>&2
      kubectl describe $daemonset --namespace=$namespace 1>&2
      exit 1
   fi
done
set -e



