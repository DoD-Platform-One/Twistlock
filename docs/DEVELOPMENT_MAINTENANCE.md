# To upgrade the Twistlock Package

Check the [upstream changelog](url_needed) and the [helm chart upgrade notes](url_needed).

# Upgrading

## Updating Grafana Dashboards

The dashboards are pulled from [here](https://github.com/PaloAltoNetworks/pcs-metrics-monitoring/tree/main/grafana/dashboards) via [Kptfile](../chart/dashboards/Kptfile). 

## Update dependencies  
  
- To Do

## Update binaries

- To Do

## Update chart

- To Do

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


```chart/values.yaml```
- To Do

# Testing new Twistlock Version

- To Do
