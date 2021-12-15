# twistlock

![Version: 0.1.0-bb.0](https://img.shields.io/badge/Version-0.1.0--bb.0-informational?style=flat-square) ![AppVersion: 21.08.520](https://img.shields.io/badge/AppVersion-21.08.520-informational?style=flat-square)

## Learn More
* [Application Overview](docs/overview.md)
* [Other Documentation](docs/)

## Pre-Requisites

* Kubernetes Cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Helm installed

Install Helm

https://helm.sh/docs/intro/install/

## Deployment

* Clone down the repository
* cd into directory
```bash
helm install twistlock chart/
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| domain | string | `"bigbang.dev"` |  |
| monitoring.enabled | bool | `false` |  |
| istio.enabled | bool | `false` |  |
| istio.console.enabled | bool | `true` |  |
| istio.console.annotations | object | `{}` |  |
| istio.console.labels | object | `{}` |  |
| istio.console.gateways[0] | string | `"istio-system/main"` |  |
| istio.console.hosts[0] | string | `"twistlock.{{ .Values.domain }}"` |  |
| networkPolicies.enabled | bool | `false` |  |
| networkPolicies.ingressLabels.app | string | `"istio-ingressgateway"` |  |
| networkPolicies.ingressLabels.istio | string | `"ingressgateway"` |  |
| networkPolicies.nodeCidr | string | `nil` |  |
| imagePullSecrets | list | `[]` |  |
| console.image.repository | string | `"registry1.dso.mil/ironbank/twistlock/console/console"` |  |
| console.image.tag | string | `"21.08.520"` |  |
| console.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| console.persistence.size | string | `"100Gi"` |  |
| console.persistence.accessMode | string | `"ReadWriteOnce"` |  |
| console.syslogAuditIntegration.enabled | bool | `false` |  |
| affinity | object | `{}` |  |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| annotations | object | `{}` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.limits.cpu | string | `"250m"` |  |
| resources.requests.memory | string | `"512Mi"` |  |
| resources.requests.cpu | string | `"250m"` |  |
| openshift | bool | `false` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
