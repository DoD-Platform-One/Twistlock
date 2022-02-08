# Twistlock on k3d

There are some special considerations for Twistlock on k3d that require both a special setup of your k3d cluster and special config of the Twistlock defenders.

By following the sections below to configure your cluster and the defenders you should end up with a Twistlock instance and defender functioning much like they would in a normal cluster (i.e. able to view all pods in the cluster, nodes, scan images, etc).

This document was written and tested against Twistlock 22.01.840, newer versions *may* need additional configuration but start with this as a baseline.

## k3d setup

Below is a k3d config that provides many of the necessary overrides for Twistlock, namely:
- Volume mounts of directories needed by Defenders
- Single server setup (due to shared docker sock and other volumes, only a single defender is possible on k3d)

```yaml
apiVersion: k3d.io/v1alpha3
kind: Simple
servers: 1
kubeAPI:
  hostPort: "6443"
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:*
      - arg: --disable=metrics-server
        nodeFilters:
          - server:*
  k3d:
    wait: true
volumes:
  - volume: /etc:/etc
    nodeFilters:
      - server:*
  - volume: /dev/log:/dev/log
    nodeFilters:
      - server:*
  - volume: /var/lib:/var/lib
    nodeFilters:
      - server:*
  - volume: /var/log:/var/log:shared
    nodeFilters:
      - server:*
  - volume: /var/run/docker.sock:/var/run/docker.sock
    nodeFilters:
      - server:*
  - volume: /run/systemd/private:/run/systemd/private
    nodeFilters:
      - server:*
ports:
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer
```

NOTE: this config should be modified to add any typical values you use in your normal dev environment (typically the TLS SAN k3s arg is the minimum to add).

## Twistlock Defender Config

For the Twistlock Defender config you will also want to override some of the defaults. The below settings seem to work best on k3d (numbered based on their setting number on the Manage -> Defenders -> Deploy page). If a config is not listed use the default:

3: `twistlock-console`

10: `/run/k3s/containerd/containderd.sock`

12: On

14: Off

15: `registry1.dso.mil/ironbank/twistlock/defender/defender:21.08.520` (update tag to same as console)

16: `private-registry`

17: SELinux ON, Privileged OFF, CRI ON, Containerized ON

NOTE: This config is not without some small issues, since we are working around some of the limitations of the dockerized cluster and volumes. You will see some errors in the logs of the defender, including:
- `failed to save iptables Twistlock defender completed with an error: exec: "iptables-save": executable file not found in $PATH exit status 1`: `iptables-save` is not in the defender pod, may be able to mount it in but not worth the effort
- `Failed to create firewall manager: lstat /proc/1/root/sys/fs/cgroup/memory/docker: no such file or directory`: This one is odd but essentially due to some of the hacks with how we configure the defenders they will fail to find the docker process file here
- `Failed to download feed /feeds/*.json - stop retry downloading due to an unexpected error: open /var/lib/twistlock/data/*.json: no such file or directory`: Not sure why this one happens but `/var/lib/twistlock` is a mounted path from the host, may occur due to reuse across multiple clusters
- `Failed to start runc proxy: listen unix /var/run/tw.runc.sock: bind: read-only file system`: runc socket does not exist on k3d nodes (another quirk of the hacky config)

Despite seeing these issues in logs/console reporting the defenders should be functioning at this point and reporting on the cluster health in console.
