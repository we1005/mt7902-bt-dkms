# Changelog

All notable changes are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- A separate Ubuntu 7.0.0-38 `btmtk` source baseline with the same upstream MT7902 patch.
- DKMS package 1.1 selects the source baseline for 6.17.x or 7.0.x.

### Verified
- Final phone retest after the second 7.0 reboot: 5/5 L2CAP echoes and a completed 4,154-byte OBEX transfer, without module reload or re-pair.
- On Ubuntu 24.04.4 / 7.0.0-38: module load, Android phone pairing, OBEX transfer, L2CAP echo, S3 suspend/resume and reboot.
- Build regression against installed 6.17.0-19 headers.

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
