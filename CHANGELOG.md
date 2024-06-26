# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.15.0-bb.13] - 2024-06-24
### Changed
- Add DNS SAN script

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

# [0.12.0-bb.3] - 2023-06-20
### Changed 
- Changed chart/values.yaml to nest serviceMonitor under monitoring

# [0.12.0-bb.2] - 2023-05-31
### Changed
- Changed chart/Chart.yaml condition

# [0.12.0-bb.1] - 2023-05-11
### Added 
- Added TLDR documentation for Container Models 

# [0.12.0-bb.0] - 2023-02-17
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
