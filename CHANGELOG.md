# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.24.0-bb.3] (2026-01-28)

- Added management of logon, intelligence, and scan settings via helm chart values.

## [0.24.0-bb.2] (2026-01-15)

### Changed

- added feature not to wait for defender rollout to complete init job

## [0.24.0-bb.1] (2026-01-12)

### Changed

- added option to disable the Istio Virtual Service for the management console -- istio.console.virtualService.enabled . it's enabled by default.

## [0.24.0-bb.0] (2025-12-11)

### Changed

- gluon updated from 0.9.6 to 0.9.7

## [0.23.0-bb.4] (2025-12-03)

### Changed

- Update registry1.dso.mil/ironbank/opensource/kubernetes/kubectl: v1.33.5 to v1.34.2

## [0.23.0-bb.3] (2025-11.12)

### Changed

- Update the egress-api network policy template to allow setting vpcCidr

## [0.23.0-bb.2] (2025-10.29)

### Changed

- gluon updated from  0.9.2 to 0.9.6

## [0.23.0-bb.1] (2025-10-02)

### Changed

- gluon updated from 0.8.4 to 0.9.2
- Updated ironbank/opensource/kubernetes/kubectl  v1.33.4 -> v1.33.5

## [0.23.0-bb.0] (2025-08-26)

### Changed

- gluon updated from 0.8.0 to 0.8.4
- Updated ironbank/opensource/kubernetes/kubectl v1.32.8 -> v1.33.4
- Updated ironbank/twistlock/console/console 34.01.132 -> 34.02.133
- Updated ironbank/twistlock/defender/defender 34.01.132 -> 34.02.133
- Added collect_pod_labels and set it to true values the yaml
- Added collect_pod_resource_labels and set it to true values the yaml

## [0.22.0-bb.1] (2025-08-19)

### Changed

- gluon updated from 0.7.0 to 0.8.0

## [0.22.0-bb.0] (2025-07-29)

### Changed

- gluon updated from 0.6.2 to 0.7.0
- ironbank/opensource/kubernetes/kubectl updated from v1.32.5 to v1.32.7
- ironbank/twistlock/console/console updated from 34.01.126 to 34.01.132
- ironbank/twistlock/defender/defender updated from 34.01.126 to 34.01.132

## [0.21.0-bb.2] (2025-07-22)

### Changed

- added Collection and host limit support to get-all-vuln-reports.sh contrib script

## [0.21.0-bb.1] (2025-07-10)

### Changed

- add tolerations for volume-upgrade-job

## [0.21.0-bb.0] (2025-06-05)

### Changed

- gluon updated from 0.5.16 to 0.6.2
- ironbank/opensource/kubernetes/kubectl updated from v1.32.4 to v1.32.5
- ironbank/twistlock/console/console updated from 34.00.141 to 34.01.126
- ironbank/twistlock/defender/defender updated from 34.00.141 to 34.01.126

## [0.20.1-bb.2] (2025-05-30)

### Changed

- added scripts/get-all-vuln-reports.sh to collect ATO BoE

## [0.20.1-bb.1] - 2025-05-28

### Changed

- Update init container images in volume-upgrade-job.yaml to use values from configuration

## [0.20.1-bb.0] (2025-04-30)

### Changed

- gluon updated from 0.5.15 to 0.5.16
- kubectl updated from v1.30.11 to v1.32.4
- registry1.dso.mil/ironbank/twistlock/console/console updated from 34.00.137 to 34.00.141 (vendor hotfix for better IngressNightmare detection)
- registry1.dso.mil/ironbank/twistlock/defender/defender updated from 34.00.137 to 34.00.141 (vendor hotfix for better IngressNightmare detection)

## [0.20.0-bb.0] - 2025-04-10

### Changed

- registry1.dso.mil/ironbank/twistlock/console/console updated from 33.03.138 to 34.00.137
- registry1.dso.mil/ironbank/twistlock/defender/defender updated from 33.03.138 to 34.00.137

## [0.19.0-bb.10] - 2025-04-15

### Changed

- Added test for defender connection

## [0.19.0-bb.9] - 2025-04-09

### Changed

- Cleaned up unused images

## [0.19.0-bb.8] - 2025-04-08

### Changed

