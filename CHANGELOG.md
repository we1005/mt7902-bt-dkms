# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-10-27

### Added
- DKMS package `btmtk-mt7902` that builds `btmtk.ko` from the Ubuntu `6.17.0-19` / upstream v6.17 sources with the upstream MT7902 patch applied (`aab25984e559`, two lines).
- `install.sh` (with `--reload`) and `uninstall.sh`.
- `BUILD_EXCLUSIVE_KERNEL="^6\.17\."` guard.
- English and Chinese documentation, testing report, troubleshooting guide.
- CI: shellcheck, SPDX header check, build against the newest `linux-headers-6.17.*`.

### Verified
- Ubuntu 24.04.4, `6.17.0-19-generic`, MT7902 Bluetooth `0e8d:7902`: initialises, scans, survives reboot, rolls back and re-installs cleanly. See [docs/TESTING.md](docs/TESTING.md).

### Known limitations
- Pairing/audio/suspend not tested; one machine only.
- Other MT7902 USB IDs added in Linux 7.1 (`13d3:*`, `0489:e156`) are not covered.
