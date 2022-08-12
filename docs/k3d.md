# Twistlock on k3d

There are some special considerations for Twistlock on k3d that require both a special setup of your k3d cluster and special config of the Twistlock defenders.

By following the sections below to configure your cluster and the defenders you should end up with a Twistlock instance and defender functioning much like they would in a normal cluster (i.e. able to view all pods in the cluster, nodes, scan images, etc).

This document was written and tested against Twistlock 22.01.840, newer versions *may* need additional configuration but start with this as a baseline.

## k3d setup

Below is a k3d config that provides many of the necessary overrides for Twistlock, namely adding volume mounts of directories needed by Defenders.

```yaml
apiVersion: k3d.io/v1alpha4
kind: Simple
servers: 1
agents: 3
options:
  k3s:
    extraArgs:
    - arg: --disable=traefik
      nodeFilters:
      - server:*
  k3d:
    wait: true
volumes:
  - volume: /etc:/etc
    nodeFilters:
      - server:*
      - agents:*
  - volume: /dev/log:/dev/log
    nodeFilters:
      - server:*
      - agents:*
  - volume: /run/systemd/private:/run/systemd/private
    nodeFilters:
      - server:*
      - agents:*
ports:
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer
```

NOTE: this config should be modified to add any typical values you use in your normal dev environment (typically the TLS SAN k3s arg is the minimum to add).

## Twistlock Defender

### Helm Chart Deployment

To run Twistlock Defenders using the Helm chart, you need to provide a valid license and point the defender to the containerd socket in the values.yaml.  The Twistlock init job will use the API to retrieve a daemonset for the Defenders and deploy it into the cluster.

```yaml
console:
  license: "AddYourTwistlockLicenseHere"
defender:
  dockerSocket: /run/k3s/containerd/containerd.sock
```

> If you are performing an upgrade, you will also need to update `console.credentials` with a valid username and password for accessing the API.

### Manual Deployment

NOTE: This method is no longer recommended since you will want to make use of the chart init job. Instead follow the above helm chart deployment and these steps will be completed for you automatically.

For the Twistlock Defender config you will also want to override some of the defaults. The below settings seem to work best on k3d (numbered based on their setting number on the Manage -> Defenders -> Deploy page). If a config is not listed use the default:

3: Choose the name that Defender will use to connect to this Console: `twistlock-console`

10: Specify a custom docker socket path: `/run/k3s/containerd/containerd.sock`

12: Monitor Istio: `On`

14: Use the official Twistlock registry: `Off`

15: Enter the full Defender image name: `registry1.dso.mil/ironbank/twistlock/defender/defender:21.08.520` (update tag to same as console)

16: Enter the name of the secret required to pull the Defender image from your private registry: `private-registry`

17a: Deploy Defenders with SELinux Policy: `On`
17b: Run Defenders as privileged: `Off`
17c: Nodes use Container Runtime Interface (CRI), not Docker: `On`
17d: Nodes run inside containerized environment: `On`

### Known issues

The configuration deployed by the init job or manually is not without some small issues.  Since we are working around some of the limitations of the dockerized cluster and volumes, you will see some errors in the logs of the defender.  The following are known issues related to this configuration:

- `exec: "iptables-*": executable file not found in $PATH exit status 1`: `iptables-save` and `iptables-restore` are not in the Defender pod.  This causes network tracking to fail.
- `Failed to create firewall manager: lstat /proc/1/root/sys/fs/cgroup/memory/docker: no such file or directory`: This one is odd but essentially due to some of the hacks with how we configure the defenders they will fail to find the docker process file here.
- `Failed to download feed /feeds/*.json - stop retry downloading due to an unexpected error: open /var/lib/twistlock/data/*.json: no such file or directory`: Not sure why this one happens but `/var/lib/twistlock` is a mounted path from the host, may occur due to reuse across multiple clusters
- `Failed to start runc proxy: listen unix /var/run/tw.runc.sock: bind: read-only file system`: This is due to the read-only file system of the defenders, CAN be mitigated by modifying the defender daemonset yaml to set `readOnlyRootFilesystem` to `false` (which will result in defender reporting fully healthy in console)
- `Failed to start log inspection for /var/log/*/*.log: failed to add watch to tracked file directory no such file or directory`: Twistlock is looking for specific logs to track, like Apache, MongoDB, and NGINX. We don't use these in Big Bang development, so they can be ignored.  You could mount `/var/log` as shared, but this would result in `monitoring/node-exporter` pods to error on startup.
- `Failed to initialize image client: 'overlay' is not supported over overlayfs: backing file system is unsupported for this graph driver`: This is a result of attempting to an overlay on `/var/lib`.  Mounting `/var/lib` from the host will get rid of this, but causes a problem with more than one defender connecting to the console.

Despite seeing these issues in logs/console reporting the defenders should be functioning sufficiently for baseline testing at this point and reporting on the cluster health in console.
