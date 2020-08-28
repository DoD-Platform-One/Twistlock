# Keycloak.md

- Configuration items
- Add new groups
- Claim information
- SAML application items

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
