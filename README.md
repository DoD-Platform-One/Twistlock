# Twistlock Documentation

# Table of Contents
- [Backup](docs/BACKUP.md)
- [Deployment](#deployment)
- [Elasticsearch Configuration](docs/ELASTIC.md)
- [Keycloak Integration](docs/KEYCLOAK.md)
- [Monitoring](docs/PROMETHEUS.md)
- [Node Affinity & Anti-Affinity with Twistlock](docs/AFFINITY.md)
- [Overview](docs/overview.md)
- [Prerequisites](#prerequisites)
- [Troubleshooting](docs/TROUBLESHOOTING.md)


## Prerequisites
* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* [Helm installed](https://helm.sh/docs/intro/install)

## Deployment
```
git clone https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock.git
cd twistlock
helm install twistlock chart
```
