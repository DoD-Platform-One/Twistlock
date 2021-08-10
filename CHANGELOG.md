# Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [0.0.7-bb.0] - 2021-08-10

### Added

- Upgrade to twistlock console 21.04.439

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
