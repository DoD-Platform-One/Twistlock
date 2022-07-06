# Monitoring

While Twistlock does expose metrics for scraping via Prometheus, authentication is required to be able to access the metrics.

The init job provided in the chart will handle creation of a metrics "service account" along with the proper configuration for the service monitor.

## Setup

Provided you have deployed both Twistlock and Monitoring from the Big Bang chart, the rest of the configuration is handled for you. The only pre-requisite is enabling the init job (see more details in [init doc](./initialization.md)) so that the user can be created for you.

The username for the "service account user" will be `bigbang-metrics-sa`. The password for this user is a randomly generated 32 character string and the role of the user is "auditor", which is the least privilege role that provides metrics capabilities. If you need to access the user account for some reason the password is accessible via the `twistlock-metrics-auth` secret. The password will be re-generated on every upgrade as a security best practice since this a service account only.

If you want additional flexibility in the monitoring setup (configuring your own user, etc) you can disable the Big Bang provided monitoring setup via values:

```yaml
# when deploying standalone chart
monitoring:
  enabled: false

# When deploying via Big Bang
twistlock:
  values:
    monitoring:
      enabled: false
```

You will then be able to customize the monitoring setup which will require at minimum a network policy to allow scraping, a secret with credentials for an auditor account (or higher privilege), and a service monitor configured to use the credentials secret.

## Exposed Metrics

Palo Alto provides a document with a list of exposed metrics [here](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/audit/prometheus).
