# Twistlock

## Licensing informaiton should not be in this repo

## Twistlock under DSOP

The Twistlock Platform provides vulnerability management and compliance across the application lifecycle by scanning images and serverless functions to prevent security and compliance issues from progressing through the development pipeline, and continuously monitoring all registries and environments.

This installation follows the Twistlock documented guidance.  Twistlock documentation can be found at:
<https://docs.paloaltonetworks.com/prisma/prisma-cloud/20-04/prisma-cloud-compute-edition-admin/welcome.html>

The Twistlock Console is deployed as a part of the gitops.  Once deployed the process of setting up daemonsets is currently a manual process.  For this installation the following information is needed:

### Prerequisites

* Kubernetes cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Elasticsearch and Kibana deployed to Kubernetes namespace

Install kubectl

```
brew install kubectl
```

Install kustomize
```
brew install kustomize
```
### Deployment

Clone repository

```
git clone https://repo1.dsop.io/platform-one/apps/twistlock.git
cd twstlock
```
Apply kustomized manifest
```
kubectl -k ./
```

### Next steps

The application needs a administrator, the license file needs to be installed, then a defender.yaml needs to be generated and deployed. This has been consolidated in a script called twistlock_setup.sh.

The Variables required are as follows:
```
$ //Environment 
$ ADMIN_USER=Administrator
$ ADMIN_PASSWORD=< my password>
$ TWISTLOCK_EXTERNAL_ROUTE=twistlock.fences.dsop.io
$ LICENSE_KEY=
$ TOKEN=<Generated Bearer token Manage/Authentication/User Certificates>
```
This process requires kubectl to be installed and able to communicate with the DSOP cluster.

#### Add an Administrator

Initially there is no users associated with twistlock console.  Go to the external URL and add an Administrator account and a password.  Alternatively, run the following script:

```
//Add Administrator
if ! curl -k -H 'Content-Type: application/json' -X POST \
     -d "{\"username\": \"$ADMIN_USER\", \"password\": \"$ADMIN_PASSWORD\"}" \
     https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/signup; then

    echo "Error creating Twistlock Console user $ADMIN_USER"
    exit 1
fi
```

#### Install the license
The License can be added directly from the TWISTLOCK_EXTERNAL_ROUTE.  When first logging in the admin user will be prompted for a license.  The following  script will install the license:

```
//License
if ! curl -k \
  -u $ADMIN_USER:$ADMIN_PASSWORD \
  -H 'Content-Type: application/json' \
  -X POST \
  -d "{\"key\": \"$LICENSE_KEY\"}" \
  https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/settings/license; then 

    echo "Error uploading Twistlock license to console"
    exit 1
fi
```
Notes: curl has some difficulties with special charicters.  During the initial setup using a password without special cahricters is recommended.  This password needs to be changed to a complex password or the account removed when keycloak is integrated. 

#### Install Defender with Twistcli 

Defender can be installde from console, script or by command line.  The twistlock CLI is provided as a part of the installation.  This can be found in the Manage/System/Download.  After download ensure the file is made executable.
```
$ chmod +x twistcli
```
The "Bearer" token can be found in the twistlock application Manage/Authorization/User Certificates.  Alternatively, run the following commands
```
//Windows twistcli:

curl --progress-bar -L -k --header "authorization: Bearer $TOKEN" https://twistlock.fences.dsop.io/api/v1/util/windows/twistcli.exe > twistcli.exe;
```
```
Linux twistcli:

curl --progress-bar -L -k --header "authorization: Bearer $TOKEN" https://twistlock.fences.dsop.io/api/v1/util/twistcli > twistcli; chmod a+x twistcli;
```
```
Mac OS twistcli:

curl --progress-bar -L -k --header "authorization: Bearer TOKEN" https://twistlock.fences.dsop.io/api/v1/util/osx/twistcli > twistcli; chmod a+x twistcli;
```

#### Install Defender

1) Download Daemonset

The following command can be authenticated by TOKEN or Username/Password.
```
./twistcli defender export kubernetes --namespace twistlock --privileged --cri --monitor-service-accounts --monitor-istio --user $ADMIN_USER --password $ADMIN_PASSWORD --address https://$TWISTLOCK_EXTERNAL_ROUTE --cluster-address twistlock-console:8084
```
#####Download the daemonset.yaml.  The default Image is set to the Prisma server.  The image should be hardened.   To pull images from Platform 1.  The image URL needs to be changed:
##### Image: registry.dsop.io/platform-one/apps/twistlock/defender:20.04.163_ib
Note:  The Console and Defender must use the same version.  If your deploymnet is using 20.04.169 then edit the image accordingly.

2) Install Defender
```
kubectl apply -f defender.yaml
```
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

### Elasticsearch configuration
Before running the configuration, be sure to have Defender installed.
Follow the steps in either 'Install Defender' or 'Install Defender with Twistcli'

create an index pattern for fluentd if not already created
```
logstash-*
```
Build filter for twistlock namespace
```
{
  "query": {
    "match_phrase": {
      "kubernetes.namespace_name": "twistlock"
    }
  }
}
```

