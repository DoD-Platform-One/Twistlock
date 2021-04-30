# Twistlock

Note: Twistlock was acquired by Paolo Alto Networks and has been rebranded as [Prisma Cloud](https://blog.paloaltonetworks.com/2019/11/cloud-prisma-cloud-compute-edition/). The names are used interchangeably in these documents.

## Licensing information should not be in this repo

## Twistlock under DSOP

The Twistlock Platform provides vulnerability management and compliance across the application lifecycle by scanning images and serverless functions to prevent security and compliance issues from progressing through the development pipeline, and continuously monitoring all registries and environments.

This installation follows the Twistlock documented guidance.  Twistlock documentation can be found at:
<https://docs.paloaltonetworks.com/prisma/prisma-cloud/20-04/prisma-cloud-compute-edition-admin/welcome.html>

The Twistlock Console is deployed as a part of the gitops.  Once deployed the process of setting up daemonsets is currently a manual process.  For this installation the following information is needed:

### Application overview

Twistlock monitors Docker for container deployment and Kubernetes for container orchestration, along with other cloud platforms. Twistlock provides continuous monitoring of containers, in addition to multi-tenancy which allows the user to defend, monitor, and manage multiple projects at once. Twistlock allows for adding firewall rules to individual applications, detecting and blocking anomalies, analyzing events, monitoring memory space, monitoring container compliance, and providing customizable access controls. Continuous Integration provides developers with the status of vulnerabilities found with each build they run, as opposed to running a different tool to see the status of each builds’ CVEs and their severity. ACAS has capability to scan entire servers, however, does not provide the container security Twistlock offers. Container security is a leading issue right now and Twistlock provides the tools necessary to address those.

For more information see the [official documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/technology_overviews.html).

### Deployment

This package chart is delpoyed as part of the BigBang Umbrella chart.

### Initial Configuration

The initial login will ask you to create an admin user, and set license key. 

### Install Defender from the Console UI

The Daemonset generator is located in the Twistlock Console Under Manage -> Defenders -> Deploy -> Daemonset
Select the following options:

Choose the name that clients and Defenders use to access this Console - twistlock-console
Choose the port number that Defenders use to access this Console -  8084
Choose the cluster orchestrator - kubernetes
NodeSelector - leave this blank
Monitor service accounts - On
Monitor Istio - On
Collect Deployment and Namespace labels - On
Use the official Twistlock registry - On (if possible)
Deploy Defenders with SELinux Policy - Off
Run Defenders as privileged - On
Nodes use Container Runtime Interface (CRI), not Docker - On
Nodes runs inside containerized environment - Off

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

For more information see the [official documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/authentication.html).
#### Collections

Collections can be used to partition views, which provide a convenient way to browse data from related resources. Collections can also be used to optionally enforce which views specific users and groups can see. They can control access to data on a need-to-know bases or assigned collections. While a single Console manages data from Defenders spread across all hosts, collections let you segment that data into different views based on attributes. Collections are created with pattern matching expressions that are evaluated against attributes such as image name, container name, labels, and namespace.  Selecting a collection reduces the scope displayed in Console to just the relevant components.

#### Assigned Collections

When admins create users and groups, they must grant access to at least one collection. By default, users and groups are assigned access to a set called All collections, which contains all objects in the system. All collections is effectively the same as manually creating a collection with a wildcard (*) for every resource type.
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

## Additional Links

* [How Twistlock Secures the Full Application Lifecycle](https://www.youtube.com/watch?v=KunpU9urBaA)
* [Twistlock Architecture](https://www.youtube.com/watch?v=Ugxwq43Fy0w)
* [Prisma Cloud: Cloud Security Posture Management Demo](https://www.youtube.com/watch?v=NsEZK5fyloE)
