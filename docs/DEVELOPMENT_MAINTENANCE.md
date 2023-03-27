# To upgrade the Twistlock Package

Twistlock is a BB created/maintained chart. As such there are typically no/minimal chart changes required for updates outside of a few select pieces listed below.

## Updating Grafana Dashboards

The dashboards are pulled from [here](https://github.com/PaloAltoNetworks/pcs-metrics-monitoring/tree/main/grafana/dashboards) via [Kptfile](../chart/dashboards/Kptfile). Typically you should run `kpt pkg update chart/dashboards --strategy force-delete-replace` to pull in the latest dashboards.

## Update dependencies  
  
Twistlock only uses a Gluon dependency. Validate it is on the latest version in `chart/Chart.yaml` then run `helm dependency update chart`.

## Update scripts/policies

The main thing that might break across updates is the initialization script process. This requires a lot of manual checking/testing and modification of the scripts under `chart/scripts` or the JSON data under `chart/policies` depending on issues that you encounter.

It is helpful to debug this in a few ways:
- Log requests that are sent to the API by adding `echo` commands or other basic debug around the area of the script that failed. It can be especially helpful to log things inside of `callapi()`.
- Utilize the development tools/console in a browser to intercept requests and make the same configuration manually. Then conpare the data sent via browser to what is set up in `chart/policies`.
- Validate that API changes have not occured - https://pan.dev/compute/api/

# Modifications made to upstream

```chart/dashboards/```

- pull down the new dashboards
```
kpt pkg get https://github.com/PaloAltoNetworks/pcs-metrics-monitoring/grafana/dashboards/Prisma-Cloud-Dashboards dashboards
```
- cd into this directory and run the following commands to update the dashboards' logic:
```
sed -i 's/job=\\"twistlock\\"/job=\\"twistlock-console\\"/g' $(find . -type f | grep .json) && \
sed -i 's/grafana-piechart-panel/piechart/g' $(find . -type f | grep .json)
```

We also add the value of `twistlock` to the `tags` key in all dashboard json files from:

for example:
```
"tags": [],
```
to:
```
"tags": [
      "twistlock"
    ],
```
...which allows a user to filter by the `twistlock` tag in Grafana to locate these particular dashboards more easily.

# Testing new Twistlock Version

- Configure SSO, add an SSO user with P1 SSO login, add "basic" user, set admin password to "admin", and point to correct dockerset in overrides value file. The below values are an example, you will need to request the development license from someone on the team.

  ```yaml
  twistlock:
  enabled: true
  sso:
    enabled: true
    client_id: "platform1_a8604cc9-f5e9-4656-802d-d05624370245_bb8-twistlock"
  values:
    console:
      license: "license_here"
      credentials:
        password: "admin"
      additionalUsers:
        - username: micah.nagel
          authType: saml
          role: admin
        - username: foo
          authType: basic
          password: bar
          role: admin
    defender:
      dockerSocket: "/run/k3s/containerd/containderd.sock"
      selinux: false
      privileged: true
  ```

- Validate that the Twistlock init job pod ran and completed, this should do all setup (license/user) and the required defender updates automatically (Pod is automatically removed after 30 minutes)

- Login to twistlock/prisma cloud with the default credentials

- Under Manage -> Defenders -> Manage, make sure # of defenders online is equal to number of nodes on the cluster

    Defenders will scale with the number of nodes in the cluster. If there is a defender that is offline, check whether the node exists in cluster anymore.
    Cluster autoscaler will often scale up/down nodes which can result in defenders spinning up and getting torn down.
    As long as the number of defenders online is equal to the number of nodes everything is working as expected.
