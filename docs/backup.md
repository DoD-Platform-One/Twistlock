# Disaster Recovery
By default, automated backups are enabled. With automated backups enabled, Prisma Cloud takes a daily, weekly, and monthly snapshots. These are known as system backups.

To specify a different backup directory or to disable automated backups, modify twistlock.cfg in the configmap.yaml [here](https://repo1.dso.mil/platform-one/big-bang/apps/security-tools/twistlock/-/blob/documentation-standard/chart/templates/configmap.yaml) and delete the Twistlock Console pod(s). For more information on configuring and restoring from backups, see [the official documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/configure/disaster_recovery.html).