- Replaced bbtests.scripts.image with Big Bang Base `registry1.dso.mil/ironbank/big-bang/base:2.1.0`

## [0.19.0-bb.7] - 2025-04-07

### Changed

- Removed jq image: `registry1.dso.mil/ironbank/stedolan/jq:1.7.1` from Chart.yaml's helm.sh/images

## [0.19.0-bb.6] - 2025-04-04

### Changed

- Replaced jq image `ironbank/stedolan/jq 1.7.1` with  Big Bang Base `registry1.dso.mil/bigbang-ci/devops-tester:1.1.2`
- Uopdated Gluon from 0.5.14 -> 0.5.15

## [0.19.0-bb.5] - 2025-03-28

### Changed

- Updated bbtests image to jq 1.7.1

## [0.19.0-bb.4] - 2025-03-28

### Changed

- ironbank/stedolan/jq updated from 1.7 to 1.7.1

## [0.19.0-bb.3] - 2025-03-14

### Changed

- Added Istio Operator-less network policy support

## [0.19.0-bb.2] - 2025-03-12

### Changed

- Edited contrib script `twistlock-defenders.sh` and `chart/scripts/contrib/scripts/il2-bb-sil-prod-example.env` env file to allow manual deployment of twistlock to support multi-cluster scenarios.

## [0.19.0-bb.0] - 2025-02-01

### Changed

- gluon updated from 0.5.12 to 0.5.14
- ironbank/opensource/kubernetes/kubectl updated from v1.30.7 to v1.30.9
- ironbank/twistlock/console/console updated from 33.01.137 to 33.03.138
- ironbank/twistlock/defender/defender updated from 33.01.137 to 33.03.138

## [0.18.0-bb.1] - 2025-01-24

### Changed

- remove upgrade-job

## [0.18.0-bb.0] - 2024-11-26

### Changed

- gluon updated from 0.5.8 to 0.5.12
- ironbank/opensource/kubernetes/kubectl updated from v1.30.6 to v1.30.7
- ironbank/twistlock/console/console updated from 32.07.123 to 33.01.137
- ironbank/twistlock/defender/defender updated from 32.07.123 to 33.01.137
- Added the maintenance track annotation and badge

## [0.17.0-bb.2] - 2024-11-05

### Changed

- Created the upgrade job for the label changes
- Brought back the changes from 0.16.0-bb.4
- Updated the volume upgrade job to be compatible with the upgrade job

## [0.17.0-bb.1] - 2024-11-04

### Added

- Added contributor scripts folder to allow for further setup of Twistlock deployments

## [0.17.0-bb.0] - 2024-10-31

### Changed

- ironbank/opensource/kubernetes/kubectl updated from v1.29.6 to v1.30.5
- ironbank/twistlock/console/console updated from 32.03.125 to 32.07.123
- ironbank/twistlock/defender/defender updated from 32.03.125 to 32.07.123

## [0.16.0-bb.5] - 2024-10-30

### Changed

- reverting the changes made in the previous release, they will come back later with a better upgrade process

## [0.16.0-bb.4] - 2024-10-08

### Changed

- Updated gluon to 0.5.8
- refactored helpers to standardize labels
- Updated the wait script
- Added kiali labels
- Added more stability to the cypress tests

## [0.16.0-bb.3] - 2024-10-07

### Changed

- Adds `podsLabel` input value and parses it through `tpl`

## [0.16.0-bb.2] - 2024-09-10

### Changed

- gluon updated from 0.5.3 to 0.5.4
- Add gluon wait script

## [0.16.0-bb.1] - 2024-08-13

### Changed

- gluon updated from 0.5.2 to 0.5.3
- ironbank/twistlock/defender/defender updated from 32.01.128 to 32.03.125

## [0.16.0-bb.0] - 2024-07-27

### Changed

- gluon updated from 0.5.0 to 0.5.2
- ironbank/twistlock/console/console updated from 32.01.128 to 32.03.125

## [0.15.0-bb.17] - 2024-07-25

### Changed

