# Disaster Recovery
By default, automated backups are enabled. With automated backups enabled, Twistlock takes daily, weekly, and monthly snapshots. These are known as system backups. However, it is important to understand how these in-app backups work and their limitations.

While these backups are enabled, Twistlock will copy its state data and configuration files to another directory within its container, `/var/lib/twistlock-backups` by default (Big Bang uses the default). This is a good first step in a backup process by gathering all the important data in one place but does not do anything to actually establish redundancy of the data. **If all you do is enable system backups and nothing else, if the Twistlock console Pod is deleted it will take all of its configuration data with it!**

The recommended way to ensure redundancy of your Twistlock configuration data is to install [Velero](https://repo1.dso.mil/platform-one/big-bang/apps/cluster-utilities/velero), a tool which automatically takes snapshots of PersistentVolumes and stores them in a configuraable backup location, e.g. Amazon S3. Since the `/var/lib/twistlock-backups` directory is mounted as a PersistentVolume in the Twistlock Console container, it should be captured automatically by Velero's backup process.

For more information on how Twistlock's built-in backup process works, see [the official documentation](https://docs.paloaltonetworks.com/prisma/prisma-cloud/prisma-cloud-admin-compute/configure/disaster_recovery.html).
