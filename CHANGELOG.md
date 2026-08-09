# Changelog

## [Unreleased]

### Added — feature-complete generic x86-64 OS build

- **Full build orchestration**: `Makefile` (`image`/`build`/`rebuild-image`/
  `sdk`/`esdk`/`shell`/`swu`/`flash`/`deploy-*`/`clean*`/`completion`),
  `docker/{yocto,sdk,esdk}` build containers, `scripts/generate-swu-keys.sh`,
  `scripts/kas-container`, `vela-make-completion.bash`.
- **`kas/`** — `common.yaml`, `boards/vela.yaml` (genericx86-64), and repos
  (`poky`, `meta-openembedded`, `meta-swupdate`, `meta-vela`).
- **Complete `meta/meta-vela` Yocto layer** (68 files):
  - `recipes-core/images/vela-image.bb` + `vela-image-common.inc` + 20
    per-domain image variants
  - `recipes-core/vela-data-init`, `vela-services`, `systemd`, `os-release`
  - `recipes-core/packagegroup-vela-middleware` / `-cloud`
  - `recipes-connectivity/vela-connectivity`, `vela-timesync`
  - `recipes-bsp/vela-hal`, `recipes-support/expand-rootfs`, `swupdate`
  - `recipes-swupdate/vela-swupdate-config` (A/B OTA runtime)
  - `wic/sdimage-x86.wks`, `swupdate/sw-description` + pre/post-install
- **`CLAUDE.md`**, **`REPO_MAP.md`**, **`CHANGELOG.md`**, `.gitignore`.

### Notes

- Vela-OS is a hardware-neutral generic x86-64 template, following the shared
  Acadia/Arches template. Add a board config + vendor BSP to target a specific
  platform.
