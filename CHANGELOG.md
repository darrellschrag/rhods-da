# Change log

All notable changes to this project will be documented in this file.

## 1.0.4 - 2023-12-15

### Added
   * First public version.
### Changed
### Fixed

## 1.0.5 - 2024-02-28
### Added
   * Added the ability to create a cluster as well as reference an existing one. The cluster it creates is a simple single zone cluster.
### Changed
   * Removed the validation of the GPU operator and RHODS operator pods and moved a summary of the pod status to the end. This is due to the fact that these pods sometimes take awhile to finish and there is no good way to wait for them as well as they may change.
### Fixed
