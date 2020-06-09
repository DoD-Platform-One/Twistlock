# Twistlock

## This should not go into production with license and token .

## Twistlock under DSOP

The Twistlock Platform provides vulnerability management and compliance across the application lifecycle by scanning images and serverless functions to prevent security and compliance issues from progressing through the development pipeline, and continuously monitoring all registries and environments.

This installation follows the Twistlock documented guidance.  Twistlock documentation can be found at:
https://docs.paloaltonetworks.com/prisma/prisma-cloud/20-04/prisma-cloud-compute-edition-admin/welcome.html

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

The application needs a administrator, the license file needs to be installed, then a defender.yaml needs to be generated and deployed. This has been consolidated in a script called build_defender.

The Variables required are as follows:
```
$ //Environment 
$ TWISTLOCK_CONSOLE_USER=Administrator
$ TWISTLOCK_CONSOLE_PASSWORD=< my password>
$ TWISTLOCK_EXTERNAL_ROUTE=twistlock.fences.dsop.io
$ TWISTLOCK_LICENSE=
$ TOKEN=<Generated Bearer token Manage/Authentication/User Certificates>
```
This process requires kubectl to be installed and able to communicate with the DSOP cluster.

#### Add an Administrator

Initially there is no users associated with twistlock console.  Go to the external URL and add an Administrator account and a password.  Alternatively, run the following script:

```
//Add Administrator
if ! curl -k -H 'Content-Type: application/json' -X POST \
     -d "{\"username\": \"$TWISTLOCK_CONSOLE_USER\", \"password\": \"$TWISTLOCK_CONSOLE_PASSWORD\"}" \
     https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/signup; then

    echo "Error creating Twistlock Console user $TWISTLOCK_CONSOLE_USER"
    exit 1
fi
```

#### Install the license
The License can be added directly from the TWISTLOCK_EXTERNAL_ROUTE.  When first logging in the admin user will be prompted for a license.  The following  script will install the license:

```
//License
if ! curl -k \
  -u $TWISTLOCK_CONSOLE_USER:$TWISTLOCK_CONSOLE_PASSWORD \
  -H 'Content-Type: application/json' \
  -X POST \
  -d "{\"key\": \"$TWISTLOCK_LICENSE\"}" \
  https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/settings/license; then 

    echo "Error uploading Twistlock license to console"
    exit 1
fi
```

#### Install Defender with Twistcli 

This can be found in the Manage/System/Download.  After download ensure the file is made executable.

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
./twistcli defender export kubernetes --namespace twistlock --privileged --cri --monitor-service-accounts --monitor-istio --user $TWISTLOCK_CONSOLE_USER --password $TWISTLOCK_CONSOLE_PASSWORD --address https://$TWISTLOCK_EXTERNAL_ROUTE --cluster-address twistlock-console:8084
```
#####Download the daemonset.yaml.  The default Image is set to teh Prisma server.  We need to pull images from Platform 1.  The image URL needs to be changed:
##### Image: registry.dsop.io/platform-one/apps/twistlock/defender:20.04.169

2) Install Defender
```
kubectl apply -f defender.yaml
```
Install Defender from the Console UI

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



