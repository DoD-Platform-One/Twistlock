#!/bin/bash

release_namespace="$1"
twistlock_console_name="$2"
twistlock_defender_name="$3-ds"

######### Deployment deletion #########
echo "Starting deployment deletion in namespace $release_namespace..."

# Check if the deployment exists before deleting
if [ $(kubectl get deploy -l "app.kubernetes.io/name=$twistlock_console_name"  -n $release_namespace --no-headers | wc -l) -gt 0 ]; then
  echo "Deployment exists, deleting..."
  # Delete the deployment and check if successful
  if kubectl delete deploy $twistlock_console_name -n $release_namespace; then
    echo "Deployments deleted successfully."

    # Optionally, wait for all resources to be deleted
    kubectl wait --for=delete deploy $twistlock_console_name -n $release_namespace --timeout=60s || echo "Some deployments are taking longer to delete."
  else
    echo "[ERROR] Failed to delete deployments." >&2
    exit 1  # Exit with error if the deletion fails
  fi
else
  echo "Deployment does not exist, skipping deletion."
fi

######### Daemonset deletion #########
echo "Starting daemonset deletion in namespace $release_namespace..."

# Check if the daemonset exists before deleting
if [ $(kubectl get daemonset -l "app.kubernetes.io/name=$twistlock_defender_name" -n $release_namespace --no-headers | wc -l) -gt 0 ]; then
  echo "Daemonset exists, deleting..."
  # Delete the daemonset and check if successful
  if kubectl delete daemonset $twistlock_defender_name -n $release_namespace; then
    echo "Daemonsets deleted successfully."

    # Optionally, wait for all resources to be deleted
    kubectl wait --for=delete daemonset $twistlock_defender_name -n $release_namespace --timeout=60s || echo "Some daemonsets are taking longer to delete."
  else
    echo "[ERROR] Failed to delete daemonsets." >&2
    exit 1  # Exit with error if the deletion fails
  fi
else
  echo "Daemonset does not exist, skipping deletion."
fi

######### PVC deletion #########
echo "Starting PVC deletion in namespace $release_namespace..."

# Check if the PVC exists before deleting
if [ $(kubectl get pvc -l "app.kubernetes.io/name=$twistlock_console_name" -n $release_namespace --no-headers | wc -l) -gt 0 ]; then
  echo "PVC exists, deleting..."
  # Update the reclaim policy to Retain for the PV
  pvName="$(kubectl get pvc -n $release_namespace $twistlock_console_name -o jsonpath='{.spec.volumeName}')"
  echo "Getting old reclaim policy for PV $pvName..."
  oldReclaimPolicy="$(kubectl get pv $pvName -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')"
  echo "Old reclaim policy: $oldReclaimPolicy, updating to Retain..."
  kubectl patch pv $pvName -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}' || true
  if [[ "$(kubectl get pv $pvName -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')" == "Retain" ]]; then
    echo "Reclaim policy updated successfully."
  else
    echo "[ERROR] Failed to update reclaim policy." >&2
    exit 1  # Exit with error if the update fails
  fi
  echo "New reclaim policy: Retain, deleting PVCs..."

  # Delete the PVC and check if successful
  kubectl delete pvc -n $release_namespace $twistlock_console_name 2>/dev/null || true
  if [[ "$(kubectl get pvc -n $release_namespace 2>&1)" =~ "No resources found in $release_namespace namespace." ]]; then
    echo "PVCs deleted successfully."
  else
    echo "[ERROR] Failed to delete PVCs." >&2
    exit 1  # Exit with error if the deletion fails
  fi

  # Set the claimRef to null for the PV so that it isn't bound to the PVC
  echo "Setting the claimRef to null for PV $pvName..."
  kubectl patch pv $pvName -p '{"spec":{"claimRef":null}}' || true
  if [[ "$(kubectl get pv $pvName -o jsonpath='{.spec.claimRef}')" == "" ]]; then
    echo "ClaimRef set to null successfully."
  else
    echo "[ERROR] Failed to set claimRef to null." >&2
    exit 1  # Exit with error if the update fails
  fi

  # Revert the reclaim policy to the original value
  echo "Reverting the reclaim policy for PV $pvName to $oldReclaimPolicy and reinstating the claimRef..."
  kubectl patch pv $pvName -p '{"spec":{"persistentVolumeReclaimPolicy":"'$oldReclaimPolicy'", "claimRef":{"name":"'$twistlock_console_name'", "namespace":"twistlock"}}}' || true
  if [[ "$(kubectl get pv $pvName -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')" == "$oldReclaimPolicy" ]]; then
    echo "Reclaim policy reverted successfully."
  else
    echo "[ERROR] Failed to revert reclaim policy." >&2
    exit 1  # Exit with error if the update fails
  fi
else
  echo "PVC does not exist, skipping deletion."
fi

exit 0
