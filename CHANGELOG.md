# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
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
