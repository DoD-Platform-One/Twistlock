# Twistlock on k3d

There are some special considerations for Twistlock on k3d that require both a special setup of your k3d cluster and special config of the Twistlock defenders.

By following the sections below to configure your cluster and the defenders you should end up with a Twistlock instance and defender functioning much like they would in a normal cluster (i.e. able to view all pods in the cluster, nodes, scan images, etc).

This document was written and tested against Twistlock 22.01.840, newer versions *may* need additional configuration but start with this as a baseline.

## k3d setup

It is recommended to use the [k3d-dev.sh](https://repo1.dso.mil/big-bang/bigbang/-/raw/master/docs/reference/scripts/developer/k3d-dev.sh?ref_type=heads) script to deploy k3d to an aws instance, as it will automatically configure the required settings.

If you are not using the `k3d-dev.sh` script, below is a k3d config that provides many of the necessary overrides for Twistlock, namely adding volume mounts of directories needed by Defenders.

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

### Known issues

The configuration deployed by the init job or manually is not without some small issues.  Since we are working around some of the limitations of the dockerized cluster and volumes, you will see some errors in the logs of the defender.  The following are known issues related to this configuration:

- `exec: "iptables-*": executable file not found in $PATH exit status 1`: `iptables-save` and `iptables-restore` are not in the Defender pod.  This causes network tracking to fail.
- `Failed to create firewall manager: lstat /proc/1/root/sys/fs/cgroup/memory/docker: no such file or directory`: This one is odd but essentially due to some of the hacks with how we configure the defenders they will fail to find the docker process file here.
- `Failed to download feed /feeds/*.json - stop retry downloading due to an unexpected error: open /var/lib/twistlock/data/*.json: no such file or directory`: Not sure why this one happens but `/var/lib/twistlock` is a mounted path from the host, may occur due to reuse across multiple clusters
- `Failed to start runc proxy: listen unix /var/run/tw.runc.sock: bind: read-only file system`: This is due to the read-only file system of the defenders, CAN be mitigated by modifying the defender daemonset yaml to set `readOnlyRootFilesystem` to `false` (which will result in defender reporting fully healthy in console)
- `Failed to start log inspection for /var/log/*/*.log: failed to add watch to tracked file directory no such file or directory`: Twistlock is looking for specific logs to track, like Apache, MongoDB, and NGINX. We don't use these in Big Bang development, so they can be ignored.  You could mount `/var/log` as shared, but this would result in `monitoring/node-exporter` pods to error on startup.
- `Failed to initialize image client: 'overlay' is not supported over overlayfs: backing file system is unsupported for this graph driver`: This is a result of attempting to an overlay on `/var/lib`.  Mounting `/var/lib` from the host will get rid of this, but causes a problem with more than one defender connecting to the console.

Despite seeing these issues in logs/console reporting the defenders should be functioning sufficiently for baseline testing at this point and reporting on the cluster health in console.
