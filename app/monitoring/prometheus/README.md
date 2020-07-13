Twistlock Prometheus Monitoring is implemented as per the documentation

https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/audit/prometheus.html


1. Create ServiceMonitor for twistlock endpoint

2. Create Role, RoleBinding for monitoring in twistlock namespace

3. Create Secrets for metrics point authentication

4. kubectl apply -k prometheus



