# Twistlock

Note: Twistlock was acquired by Palo Alto Networks and has been rebranded as [Prisma Cloud](https://blog.paloaltonetworks.com/2019/11/cloud-prisma-cloud-compute-edition/). The names are used interchangeably in these documents.

## Twistlock under DSOP

The Twistlock Platform provides vulnerability management and compliance across the application lifecycle by scanning images and serverless functions to prevent security and compliance issues from progressing through the development pipeline, and continuously monitoring all registries and environments.

This installation follows the Twistlock documented guidance.  Twistlock documentation can be found at:
<https://docs.prismacloud.io/en/compute-edition/34>

The Twistlock Console is deployed as a part of the gitops.

## Platform One Prisma Cloud Compute Basic Configuration

Platform One has a minimum configuration required as a result of security findings and compliance.  The basic configuration for Prisma Cloud Compute version 21.04.412 can be found [here](https://repo1.dso.mil/platform-one/cyber/prisma_cloud_config/-/tree/configs-v21.04.412).  This security configuration is not automated nor in gitops due to limitations with the Prisma Cloud Compute product and the Security Operations team is actively working with the Palo Alto Network engineer and product team on the way forward.  The P1 Security Operations team is in the process of moving this to a public repo, in the mean time @jweiler or @aaron.ruse can grant access or answer any questions.


## Application overview

Twistlock monitors Docker for container deployment and Kubernetes for container orchestration, along with other cloud platforms. Twistlock provides continuous monitoring of containers, in addition to multi-tenancy which allows the user to defend, monitor, and manage multiple projects at once. Twistlock allows for adding firewall rules to individual applications, detecting and blocking anomalies, analyzing events, monitoring memory space, monitoring container compliance, and providing customizable access controls. Continuous Integration provides developers with the status of vulnerabilities found with each build they run, as opposed to running a different tool to see the status of each builds’ CVEs and their severity. ACAS has capability to scan entire servers, however, does not provide the container security Twistlock offers. Container security is a leading issue right now and Twistlock provides the tools necessary to address those.

For more information see the [official documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/technology_overviews.html).

### Deployment

This package chart is deployed as part of the BigBang Umbrella chart. When deploying on k3d make sure to follow the configuration provided in [k3d docs](./k3d.md) for assistance in getting up and running.

### Initial Configuration

The initial login will ask you to create an admin user, and set license key.

### Install Defender from the Console UI

The Defender Daemonset is now created automatically by the chart's init job.

### Daily Use

Runtime Defense provides predictive and threat based active protection for running containers. Runtime defense serves the purpose of detecting suspicious activity or the presence of malware within a container. Predictive protection detects anomalous behavior. The Defend - Runtime tab allows for machine learning, where models are built with known good activity so anomalous behavior can be identified. Container runtime protection creates models for images and host runtime protection creates models for processes. Runtime rules are applied to containers and hosts in addition to the autonomous model already created. The rules provide further administrative control to explicitly allow or block an object. The Monitor - Runtime tab displays the container and host models created, along with the container and host audits that list any abnormal behavior happening with a container or image. Using Twistlock Runtime Defense enables security staff to quickly identify and isolate suspicious activity, launch an investigation, and remediate the vulnerability.

#### Access

Twistlock is configured to use SAML and map groups from keycloak to roles within Twistlock.

The roles are as listed:

- Administrator
  - Can manage all aspects of Twistlock installation
  - Full read-write access to all Twistlock settings and data
  - Create and update security policies
  - Create and update access control policies
  - Create and update the list of users and groups that can access Twistlock
  - Assign roles to users and groups
  - Designated for members of Twistlock security administrators team
- Operator
  - Can create and update all Twistlock settings
  - View audit data
  - Manage the rules that define the policies
  - Designated for members of Twistlock security operations team
- Defender Manager
  - Can install, manage, and remove Defenders from environment
  - Manage hosts that Twistlock protects   - Read-only access to settings and log files
  - Designated for members of Twistlock DevOps team
- Auditor
  - Read-only access to all Twistlock data, settings, and logs
  - Designated for members of Twistlock compliance team
- DevOps User
  - Read-only access to all tabs under Monitor > Vulnerabilities
  - Access to Manage > Collections to group resources and organize environment
  - Designated for members of Twistlock DevOps team
- Access User
  - Can run Docker client commands on the hosts that are protected by Defender
  - Designated for members of the Twistlock engineering team
- CI User
  - Can only run the plugin
  - Has no other access to configure Twistlock or view data
  - Minimal amount of access required to run the plugins

For more information see the [official documentation](https://docs.prismacloud.io/en/compute-edition/34/admin-guide/authentication/authentication).

#### Collections

Collections can be used to partition views, which provide a convenient way to browse data from related resources. Collections can also be used to optionally enforce which views specific users and groups can see. They can control access to data on a need-to-know bases or assigned collections. While a single Console manages data from Defenders spread across all hosts, collections let you segment that data into different views based on attributes. Collections are created with pattern matching expressions that are evaluated against attributes such as image name, container name, labels, and namespace.  Selecting a collection reduces the scope displayed in Console to just the relevant components.

#### Assigned Collections

When admins create users and groups, they must grant access to at least one collection. By default, users and groups are assigned access to a set called All collections, which contains all objects in the system. All collections is effectively the same as manually creating a collection with a wildcard (`*`) for every resource type.
Users with admin or operator roles can always see all resources in the system. They can also see all collections, and utilize them to filter views. When creating users or groups with the admin or operator role, there is no option for assigning collections.

Collections cannot be deleted as long as they’ve been assigned to users or groups. This enforcement mechanism ensures that users and groups are never left stateless. Click on a specific collection to see who is using them.

Changes to a user or group’s assigned collections only take affect after users re-login.
Creating Collections Procedure

- Manage > Collections
- Add Collection
- Create a new collection
- Add name to collection
- Specify a filter
- Save
Note: The collection selects all images with specified image filter in the specified namespace, based on what you choose as your filters. You cannot have collections that specify both containers and images. A wildcard must be in one of the fields, of the collection won’t be applied correctly. If you want to create collections that apply to both a container and an image, then this must be done through two separate collections. Filtering on both collections at the same time will yield the desired result.

#### Assigning Collection Procedure

- Ensure one or more collections are created
- Manage > Authentication > {Users | Groups}
- Add users or Add group
- Selected Auditor or DevOps User role
- Within permissions, select one or more collections
Note: If left unspecified, default is All Collections

Selecting Collection Procedure

- Navigate to Monitor section
- In collections drop-down, select a collection
- This displays only images containing the filters specified
- Multiple collections can be selected

The Collections column shows to which collection a resource belongs. The color assigned to a collection distinguishes objects that belong to specific collections. This is useful when multiple collections are displayed simultaneously. Collections can also be assigned arbitrary text tags to make it easier for users to associate other metadata with a collection.

## Granting Egress to Blocked Services

When Istio hardening is enabled through the settings `istio.enabled` and `istio.hardened.enabled`, a sidecar is injected into the twistlock namespace. This sidecar limits network traffic to 'REGISTRY_ONLY', effectively blocking access to external services.

> **Note:** Access to external services will be blocked.

This restriction commonly affects cloud provider services and secret stores configured in the Twistlock UI. To resolve this, you'll need to identify the hosts blocked by Istio and add a `customServiceEntry` for each one to your Big Bang `values.yaml` file.

### Discovering Blocked Hosts

To find out which hosts are being blocked, inspect the `istio-proxy` logs from the Twistlock pod using the following commands:

```bash
export SOURCE_POD=$(kubectl -n twistlock get pod -l name=twistlock-console -o jsonpath={.items..metadata.name})
kubectl -n twistlock logs "$SOURCE_POD" -c istio-proxy | grep -i "BlackHoleCluster"
```

Here is an example of a `customServiceEntry` that can be added to your Big Bang `values.yaml`
```yaml
istio:
  enabled: true
  hardened:
    enabled: true
    customServiceEntries:
     - name: "allow-amazonaws"
       enabled: true
       spec:
         hosts:
           - "cloudfront.amazonaws.com"
           - "ec2.us-gov-east-1.amazonaws.com"
           - "ec2.us-gov-west-1.amazonaws.com"
           - "lambda.us-gov-west-1.amazonaws.com"
           - "secretsmanager.us-gov-east-1.amazonaws.com"
           - "sts.amazonaws.com"
           - "sts.us-gov-east-1.amazonaws.com"
         location: MESH_EXTERNAL
         exportTo:
         - "."
         ports:
         - name: https
           number: 443
           protocol: TLS
         resolution: DNS
```

## Additional Links

* [How Twistlock Secures the Full Application Lifecycle](https://www.youtube.com/watch?v=KunpU9urBaA)
* [Twistlock Architecture](https://www.youtube.com/watch?v=Ugxwq43Fy0w)
* [Prisma Cloud: Cloud Security Posture Management Demo](https://www.youtube.com/watch?v=NsEZK5fyloE)
