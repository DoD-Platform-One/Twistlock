# Twistlock Initialization

## Overview

The initialization job will use the Twistlock API to perform various deployment and configuration tasks that cannot be achieved declaratively.  These tasks include:

- Setting up an initial administrator user
- Installing and validating a license
- Configuring and deploying Twistlock Defenders on each node
- Setting up additional Twistlock users
- Creating vulnerability policies to alert on a severity threshold
- Creating compliance policies that align with templates (e.g. DISA STIG, NIST)
- Creating runtime policies
- Enabling stdout logging
- Turning off telemetry

## Prerequisites

In order to utilize the init job, the following must be configured in values.yaml:

```yaml
# Pull secret for Iron Bank images
imagePullSecrets:
- name: insert_secret_name_here

console:
  # Credentials for admin account
  # If this is a new install, the account will be created
  credentials:
    username: insert_user_here
    password: insert_pass_here

init:
  enabled: true
```

> Care should be taken to securely store the credentials in an encrypted format (e.g. key store, SOPS)

Additionally, a valid license is required to interact with the API.  This can be provided in `console.license` or manually installed.

## SSO

By setting `sso.enabled: true`, you can configure SAML SSO without manually logging into the console. The provider type `shibboleth` is set as default since this is recommended by Twistlock support. For SAML SSO to work with Twistlock, local Twistlock users have to be created after configuring SSO via the console (`Manage -> Authentication -> Users`). Click the `Add User` button to create a Twistlock user with the same name as the Keycloak user name and specify `SAML` as the `Authentication Method`. With the init script, SAML users can automatically be created by setting `console.additionalUsers`.

Example:
```yaml
additionalUsers:
  - username: "test"
    role: "devOps"
    authType: "saml"
```

## Users

