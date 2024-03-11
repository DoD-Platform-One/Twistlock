# twistlock

![Version: 0.15.0-bb.2](https://img.shields.io/badge/Version-0.15.0--bb.2-informational?style=flat-square) ![AppVersion: 32.01.128](https://img.shields.io/badge/AppVersion-32.01.128-informational?style=flat-square)

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
| domain | string | `"bigbang.dev"` | domain to use for virtual service |
| monitoring.enabled | bool | `false` | Toggle monitoring integration, only used if init job is enabled, creates required metrics user, serviceMonitor, networkPolicy, etc |
| monitoring.serviceMonitor.scheme | string | `""` |  |
| monitoring.serviceMonitor.tlsConfig | object | `{}` |  |
| sso | object | `{"cert":"","client_id":"","console_url":"","enabled":false,"groups":"","idp_url":"","issuer_uri":"","provider_name":"","provider_type":"shibboleth"}` | Configuration of Twistlock's SAML SSO capability.  This requires `init.enabled`=`true`, valid credentials, and a valid license. Refer to docs/KEYCLOAK.md for additional information. |
| sso.enabled | bool | `false` | Toggle SAML SSO |
| sso.client_id | string | `""` | SAML client ID |
| sso.provider_name | string | `""` | SAML Povider Alias (optional) |
| sso.provider_type | string | `"shibboleth"` | SAML Identity Provider. `shibboleth` is recommended by Twistlock support for Keycloak |
| sso.issuer_uri | string | `""` | Identity Provider url with path to realm, example: https://keycloak.bigbang.dev/auth/realms/baby-yoda |
| sso.idp_url | string | `""` | SAML Identity Provider SSO URL, example: https://keycloak.bigbang.dev/auth/realms/baby-yoda/protocol/saml" |
| sso.console_url | string | `""` | Console URL of the Twistlock app. Example: `https://twistlock.bigbang.dev` (optional) |
| sso.groups | string | `""` | Groups attribute (optional) |
| sso.cert | string | `""` | X.509 Certificate from Identity Provider (i.e. Keycloak). See docs/KEYCLOAK.md for format. Use the `|-` syntax for multiline string |
| istio.enabled | bool | `false` | Toggle istio integration |
| istio.hardened | object | `{"customAuthorizationPolicies":[],"enabled":false}` | Default twistlock peer authentication |
| istio.tempo.enabled | bool | `false` |  |
| istio.tempo.namespaces[0] | string | `"tempo"` |  |
| istio.tempo.principals[0] | string | `"cluster.local/ns/tempo/sa/tempo-tempo"` |  |
| istio.mtls.mode | string | `"STRICT"` | STRICT = Allow only mutual TLS traffic, PERMISSIVE = Allow both plain text and mutual TLS traffic |
| istio.console.enabled | bool | `true` | Toggle vs creation |
| istio.console.annotations | object | `{}` | Annotations for VS |
| istio.console.labels | object | `{}` | Labels for VS |
| istio.console.gateways | list | `["istio-system/main"]` | Gateways for VS |
| istio.console.hosts | list | `["twistlock.{{ .Values.domain }}"]` | Hosts for VS |
| networkPolicies.enabled | bool | `false` | Toggle network policies |
| networkPolicies.ingressLabels | object | `{"app":"istio-ingressgateway","istio":"ingressgateway"}` | Labels for ingress pods to allow traffic |
| networkPolicies.controlPlaneCidr | string | `"0.0.0.0/0"` | Control Plane CIDR to allow init job communication to the Kubernetes API.  Use `kubectl get endpoints kubernetes` to get the CIDR range needed for your cluster |
| networkPolicies.nodeCidr | string | `nil` | Node CIDR to allow defender to communicate with console.  Defaults to allowing "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" networks. use `kubectl get nodes -owide` and review the `INTERNAL-IP` column to derive CIDR range. Must be an IP CIDR range (x.x.x.x/x - ideally a /16 or /24 to include multiple IPs) |
| imagePullSecretName | string | `"private-registry"` | Defines the secret to use when pulling the container images |
| selinuxLabel | string | `"disable"` | Run Twistlock Console and Defender with a dedicated SELinux label. See https://docs.docker.com/engine/reference/run/#security-configuration |
| systemd | object | `{"enabled":false}` | systemd configuration |
| systemd.enabled | bool | `false` | option to install Twistlock as systemd service. true or false |
| console.dataRecovery | bool | `true` | Enables or Disables data recovery. Values: true or false. |
| console.image.repository | string | `"registry1.dso.mil/ironbank/twistlock/console/console"` | Full image name for console |
| console.image.tag | string | `"32.01.128"` | Full image tag for console |
| console.image.imagePullPolicy | string | `"IfNotPresent"` | Pull policy for console image |
| console.ports.managementHttp | int | `8081` | Enables the management HTTP listener. |
| console.ports.managementHttps | int | `8083` | Enables the management HTTPS listener. |
| console.ports.communication | int | `8084` | Sets the port for communication between the Defender(s) and the Console |
| console.securityContext | object | `{"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":2674,"runAsNonRoot":true,"runAsUser":2674}` | Sets the container security context for the console |
| console.persistence.size | string | `"100Gi"` | Size of Twistlock PVC |
| console.persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for Twistlock PVC |
| console.syslogAuditIntegration | object | `{"enabled":false}` | Enable syslog audit feature When integrating with BigBang, make sure to include an exception to Gatekeeper and/or Kyverno for Volume Types. |
| console.disableCgroupLimits | bool | `false` | Controls console container's resource constraints. Set to "true" to run without limits. See https://docs.docker.com/engine/reference/run/#runtime-constraints-on-resources |
| console.license | string | `""` | The license key to use.  If not specified, the license must be installed manually. |
| console.runAsRoot | bool | `false` | Run Twistlock Console processes as root (default false, twistlock user account). Values: true or false |
| console.credentials | object | `{"password":"change_this_password","username":"admin"}` | Required if init is enabled.  Admin account to use for configuration through API.  Will create account if Twistlock is a new install.  Otherwise, an existing account needs to be provided. |
| console.credentials.username | string | `"admin"` | Username of account |
| console.credentials.password | string | `"change_this_password"` | Password of account |
| console.additionalUsers | list | `[]` | Additional users to setup.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| console.updateUsers | bool | `false` | Toggles whether to update the `additionalUsers` if the user is already created (e.g. on upgrades).  This would overwrite the existing user configuration. |
| console.groups | list | `[]` | Additional users to setup.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| console.options.enabled | bool | `true` | Toggle setting all options in this section |
| console.options.network | object | `{"container":true,"host":true}` | Network monitoring options |
| console.options.network.container | bool | `true` | Toggle network monitoring of containers |
| console.options.network.host | bool | `true` | Toggle network monitoring of hosts |
| console.options.logging | bool | `true` | Toggle logging Prisma Cloud events to standard output |
| console.options.telemetry | bool | `false` | Toggle sending product usage data to Palo Alto Networks |
| console.volumeUpgrade | bool | `true` | This value should be enabled when upgrading from a version <=0.10.0-bb.1 in order to allow the console to run as non-root |
| console.trustedImages | object | `{"defaultEffect":"alert","enabled":true,"name":"BigBang-Trusted","registryMatches":["registry1.dso.mil/ironbank/*"]}` | Trusted images settings |
| console.trustedImages.enabled | bool | `true` | Toggle deployment and updating of trusted image settings |
| console.trustedImages.registryMatches | list | `["registry1.dso.mil/ironbank/*"]` | List of regex matches for images to trust |
| console.trustedImages.name | string | `"BigBang-Trusted"` | Name for the group/rule to display in console |
| console.trustedImages.defaultEffect | string | `"alert"` | Effect for images that do not match the trusted registry, can be "alert" or "block" |
| defender | object | `{"certCn":"","clusterName":"","collectLabels":true,"containerRuntime":"containerd","dockerListenerType":"","dockerSocket":"","enabled":true,"image":{"repository":"registry1.dso.mil/ironbank/twistlock/defender/defender","tag":"32.01.128"},"monitorServiceAccounts":true,"privileged":false,"proxy":{},"resources":{"limits":{"cpu":2,"memory":"2Gi"},"requests":{"cpu":4,"memory":"4Gi"}},"securityCapabilitiesAdd":["CHOWN","DAC_READ_SEARCH","SYSLOG"],"securityCapabilitiesDrop":["ALL"],"selinux":true,"tolerations":[],"uniqueHostName":false}` | Configuration of Twistlock's container defenders.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| defender.image | object | `{"repository":"registry1.dso.mil/ironbank/twistlock/defender/defender","tag":"32.01.128"}` | Image for Twistlock defender.  Leave blank to use twistlock official repo. |
| defender.image.repository | string | `"registry1.dso.mil/ironbank/twistlock/defender/defender"` | Repository and path for defender image |
| defender.image.tag | string | `"32.01.128"` | Image tag for defender |
| defender.clusterName | string | `""` | Name of cluster |
| defender.collectLabels | bool | `true` | Collect Deployment and Namespace labels |
| defender.containerRuntime | string | `"containerd"` | Set containerRuntime option for Defenders ("docker", "containerd", or "crio") |
| defender.dockerSocket | string | `""` | Path to Docker socket.  Leave blank to use /var/run/docker.sock |
| defender.tolerations | list | `[]` | List of tolerations to be added to the Defender DaemonSet retrieved during the init script |
| defender.securityCapabilitiesDrop | list | `["ALL"]` | Sets the container security context dropped capabilities for the defenders |
| defender.securityCapabilitiesAdd | list | `["CHOWN","DAC_READ_SEARCH","SYSLOG"]` | Sets the container security context added capabilities for the defenders |
| defender.dockerListenerType | string | `""` | Sets the type of the Docker listener (TCP or NONE) |
| defender.monitorServiceAccounts | bool | `true` | Monitor service accounts |
| defender.privileged | bool | `false` | Run as privileged.  If `selinux` is `true`, this automatically gets set to `false` |
| defender.proxy | object | `{}` | Proxy settings |
| defender.selinux | bool | `true` | Deploy with SELinux Policy |
| defender.uniqueHostName | bool | `false` | Assign globally unique names to hosts |
| policies | object | `{"compliance":{"alertThreshold":"medium","enabled":true,"templates":["DISA STIG","NIST SP 800-190"]},"enabled":true,"name":"Default","runtime":{"enabled":true},"vulnerabilities":{"alertThreshold":"medium","enabled":true}}` | Configures defender policies.  This requires `init.enabled`=`true`, valid credentials, and a valid license. |
| policies.enabled | bool | `true` | Toggles configuration of defender policies |
| policies.name | string | `"Default"` | Name to use as prefix to policy rules. NOTE: If you change the name after the initial deployment, you may end up with duplicate policy sets and need to manually cleanup old policies. |
| policies.vulnerabilities | object | `{"alertThreshold":"medium","enabled":true}` | Vulnerability policies |
| policies.vulnerabilities.enabled | bool | `true` | Toggle deployment and updating of vulnerability policies |
| policies.vulnerabilities.alertThreshold | string | `"medium"` | The minimum severity to alert on |
| policies.compliance | object | `{"alertThreshold":"medium","enabled":true,"templates":["DISA STIG","NIST SP 800-190"]}` | Compliance policies |
| policies.compliance.enabled | bool | `true` | Toggle deployment and updating of compliance policies |
| policies.compliance.templates | list | `["DISA STIG","NIST SP 800-190"]` | The policy templates to use.  Valid values are 'GDPR', 'DISA STIG', 'PCI', 'NIST SP 800-190', or 'HIPAA' |
| policies.compliance.alertThreshold | string | `"medium"` | If template does not apply, set policy to alert using this severity or higher.  Valid values are 'low', 'medium', 'high', or 'critical'. |
| policies.runtime | object | `{"enabled":true}` | Runtime policies |
| policies.runtime.enabled | bool | `true` | Toggle deployment and updating of runtime policies |
| init | object | `{"enabled":true,"image":{"imagePullPolicy":"IfNotPresent","repository":"registry1.dso.mil/ironbank/big-bang/base","tag":"2.1.0"},"resources":{"limits":{"cpu":0.5,"memory":"256Mi"},"requests":{"cpu":0.5,"memory":"256Mi"}}}` | Initialization job.  Sets up users, license, container defenders, default policies, and other settings. |
| init.enabled | bool | `true` | Toggles the initialization on or off |
| init.image | object | `{"imagePullPolicy":"IfNotPresent","repository":"registry1.dso.mil/ironbank/big-bang/base","tag":"2.1.0"}` | Initialization job image configuration |
| init.image.repository | string | `"registry1.dso.mil/ironbank/big-bang/base"` | Repository and path to initialization image.  Image must contain `jq` and `kubectl` |
| init.image.tag | string | `"2.1.0"` | Initialization image tag |
| init.image.imagePullPolicy | string | `"IfNotPresent"` | Initialization image pull policy |
| affinity | object | `{}` | affinity for console pod |
| nodeSelector | object | `{}` | nodeSelector for console pod |
| tolerations | list | `[]` | tolerations for console pod |
| annotations | object | `{}` | annotations for console pod |
| resources | object | `{"limits":{"cpu":"250m","memory":"3Gi"},"requests":{"cpu":"250m","memory":"3Gi"}}` | resources for console pod |
| openshift | bool | `false` | Toggle to setup special configuration for OpenShift clusters |
| bbtests.enabled | bool | `false` | Toggle bbtests on/off for CI/Dev |
| bbtests.scripts.image | string | `"registry1.dso.mil/ironbank/stedolan/jq:1.7"` | Image to use for script tests |
| bbtests.scripts.envs | object | `{"desired_version":"{{ .Values.console.image.tag }}","twistlock_host":"http://twistlock-console.twistlock.svc.cluster.local:8081"}` | Set envs for use in script tests |

## Contributing

Please see the [contributing guide](./CONTRIBUTING.md) if you are interested in contributing.
