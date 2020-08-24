"clientId": "unique_clinet_id__twistlock",
    "name": "twistlock",
    "rootUrl": "https://twistlock.fences.dsop.io/api/v1/authenticate",
    "surrogateAuthRequired": false,
    "enabled": true,
    "alwaysDisplayInConsole": false,
    "clientAuthenticatorType": "client-secret",
    "redirectUris": [
        "*"
    ],
    "webOrigins": [],
    "notBefore": 0,
    "bearerOnly": false,
    "consentRequired": false,
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": false,
    "serviceAccountsEnabled": false,
    "publicClient": false,
    "frontchannelLogout": true,
    "protocol": "saml",
    "attributes": {
        "saml.assertion.signature": "true",
        "saml.force.post.binding": "true",
        "saml.multivalued.roles": "false",
        "saml.encrypt": "false",
        "saml.server.signature": "true",
        "saml.server.signature.keyinfo.ext": "false",
        "exclude.session.state.from.auth.response": "false",
        "saml.signing.certificate": "this is populated from a previous export and will be recreated",
        "saml.signature.algorithm": "RSA_SHA256",
        "saml_force_name_id_format": "false",
        "saml.client.signature": "false",
        "tls.client.certificate.bound.access.tokens": "false",
        "saml.authnstatement": "true",
        "display.on.consent.screen": "false",
        "saml_name_id_format": "username",
        "saml.signing.private.key": "this will be populated with a key from a previous install if importing a json client description",
        "saml_signature_canonicalization_method": "http://www.w3.org/2001/10/xml-exc-c14n#",
        "saml.onetimeuse.condition": "false"
    },
    "authenticationFlowBindingOverrides": {},
    "fullScopeAllowed": true,
    "nodeReRegistrationTimeout": -1,
    "defaultClientScopes": [
        "web-origins",
        "role_list",
        "roles",
        "profile",
        "email"
    ],
    "optionalClientScopes": [
        "address",
        "phone",
        "offline_access",
        "microprofile-jwt"
    ],
    "access": {
        "view": true,
        "configure": true,
        "manage": true
    }
}