There should be 4 pods in the twistlock namespace
```
kubectl get pods -n twistlock
NAME                                READY   STATUS    RESTARTS   AGE
twistlock-console-7d77c954d-lnjxp   1/1     Running   0          3h13m
twistlock-defender-ds-442zh         1/1     Running   0          5s
twistlock-defender-ds-dtdjv         1/1     Running   0          5s
twistlock-defender-ds-rgs7q         1/1     Running   0          5s
```
:warning: **CAUTION**: 
If you only have one pod in the twistlock namespace, the defender did not install properly or at all. Run the steps to install defender again before continuing on.

Here are some examples of a filter for specific containers

twistlock-console
```
{
  "query": {
    "match_phrase": {
      kubernetes.container_name:twistlock-console
    }
  }
}
```

twistlock-defender
```
{
  "query": {
    "match_phrase": {
      kubernetes.labels.app:twistlock-defender
    }
  }
}
```

In the KQL field you can text search within a source field such as twistlock-defender
```
kubernetes.labels.app: "twistlock-defender"
```
```
kubernetes.namespace_name:twistlock kubernetes.labels.app:twistlock-defender stream:stdout log: F [31m ERRO 2020-07-14T19:13:25.646 defender.go:331 [0m Failed to initialize GeoLite2 db: open /prisma-static-data/GeoLite2-Country.mmdb: no such file or directory docker.container_id:c0f14b6ba111ef0af3761484dd77a19a5a9f054a4853f757d303be838cad6e6a kubernetes.container_name:twistlock-defender kubernetes.pod_name:twistlock-defender-ds-dtdjv kubernetes.container_image:registry-auth.twistlock.com/tw_bbzc81abegfiqtnruvspkazws2ze0dby/twistlock/defender:defender_20_04_169 kubernetes.container_image_id:registry-
```
```
kubernetes.container_name:twistlock-console
```
```
kubernetes.container_name:twistlock-console kubernetes.namespace_name:twistlock stream:stdout log: F [31m ERRO 2020-07-14T20:01:10.932 kubernetes_profile_resolver.go:38 [0m Failed to fetch Istio resources in 863da02e-15f2-d3da-f74d-0256f77292ad: 1 error occurred: docker.container_id:8303db1aa9e2a694b5db5a454c07127944ee0a4799f3e15f190eaa0eec53ca63 kubernetes.pod_name:twistlock-console-7d77c954d-lnjxp kubernetes.container_image:registry.dsop.io/platform-one/apps/twistlock/console:20.04.169 kubernetes.container_image_id:registry.dsop.io/platform-one/apps/twistlock/console@sha256:db77c64af682161c52da2bbee5fb55f38c0bcd46cacdb4c1148f24d094f18a10 kubernetes.pod_id:c979ebe6-f636-41b8-bfff-eab27fd48692
```

# Monitoring

## Prometheus Monitoring

Twistlock Prometheus metrics collection is implemented following the documentation:

https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/audit/prometheus.html

NOTE:
1. For twistlock monitoring, credentials are required to access the endpoint metrics. 
2. Current metrics is coming null, as current deployment has no ways to enable prometheus metrics.  To turn on Promethius from the console:
 ``Console -> Manage -> Alerts -> Logging -> Enable Prometheus Monitoring``

To enable prometheus metrics in twistlock:
```
cd app/monitoring/prometheus
```
```
kubectl apply -k .
```
## Integrating with SAML

Integrating Prisma Cloud with SAML consists of setting up your IdP, then configuring Prisma Cloud to integrate with it. for keycloak integration we will use use ADFS as the IdP.

Setting up Prisma Cloud in Keycloak

1. Follow the keycloak instructions under docs/keycloak named `configure-keycloak.md`

2. In Keycloak select the baby-yoda realm

3. On the left column, select "Clients", then new client.

4. Select load file and choose the "client.json" if available.  If not, use the 'saml_example.json.md' for the correct settings. The client info can be manually entered if the client isn't available.   Go into the configuration and select "Save".

5. In the left column Create a `Client Scope` for twistlock with a SAML Protocol.  Return to yout twistlock client and Add the Client scope to the `Your twistlock client` client.

6. Back in the Client configuration, under "Scope" Add the twistlock scope just created.

7. Select the "Installation" tab, the download the connection file in `Mod Auth Mellon format`
   _This is needed for the keycloak connection string._

8. Create a user in keycloak for twistlock.  Add the user to the IL2 Group.

### The following is required for manual configuration

1. Navigate to the Twistlock URL and create an admin user, then add a license key.

2. Navigate to "Manage" -> "Authentication" in the left navigation bar.

3. Select "SAML" then the enable switch.

4. Open the installation file from keycloak.  
     a. The Identity Provider SSO is `https://keycloak.fences.dsop.io/auth/realms/your-realm/protocol/saml`
     b. The Identity Provider is `https://keycloak.fences.dsop.io/auth/realms/your-realm`
     c. The root URL is `https://twistlock.fences.dsop.io`

5. Paste the client certificate token in the x509 area.  The certificate must be in pem format and include the header and footer.  When completed select "Save".  

   If this fails, the certificate is not formatted correctly.  Copy the cert to a file and test its validity.
   Copy the certificate into a vi session and ensure there are three lines:

   -----BEGIN CERTIFICATE-----

   (certificate from step 7 keycloak install file)

   -----END CERTIFICATE-----

   *note: when SAML is added, the twistlock console will default to keycloak.  If you need to bypass the saml auth process add "#!/login" the the end of the root url.*

6. Create a twistlock user using the same name as in step

7. There should be a "SAML box to select.  If this selection is not visible, go to a different tab, then return to users.