- Added `app` and `version` labels to defender pods to conform to Kiali requirements
- Updated `docs/DEVELOPMENT_MAINTENANCE.md` [Modifications made to upstream](https://repo1.dso.mil/big-bang/product/packages/twistlock/-/blob/main/docs/DEVELOPMENT_MAINTENANCE.md?ref_type=heads#modifications-made-to-upstream) section to reflect changes

## [0.15.0-bb.16] - 2024-07-19

### Changed

- Reduced Twistlock Defender Daemonsets resource request and limit to 2 CPU/2Gi RAM

## [0.15.0-bb.15] - 2024-07-12

### Changed

- Removed redundant entries in package test-values.yaml already in package values.yaml

## [0.15.0-bb.14] - 2024-07-02

### Changed

- Removed the shared authorization policies

## [0.15.0-bb.13] - 2024-06-19

### Changed

- Fixed resource requests and limits for Defender DaemonSet
- Added DNS SAN init script

## [0.15.0-bb.12] - 2024-06-05

### Added

- Added Cypress tests

## [0.15.0-bb.11] - 2024-05-22

### Changed

- Add resource requests and limits for Defender DaemonSet

## [0.15.0-bb.10] - 2024-05-15

### Changed

- Add Priority Class argument for defenders

## [0.15.0-bb.9] - 2024-05-15

### Changed

- Fixed minor typo error on twistlock/allow-sidecar-scraping

## [0.15.0-bb.8] - 2024-05-10

### Changed

- gluon updated from 0.4.9 to 0.5.0

## [0.15.0-bb.7] - 2024-04-30

### Changed

- Updated security capabilities for defender

## [0.15.0-bb.6] - 2024-04-18

### Changed

- Updated grafana dashboards to be compatible with Thanos

## [0.15.0-bb.5] - 2024-04-10

### Changed

- gluon updated from 0.4.8 to 0.4.9

## [0.15.0-bb.4] - 2024-03-29

### Changed

- Updated resources values for defender to match and follow Guaranteed QoS

## [0.15.0-bb.3] - 2024-03-13

### Changed

- Added Istio Sidecar to restrict egress traffic to REGISTRY_ONLY
- Added Istio ServiceEntry to explicitly allow egress

## [0.15.0-bb.2] - 2024-03-11

### Changed

- Updated security context for defender
- Updated resources for defender containers

## [0.15.0-bb.1] - 2024-03-04

### Changed

- Openshift update for deploying Twistlock into Openshift cluster

## [0.15.0-bb.0] - 2024-02-08

### Changed

- ironbank/twistlock/console/console updated from 31.03.103 to 32.01.128
- ironbank/twistlock/defender/defender updated from 31.03.103 to 32.01.128

## [0.14.0-bb.2] - 2024-02-08

### Added

- Added istio `allow-nothing` policy
- Added istio `allow-ingress` policy
- Added istio `allow-tempo` policy
- Added istio `allow-defender-to-console-port` policy
- Added `allow-scraping` policy
- Added `allow-sidecar-scraping` policy
- Added istio custom policy template

## [0.14.0-bb.1] - 2024-02-08

### Changed

- Bumped default memory from 2Gi to 3Gi
- gluon updated from 0.4.7 to 0.4.8

## [0.14.0-bb.0] - 2024-01-26

### Changed

- gluon updated from 0.4.6 to 0.4.7
- ironbank/twistlock/console/console updated from 30.02.123 to 31.03.103
- ironbank/twistlock/defender/defender updated from 30.02.123 to 31.03.103

## [0.13.0-bb.10] - 2023-11-30

### Changed

- Updating OSCAL Component File.

## [0.13.0-bb.9] - 2023-11-27

### Changed

- Updated PVC ironbank/big-bang/base updated from 2.0.0 to 2.1.0

## [0.13.0-bb.8] - 2023-11-08

### Changed

- ironbank/big-bang/base updated from 2.0.0 to 2.1.0

## [0.13.0-bb.7] - 2023-11-07

### Changed

- gluon updated from 0.4.1 to 0.4.4

## [0.13.0-bb.6] - 2023-11-01

### Changed

- Increase init job memory limit

## [0.13.0-bb.5] - 2023-10-18

### Changed

- Changed test url now that istio/ssl is configured to handle https

## [0.13.0-bb.4] - 2023-10-17

### Added

- Added appProtocol to service.yaml port 8083 definition to use istio explicit protocol selection
- Removed all files related to Cypress testing, using the scriopt for testing goign forward

## [0.13.0-bb.3] - 2023-10-11

### Changed

- OSCAL version update from 1.0.0 to 1.1.1

## [0.13.0-bb.2] - 2023-10-05

### Changed

- gluon updated from 0.4.0 to 0.4.1
- Updated Cypress to version 13.0.0
- Changed the Cypress file structure
- Changed to use the script for e2e testing instead of Cypress

## [0.13.0-bb.1] - 2023-09-15

### Changed

- Support for group assertion for SSO through Init script

## [0.13.0-bb.0] - 2023-09-01

### Changed

- ironbank/twistlock/console/console updated from 22.12.415 to 30.02.123
- ironbank/twistlock/defender/defender updated from 22.12.415 to 30.02.123

## [0.12.0-bb.5] - 2023-06-22

### Changed

- Setting new variable for cypress test timeout
- If no value is given it will use default timeout value.

## [0.12.0-bb.4] - 2023-06-22

### Changed

- Updated gluon from 0.3.2 -> 0.4.0

## [0.12.0-bb.3] - 2023-06-20

### Changed

- Changed chart/values.yaml to nest serviceMonitor under monitoring

## [0.12.0-bb.2] - 2023-05-31

### Changed

- Changed chart/Chart.yaml condition

## [0.12.0-bb.1] - 2023-05-11

### Added

- Added TLDR documentation for Container Models

## [0.12.0-bb.0] - 2023-02-17

### Changed

- ironbank/twistlock/console/console updated from 22.06.197 to 22.12.415
- ironbank/twistlock/defender/defender updated from 22.06.197 to 22.12.415

## [0.11.4-bb.3] - 2023-02-09

### Changed

- Add init job resources values and templating

## [0.11.4-bb.2] - 2022-01-17

### Changed

- Update gluon to new registry1 location + latest version (0.3.2)

## [0.11.4-bb.1] - 2022-12-05

### Fixed

- Quote value for privileged for stringData

### Added

- Add docs for WAAS

## [0.11.4-bb.0] - 2022-11-17

### Added

- Added Grafana dasboards

## [0.11.3-bb.2] - 2022-10-20

### Changed

- Modified volume job to add retries on chown + exit with error properly

## [0.11.3-bb.1] - 2022-10-14

### Added

- Added drop security context capability to defender and console

## [0.11.3-bb.0] - 2022-10-12

### Added

- Configurable trusted image policy via init job

## [0.11.2-bb.0] - 2022-10-06

### Fixed

- Added affinity for volume upgrade job
- Set job to run by default
- Add resources for volume job, modify wait logic to handle edge cases with unhealthy console

## [0.11.1-bb.0] - 2022-10-02

### Changed

- increase Mem for console to 2gb

## [0.11.0-bb.0] - 2022-09-27

### Added

- Set Twistlock console to run as nonroot
- Added upgrade option for those with local volumes through the volume-upgrade-job

## [0.10.0-bb.2] - 2022-09-22

### Added

- Enable mTLS for Twistlock metrics
- Updated Gluon to `0.3.1`

## [0.10.0-bb.1] - 2022-09-02

### Added

- Add support for SAML SSO via init script

## [0.10.0-bb.0] - 2022-08-26

### Changed

- Updated console and defender to `22.06.197`

## [0.9.1-bb.0] - 2022-09-01

### Added

- Conditional PrometheusRule template for Defender count alerts fulfilled by the monitoring stack

## [0.9.0-bb.4] - 2022-08-15

### Fixed

- Update Defender's daemonSet to support/add tolerations

## [0.9.0-bb.3] - 2022-06-30

### Fixed

- Fixed handling of metrics/servicemonitor + creation of user for metrics
- Adjust job TTL to 30 minutes to provide time for viewing debug logging

## [0.9.0-bb.2] - 2022-07-04

### Updated

- Make Twistlock more customization via values.yaml

## [0.9.0-bb.1] - 2022-06-28

### Updated

- Updated bb base image to 2.0.0
- Updated gluon to 0.2.10

## [0.9.0-bb.0] - 2022-06-16

### Updated

- Updated to 22.06.179 (console and defender)
- Updated to latest gluon library + latest base image

## [0.8.0-bb.0] - 2022-06-10

### Added

- Added oscal-component.yaml

## [0.7.0-bb.0] - 2022-05-05

### Added

- Added initialization job to setup users, license, defenders, policies, and other misc settings

### Changed

- Refactored names and labels to use _helpers.tpl
- Added labels to all resources

## [0.6.0-bb.0] - 2022-05-03

### Changed

- Updated twistlock image to 22.01.880

## [0.5.0-bb.0] - 2022-03-24

### Added

- Added Tempo Zipkin Egress Policy

## [0.4.0-bb.1] - 2022-02-28

### Added

- Added mTLS PeerAuthentication
- Added mTLS exception for defenders

## [0.4.0-bb.0] - 2022-01-31

### Changed

- Updated to 22.01.840 image versions
- Added documentation for running on k3d

## [0.3.0-bb.0] - 2022-01-31

### Changed

- Update Chart.yaml to follow new standardization for release automation
- Added renovate check to update new standardization

## [0.2.0-bb.0] - 2022-01-18

### Changed

- Relocated bbtests from `test-values.yaml` to `values.yaml`

## [0.1.0-bb.0] - 2021-12-14

### Added

- Add annotations to console deployment

## [0.0.12-bb.0] - 2021-11-22

### Changed

- Rename hostname to domain

## [0.0.11-bb.0] - 2021-10-27

### Changed

- Add image pull policy for the console

## [0.0.10-bb.0] - 2021-10-27

### Changed

- Updated console to version `21.08.520`
- Updated renovate.json for defender image + appVersion

### Added

- `tests/images.txt` for package release CI
- New network policy to allow for egress to twistlock upstream services

## [0.0.9-bb.1] - 2021-10-18

### Changed

- VS API version to v1beta1 to solve deprecation
- @micah.nagel added to CODEOWNERS, @joshwolf removed

## [0.0.9-bb.0] - 2021-09-10

### Added

- Documentation link to PCC default configuration for version 21.04.412
- Network Policy template specifically for Defenders communication
- networkPolicies.nodeCidr value to explicity set ingress CIDR for Defender WebSocket connections

## [0.0.8-bb.1] - 2021-08-26

### Added

- Added istio sidecar scraping network policy

## [0.0.8-bb.0] - 2021-08-16

### Added

- Upgrade twistlock console  to version 21.04.439

## [0.0.7-bb.0] - 2021-08-09

### Added

- Add conditional syslog audit integration for twistlock console.

## [0.0.6-bb.2] - 2021-08-06

### Added

- Add Resource limit and request.

## [0.0.6-bb.1] - 2021-07-21

### Added

- Add openshift toggle. If it's set, add port 5353 egress rule.

## [0.0.6-bb.0] - 2021-06-09

### Fixed

- Bug with istio network policy, allow egress in ns

## [0.0.5-bb.0] - 2021-06-02

### Changed

- Network policy resource Templates

## [0.0.4-bb.3] - 2021-06-01

### Added

- Gluon test library dependency

### Changed

- CI Test infrastructure. Migrating to helm tests with script capabilities.

## [0.0.4-bb.2] - 2021-05-26

### Added

- Network policy resource Templates

## [0.0.4-bb.0] - 2021-05-12

### Added

- Moved all resources into `chart/templates/console/`
- Updated twistlock to 21.04.412

## [0.0.3-bb.4] - 2021-04-06

### Added

- Resource and Toleration Values

## [0.0.3-bb.3] - 2021-04-05

### Changed

- Affinity values modified to standardize

## [0.0.3-bb.2] - 2021-03-31

### Added

- Values passthroughs for affinity and anti-affinity added

### Changed

- Split out resources into separate yaml files

## [0.0.3-bb.0] - 2021-02-12

### Added

- Options under istio values to control labels, annotations, gateways and full URL modification for twistlock VirtualService.

### Changed

- Position of "hostname" value in values, from "console.hostname" to toplevel "hostname".

## [0.0.2-bb.2] - 2021-02-11

### Added

- imagePullSecret array to values.

### Changed

- Image based on 20.12 version from IronBank.

## [0.0.2-bb.1] - 2021-01-27

### Changed

- Updating all "dsop.io" URLs to "dso.mil".

## [0.0.2-bb.0] - 2020-12-15

### Added

- Istio flag to enable VirtualService when true.

## [0.0.1-bb.0] - 2020-06-15

### Added

- Initial manifests for deploying Twistlock version 20.04.196.
