# Monitoring

- Configuration items
- List of metrics gathered
- Useful queries [living list]

## Prometheus Monitoring

Twistlock Prometheus metrics collection is implemented following the documentation:

<https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/audit/prometheus.html>

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
