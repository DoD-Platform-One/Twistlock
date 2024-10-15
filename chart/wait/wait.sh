#!/bin/bash
wait_project() {
   # need to remove the default "set -e" to allow commands to return nonzero exit codes without the script failing
   set +e

   # interval and timeout are in seconds
   interval=5
   timeout=600
   daemonset=twistlock-defender-ds
   jobLabel="app.kubernetes.io/name=twistlock-init"
   namespace=twistlock
   counter=0
   while true; do
      initJobStatus=$(kubectl get jobs -l $jobLabel -n $namespace -o jsonpath='{.items[0].status.conditions[?(@.type=="Complete")].status}')
      if [[ $initJobStatus == "True" ]]; then
         break
      fi
      sleep $interval
      let counter++
      if [[ $(($counter * $interval)) -ge $timeout ]]; then
         echo "$daemonset timeout waiting $timeout seconds for creation, running describe..." 1>&2
         kubectl describe jobs -l $jobLabel -n $namespace 1>&2
         exit 1
      fi
   done

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
}