By setting `console.additionalUsers`, you can setup more users in Twistlock with various authentication types and roles.  Refer to [Prisma Cloud's RBAC Guide](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-reference-architecture-compute/rbac/access_twistlock) for more information.

Setting `console.updateUsers: true` will force the init job to update the user's password, role, and auth type, regardless of changes made in the console.  This setting can also be set to `false` to only setup the user if it does not currently exist.

## Defenders

By setting `defender.enabled: true`, Twistlock defender containers will be deployed on every node using a Daemonset.  It is recommended that you set `defender.clusterName` to help identify the defenders.

> On Kubernetes systems that do not use the Docker daemon, you will need to change `defender.dockerSocket`.  For example, with `k3s`, this is set to `/run/k3s/containerd/containerd.sock`

After successful deployment, you should see  `twistlock-defender-ds` pods running in your cluster.

Refer to the [Prisma Cloud Defender Documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/22-01/prisma-cloud-compute-edition-admin/install/install_defender/install_cluster_container_defender) for more information on installing Defenders.

## Policies

By setting `policies.enabled: true`, Defender policies will be configured.  This includes setting up Vulnerability, Compliance, and Runtime policies for Containers, Hosts/VMs, and Functions (Serverless).

It is recommended that you set `policies.name` as this will be used to identify the policies created by the init job.

> Policy settings were based on [Cyber Recommended Configurations](https://repo1.dso.mil/platform-one/cyber/prisma_cloud_config).

### Vulnerabilities

Setting `policies.vulnerabilities.enabled: true` will setup the vulnerability policies.  If enabled, the following Rules will be added to Twistlock:

- Images > Deployed
- Hosts > Running hosts
- Hosts > VM images
- Functions > Functions

Each rule will force the following settings:

- Rule name: set to `policies.name`
- Alert threshold: set to `policies.vulnerabilities.alertThreshold`
- Apply rule only when vendor fixes are available: true

All other settings will be preserved.

For more information on Vulnerabilities, refer to [Prisma Cloud's Vulnerability Management](https://docs.paloaltonetworks.com/prisma/prisma-cloud/22-01/prisma-cloud-compute-edition-admin/vulnerability_management).

### Compliance

Setting `policies.compliance.enabled: true` will setup the compliance policies.  If enabled, the following Rules will be added to Twistlock:

- Containers and images > Deployed
- Hosts > Running hosts
- Hosts > VM images
- Functions > Functions

Each rule will force the following settings:

- Rule name: set to combination of `policies.name` and `policies.compliance.templates`
  - Each template set will have its own rule
- Compliance actions:
  - If a control is in the specified `policies.compliance.templates` set, the action is set to a minimum of `Alert`
  - If there are no controls matching the compliance set, controls at or above `policies.compliance.alertThreshold` will have their action set to a minimum of `Alert`
  - If an action is already set to `Block`, it will not be changed.
  - Changes are not made to controls that are outside the compliance set

All other settings will be preserved.

Refer to [Prisma Cloud's Compliance Documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/22-01/prisma-cloud-compute-edition-admin/compliance) for further details.

### Runtime

Setting `policies.runtime.enabled: true` will setup the runtime policies.  If enabled, the following Rules will be added to Twistlock:

- Container policy
- Host policy
- Serverless policy

#### Container Runtime

The container policy runtime rule will force the following settings:

- Rule name: set to `policies.name`
- Anti-malware
  - Prisma Cloud advanced threat protection: On
  - Kubernetes attacks: On
  - Suspicious queries to cloud provider APIs: On
- Processes
  - Processes started from modified binaries: On
  - Crypto miners: On
  - Reverse shell attacks: On
  - Processes used for lateral movement: On
  - Child processes started by unrecognized parents: On
  - Processes started with SUID: On
- Networking
  - Networking activity from modified binaries: On
  - Port scanning: On
  - Raw sockets: On
- File System
  - Change to binaries and certificates: On
  - Detection of encrypted/packed binaries: On
  - Changes to SSH and admin account configuration files: On
  - Binaries with suspicious ELF headers: On
- Custom Rules
  - Detect privileged management tools starting in a container: Selected
  - Detect usage of common data exfiltration ports: Selected
  - Detect access to common crypto miner pool ports: Selected
  - Detect access to cloud platform metadata APIs (AWS/GCP/Azure): Selected
  - Detect attempts to tamper with bash shell configuration: Selected
  - Detect writes to linux password and shadow files: Selected
  - Detect file writes under /etc folder (Host): Selected
  - Detect file writes under /etc folder (Container): Selected
  - Detect an execution of cron app: Selected
  - A database server app spawned a new process other than itself: Selected
  - Detect launching of suspicious networking scanning tool: Selected
  - Detect launching of suspicious networking tool: Selected
  - Detect user deletion: Selected
  - Detect user modification: Selected
  - Detect user creation: Selected

> Each section's "Enabled" setting is not forced on.  But, is on by default.

All other settings will be preserved.

#### Host Runtime

The host policy runtime rule will force the following settings:

- Rule name: set to `policies.name`
- Anti-malware
  - Deny process by category: Exploit tools, Persistent access, Password attacks, Sniffing and spoofing
  > If a tool is added to the list it will be preserved
- Log inspection
  - `/var/log/auth.log` and regex
  - `/var/log/nginx/error.log` and regex
  - `/var/log/mongodb/mongod.log` and regex
  - `/var/log/postgresql/postgresql-*.log` and regex
  - `/var/log/mysql.err` and regex
  - `/var/log/apache2/error.log` and regex
- Activities
  - Docker commands: On
  - Include read only Docker events: Checked
  - New sessions spawned by sshd: On
  - Commands run with sudo or su: On
  - Track SSH events: On
- Custom Rules
  - Detect privileged management tools starting in a container: Selected
  - Detect usage of common data exfiltration ports: Selected
  - Detect access to common crypto miner pool ports: Selected
  - Detect access to cloud platform metadata APIs (AWS/GCP/Azure): Selected
  - Detect attempts to tamper with bash shell configuration: Selected
  - Detect writes to linux password and shadow files: Selected
  - Detect file writes under /etc folder (Host): Selected
  - Detect file writes under /etc folder (Container): Selected
  - Detect an execution of cron app: Selected
  - A database server app spawned a new process other than itself: Selected
  - Detect launching of suspicious networking scanning tool: Selected
  - Detect launching of suspicious networking tool: Selected
  - Detect user deletion: Selected
  - Detect user modification: Selected
  - Detect user creation: Selected

> Each section's "Enabled" setting is not forced on.  But, is on by default.

All other settings will be preserved.

#### Serverless Runtime

The serverless policy runtime rule will force the following settings:

- Rule name: set to `policies.name`
- General
  - Prisma Cloud advanced threat protection: On
- Processes
  - Crypto miners: On
  - Block all processes except main process: On
- Networking
  - Raw sockets: On

> Each section's "Enabled" setting is not forced on.  But, is on by default.

All other settings will be preserved

Additional runtime details can be found in [Prisma Cloud's Runtime Defense Documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/22-01/prisma-cloud-compute-edition-admin/runtime_defense).

## Misc Settings

TBD

## Development Notes

Twistlock's console deployment does not have declarative settings for accounts, defenders, policies, miscellaneous settings, etc.

### Operator

One solution is to use the [Twistlock Operator](https://github.com/PaloAltoNetworks/prisma-cloud-compute-operator).  However, [during evaluation](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues/704), several issues were found that make the operator unfit for Big Bang use:

- Pre-deployment, a [secret](https://github.com/PaloAltoNetworks/prisma-cloud-compute-operator/blob/main/docs/Kubernetes/pcc-credentials.yaml) with an access token is required.  But, the token is generated by the console when it is created.  This means you need to deploy the console, get the token, then deploy the operator.
- [HTTP port of the console is not exposed](https://github.com/PaloAltoNetworks/prisma-cloud-compute-operator/issues/13).  We would need to use pass-through TLS for Istio to accommodate HTTPS.
- The operator does not have a Helm chart.  Instead, it requires a series of [deployment steps](https://github.com/PaloAltoNetworks/prisma-cloud-compute-operator/blob/main/docs/Kubernetes/kubernetes.md).
- There are no accommodations in the operator for additional configuration like
  - Policy rules
  - Additional user accounts
  - Logging to stdout

### API

The [Twistlock API](https://cdn.twistlock.com/docs/api/twistlock_api.html) provides an extensive set of options for configuration. Behind the console GUI, the API is used to perform the deployments and configuration.  Although writing and maintaining a shell script is not ideal, it is the best option available for declarative configuration.

### Implementation

The Helm chart values for initialization are stored in a few secrets that get mounted into the initialization container.  In addition, the scripts are stored in a configmap and volume mounted.

The bash scripts heavily use `curl` and `jq` to interact with the API.  The main script is `twistlock-init.sh` and will call the other scripts based on whether each one is enabled.  At a minimum, the credentials are used to retrieve an auth token and the license is verified to be current.
