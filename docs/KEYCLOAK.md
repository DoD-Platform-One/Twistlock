# Keycloak integration

- Configuration items
- Add new groups
- Claim information
- SAML application items

## Integrating with SAML

Integrating Prisma Cloud with SAML consists of setting up your IdP, then configuring Prisma Cloud to integrate with it. For keycloak integration we will use use ADFS as the IdP. Here is the official [SAML documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/20-04/prisma-cloud-compute-edition-admin/access_control/integrate_saml)

Setting up Prisma Cloud in Keycloak

1. These instructions assume that Keycloak is properly installed and configured with a realm other than master.

2. In Keycloak select the realm

3. On the left column, select "Clients", then click button ```Create```.

4. The client can be manually created. Or the example [twistlock_client.json](twistlock_client.json) can be imported after clicking the ```Create``` button. Make any necessary changes and click ```Save``` button.  Example settings:

   Client ID:  il2_a8604cc9-f5e9-4656-802d-d05624370245_twistlock
   Client Protocol: saml

   Settings TAB (accept defaults except for the following)
   Name: twistlock
   Sign Assertions: ON
   Client Signature Required: OFF
   Root URL:  https://twistlock.bigbang.dev/api/v1/authenticate
   Valid Redirect URIs: *

5. In the left column Create a Client Scope (if it does not already exist) named ```twistlock``` with a SAML Protocol.  Return to yout twistlock client and on the ```Client Scopes``` add the ```twistlock``` client scope.

6. Select the "Installation" tab. In the ```Format Option dropdown``` select ```Mod Auth Mellon files```. Then click the ```Download``` button. Information from this file is needed to configure Twistlock.

7. Create a test user in Keycloak for testing the Twistlock SSO authentication.

## Twistlock manual SAML configuration

Twistlock SSO integration is manual through the Admnistration UI. When Twistlock is deployed for the first time the login will ask you to create an admin user. Login with the admin user and follow these instructions:

1. Navigate to the Twistlock console URL. After installation you will be asked to create an admin user and enter license key.

2. Navigate to ```Manage -> Authentication``` in the left navigation bar. Select ```System Certificates``` (it might be in a drop down list if your browser is narrow). Enter the contatenated certificate and private key that matches your console domian. This is necessary so that the twistlock server can do TLS to Keycloak. When you click the ```Save``` button you will be logged out. You will have to log in again with the admin credentials.

3. Navigate to ```Manage -> Authentication``` in the left navigation bar. Select ```SAML``` (it might be in a drop down list if your browser is narrow). Then turn on the enable switch. Use identity provider "Shibboleth". This provider selection was recommended by Twistlock support.

4. Fill in the form. Example values are shown below. Use the values for your IdP. You can get the values from the installation files ```idp-metadata.xml``` and ```sp-metadata.xml``` in the zip archive downloaded from Keycloak from step #6 in the previous section.  
     a. Identity provider single sign-on URL: this is the Keycleak SAML authentication endpoint. The value can be found inside the ```<SingleSignOnService>``` tag in the ```idp-metadata.xml``` installation file.
        ```https://keycloak.bigbang.dev/auth/realms/baby-yoda/protocol/saml```  
     b. Identity provider issuer: enter the Keycloak URL path to the realm. The value can be found inside the ```<EntityDescriptor>``` tag in the ```idp-metadata.xml``` installation file.
        ```https://keycloak.bigbang.dev/auth/realms/baby-yoda```  
     c. Audience:  this is the Keycloak Client ID. The value can be found inside the ```<EntityDescriptor>``` tag as ```entityID``` in the ```sp-metadata.xml``` installation file.
        ```il2_00eb8904-5b88-4c68-ad67-cec0d2e07aa6_twistlock```  
     d. Console URL: This is the console URL of the Twistlock app. It is optional
        ```https://twistlock.bigbang.dev```  
     e. x509 certificate: This is the certificate from Keycloak. The value can be found inside the ```<dsig:X509Certificate>``` tag in the ```idp-metadata.xml``` installation file.  The field must contain 3 lines with the begin and end certificate as show below. Do not leave any blank spaces at the beginning or ending of the 3 lines. If this is not followed exactly the SAML authentication will fail.
     ```
     -----BEGIN CERTIFICATE-----
     (certificate from the install file)
     -----END CERTIFICATE-----
     ```
     f. When all fields in the web form are completed select "Save".  

   *note: after SAML is added, the twistlock console will default to the keycloak login page. If you need to bypass the saml auth process add ```#!/login``` the the end of the root url.*

5. Twistlock SAML SSO does not create the users automatically. Unfortunatly, you must manually create the users before they can log in. Navigate to ```Manage -> Authentication``` in the left navigation bar. Select "Users" in the drop down list. Click the ```Add User``` button to create a twistlock user with the same name as the Keycloak user name. There should be a ```SAML``` auth method button to select. If this selection is not visible, go to a different tab, then return to users.
