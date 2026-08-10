# Changelog

## [Unreleased]

### Added — feature-complete generic x86-64 OS build

- **Full build orchestration**: `Makefile` (`image`/`build`/`rebuild-image`/
  `sdk`/`esdk`/`shell`/`swu`/`flash`/`deploy-*`/`clean*`/`completion`),
  `docker/{yocto,sdk,esdk}` build containers, `scripts/generate-swu-keys.sh`,
  `scripts/kas-container`, `vela-make-completion.bash`.
- **`kas/`** — `common.yaml`, `boards/vela.yaml` (QCS6490 RB3 Gen 2), and repos
  (`poky`, `meta-arm`, `meta-openembedded`, `meta-qcom`, `meta-swupdate`, `meta-vela`).
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

### Retarget: generic x86-64 → Qualcomm Snapdragon

- **Vela-OS is now the Qualcomm Snapdragon build** (QCS6490 / QCM6490 /
  QCS5430, machine `qcs6490-rb3gen2-core-kit`).
- Added `meta-qcom` + `meta-arm` layers; accepted the
  Qualcomm-Technologies-Inc.-Proprietary licence.
- Boot: UEFI firmware → systemd-boot → Linux (boot.img + qcom/qcs6490-rb3gen2.dtb).
- A/B OTA: EFI GPT layout (`sdimage-qcom.wks`), systemd-boot loader.conf slot
  switching; kernel (boot.img) + DTB included in the `.swu`.
