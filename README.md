# twistlock

![Version: 0.7.0-bb.0](https://img.shields.io/badge/Version-0.7.0--bb.0-informational?style=flat-square) ![AppVersion: 22.01.880](https://img.shields.io/badge/AppVersion-22.01.880-informational?style=flat-square)

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
| istio.mtls | object | `{"mode":"STRICT"}` | Default twistlock peer authentication |
| istio.mtls.mode | string | `"STRICT"` | STRICT = Allow only mutual TLS traffic, PERMISSIVE = Allow both plain text and mutual TLS traffic |
| istio.console.enabled | bool | `true` |  |
| istio.console.annotations | object | `{}` |  |
| istio.console.labels | object | `{}` |  |
| istio.console.gateways[0] | string | `"istio-system/main"` |  |
| istio.console.hosts[0] | string | `"twistlock.{{ .Values.domain }}"` |  |
| networkPolicies.enabled | bool | `false` |  |
| networkPolicies.ingressLabels.app | string | `"istio-ingressgateway"` |  |
| networkPolicies.ingressLabels.istio | string | `"ingressgateway"` |  |
| networkPolicies.controlPlaneCidr | string | `"0.0.0.0/0"` | Control Plane CIDR to allow init job communication to the Kubernetes API.  Use `kubectl get endpoints kubernetes` to get the CIDR range needed for your cluster |
| networkPolicies.nodeCidr | string | `nil` | Node CIDR to allow defender to communicate with console.  Defaults to allowing "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" networks. use `kubectl get nodes -owide` and review the `INTERNAL-IP` column to derive CIDR range. Must be an IP CIDR range (x.x.x.x/x - ideally a /16 or /24 to include multiple IPs) |
| imagePullSecrets | list | `[]` | Defines the secrets to use when pulling the container images NOTE: Only first entry in the list will be used for Defender deployment |
| console.image.repository | string | `"registry1.dso.mil/ironbank/twistlock/console/console"` |  |
| console.image.tag | string | `"22.01.880"` |  |
| console.image.imagePullPolicy | string | `"IfNotPresent"` |  |
| console.persistence.size | string | `"100Gi"` |  |
| console.persistence.accessMode | string | `"ReadWriteOnce"` |  |
| console.syslogAuditIntegration | object | `{"enabled":false}` | Enable syslog audit feature When integrating with BigBang, make sure to include an exception to Gatekeeper and/or Kyverno for Volume Types. |
| console.license | string | `""` | The license key to use.  If not specified, the license must be installed manually. |
| console.credentials | object | `{"password":"change_this_password","username":"admin"}` | Required if init is enabled.  Admin account to use for configuration through API.  Will create account if Twistlock is a new install.  Otherwise, an existing account needs to be provided. |
| console.credentials.username | string | `"admin"` | Username of account |
| console.credentials.password | string | `"change_this_password"` | Password of account |
| console.additionalUsers | list | `[]` | Additional users to setup.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| console.updateUsers | bool | `false` | Toggles whether to update the `additionalUsers` if the user is already created (e.g. on upgrades).  This would overwrite the existing user configuration. |
| console.options.enabled | bool | `true` | Toggle setting all options in this section |
| console.options.network | object | `{"container":true,"host":true}` | Network monitoring options |
| console.options.network.container | bool | `true` | Toggle network monitoring of containers |
| console.options.network.host | bool | `true` | Toggle network monitoring of hosts |
| console.options.logging | bool | `true` | Toggle logging Prisma Cloud events to standard output |
| console.options.telemetry | bool | `false` | Toggle sending product usage data to Palo Alto Networks |
| defender | object | `{"clusterName":"","collectLabels":true,"cri":true,"dockerSocket":"","enabled":true,"image":{"repository":"registry1.dso.mil/ironbank/twistlock/defender/defender","tag":"22.01.880"},"monitorServiceAccounts":true,"privileged":false,"proxy":{},"selinux":true,"uniqueHostName":false}` | Configuration of Twistlock's container defenders.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| defender.image | object | `{"repository":"registry1.dso.mil/ironbank/twistlock/defender/defender","tag":"22.01.880"}` | Image for Twistlock defender.  Leave blank to use twistlock official repo. |
| defender.image.repository | string | `"registry1.dso.mil/ironbank/twistlock/defender/defender"` | Repository and path for defender image |
| defender.image.tag | string | `"22.01.880"` | Image tag for defender |
| defender.clusterName | string | `""` | Name of cluster |
| defender.collectLabels | bool | `true` | Collect Deployment and Namespace labels |
| defender.cri | bool | `true` | Use Container Runtime Interface (CRI) instead of Docker |
| defender.dockerSocket | string | `""` | Path to Docker socket.  Leave blank to use /var/run/docker.sock |
| defender.monitorServiceAccounts | bool | `true` | Monitor service accounts |
| defender.privileged | bool | `false` | Run as privileged.  If `selinux` is `true`, this automatically gets set to `false` |
| defender.proxy | object | `{}` | Proxy settings |
| defender.selinux | bool | `true` | Deploy with SELinux Policy |
| defender.uniqueHostName | bool | `false` | Assign globally unique names to hosts |
| policies | object | `{"compliance":{"alertThreshold":"medium","enabled":true,"templates":["DISA STIG","NIST SP 800-190"]},"enabled":true,"name":"Default","runtime":{"enabled":true},"vulnerabilities":{"alertThreshold":"medium","enabled":true}}` | Configures defender policies.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| policies.enabled | bool | `true` | Toggles configuration of defender policies |
| policies.name | string | `"Default"` | Name to use as prefix to policy rules. NOTE: If you change the name after the initial deployment, you may end up with duplicate policy sets and need to manually cleanup old policies. |
| policies.vulnerabilities | object | `{"alertThreshold":"medium","enabled":true}` | Vulnerabilitiy policies |
| policies.vulnerabilities.enabled | bool | `true` | Toggle deployment and updating of vulnerability policies |
| policies.vulnerabilities.alertThreshold | string | `"medium"` | The minimum severity to alert on |
| policies.compliance | object | `{"alertThreshold":"medium","enabled":true,"templates":["DISA STIG","NIST SP 800-190"]}` | Compliance policies |
| policies.compliance.enabled | bool | `true` | Toggle deployment and updating of compliance policies |
| policies.compliance.templates | list | `["DISA STIG","NIST SP 800-190"]` | The policy templates to use.  Valid values are 'GDPR', 'DISA STIG', 'PCI', 'NIST SP 800-190', or 'HIPAA' |
| policies.compliance.alertThreshold | string | `"medium"` | If template does not apply, set policy to alert using this severity or higher.  Valid values are 'low', 'medium', 'high', or 'critical'. |
| policies.runtime.enabled | bool | `true` | Toggle deployment and updating of runtime policies |
| init | object | `{"enabled":true,"image":{"imagePullPolicy":"IfNotPresent","repository":"registry1.dso.mil/ironbank/big-bang/base","tag":"1.1.0"}}` | Initialization job.  Sets up users, license, container defenders, default policies, and other settings. |
| init.enabled | bool | `true` | Toggles the initialization on or off |
| init.image | object | `{"imagePullPolicy":"IfNotPresent","repository":"registry1.dso.mil/ironbank/big-bang/base","tag":"1.1.0"}` | Initializtion job image configuration |
| init.image.repository | string | `"registry1.dso.mil/ironbank/big-bang/base"` | Repository and path to initialization image.  Image must contain `jq` and `kubectl` |
| init.image.tag | string | `"1.1.0"` | Initialization image tag |
| init.image.imagePullPolicy | string | `"IfNotPresent"` | Initialization image pull policy |
| affinity | object | `{}` |  |
| nodeSelector | object | `{}` |  |
| tolerations | list | `[]` |  |
| annotations | object | `{}` |  |
| resources.limits.memory | string | `"1Gi"` |  |
| resources.limits.cpu | string | `"250m"` |  |
| resources.requests.memory | string | `"512Mi"` |  |
| resources.requests.cpu | string | `"250m"` |  |
| openshift | bool | `false` | Toggle to setup special configuration for OpenShift clusters |
| bbtests.enabled | bool | `false` |  |
| bbtests.cypress.artifacts | bool | `true` |  |
| bbtests.cypress.envs.cypress_baseUrl | string | `"http://{{ .Release.Name }}-console.{{ .Release.Namespace }}.svc.cluster.local:8081"` |  |
| bbtests.scripts.image | string | `"registry1.dso.mil/ironbank/stedolan/jq:1.6"` |  |
| bbtests.scripts.envs.twistlock_host | string | `"https://{{ .Release.Name }}-console.{{ .Release.Namespace }}.svc.cluster.local:8083"` |  |
| bbtests.scripts.envs.desired_version | string | `"{{ .Values.console.image.tag }}"` |  |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
