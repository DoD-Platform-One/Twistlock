# Twistlock

## Licensing is required for this applicaiton  

## Twistlock under DSOP

The Twistlock Platform provides vulnerability management and compliance across the application lifecycle by scanning images and serverless functions to prevent security and compliance issues from progressing through the development pipeline, and continuously monitoring all registries and environments.

This installation follows the Twistlock documented guidance.  Twistlock documentation can be found at:
<https://docs.paloaltonetworks.com/prisma/prisma-cloud/20-04/prisma-cloud-compute-edition-admin/welcome.html>

The Twistlock Console is deployed as a part of the gitops.  Once deployed the process of setting up daemonsets is currently a manual process.  In order to install the following is required:

### Prerequisites

* Kubernetes cluster deployed
* Kubernetes config installed in `~/.kube/config`
* Elasticsearch, Keycloak and Kibana deployed and accessable.

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

The application needs a administrator, the license file needs to be installed, then a defender.yaml needs to be generated and deployed, then logging needs to be enabled. This has been consolidated in a script called twistlock_setup.sh.

The Variables required are as follows:

```
//Environment
$ TWISTLOCK_CONSOLE_USER=Administrator
$ TWISTLOCK_CONSOLE_PASSWORD=< my password>
$ TWISTLOCK_EXTERNAL_ROUTE=twistlock.fences.dsop.io
$ TWISTLOCK_LICENSE=
$ TOKEN=<Generated Bearer token Manage/Authentication/User Certificates>
```

This process requires kubectl to be installed and able to communicate with the DSOP cluster.

#### Add an Administrator

Initially there is no users associated with twistlock console.  Go to the external URL and add an Administrator account and a password.  Alternatively, run the following script:

``
//Add Administrator
if ! curl -k -H 'Content-Type: application/json' -X POST \
     -d "{\"username\": \"$TWISTLOCK_CONSOLE_USER\", \"password\": \"$TWISTLOCK_CONSOLE_PASSWORD\"}" \
     <https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/signup>; then

    echo "Error creating Twistlock Console user $TWISTLOCK_CONSOLE_USER"
    exit 1
fi
``

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
chmod +x twistcli
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

##### Download the daemonset.yaml.  The default Image is set to teh Prisma server.  We need to pull images from Platform 1.  The image URL needs to be changed

##### Image: registry.dsop.io/platform-one/apps/twistlock/defender:20.04.169

2) Install Defender

``
kubectl apply -f defender.yaml
``

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

#### Set up Logging

Run this code while setting the correct variables:

```
if ! curl -k \
  -u $TWISTLOCK_CONSOLE_USER:$TWISTLOCK_CONSOLE_PASSWORD \
  -H 'Content-Type: application/json' \
  -X POST \
  -d \
  '{
   "stdout": {
     "enabled": true,
     "verboseScan": true,
     "allProcEvents": true,
     }
  }' \
  https://$TWISTLOCK_EXTERNAL_ROUTE/api/v1/settings/logging; then

    echo "Error editing syslog settings on console"
    exit 1
fi
```

## Integrating with SAML

Integrating Prisma Cloud with SAML consists of setting up your IdP, then configuring Prisma Cloud to integrate with it. for keycloak integration we will use use ADFS as the IdP.
The following information is required to setup up Prisma Cloud in Keycloak:

* The SSO_URI will be the keycloak SAML URI
SSO_URL=<https://keycloak.fences.dsop.io/auth/realms/your-realm/protocol/saml>
* The issuer URL
ISSUER_URL=<https://keycloak.fences.dsop.io/auth/realms/your-realm>
* The Client ID.  THis is the name of the client in keycloak.  For SAML you will need the x509 certificate for this Client
CLIENT_ID=il2_twistlock (or whatever your client name)
* X590 certificate from the keycloak client install download  To imput this into twistlock by teh web page or by the api, be aware teh pem format is strictly enforced.  If you are having issues, test the certificate using opensource tools.  Ensure there are 3 lines in the cert; BEGIN/CRLF/Cert/CRLF/END
X_509_CERT="just the certificate"  

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

6. Create a twistlock user using the same name as in step 8 of keycloak setup.  

7. There should be a "SAML box to select.  If this selection is not visible, go to a different tab, then return to users.
