# Vela-OS Build and Deployment

## Purpose and scope

Vela-OS is the containerized Yocto/OpenEmbedded build system for the Qualcomm
QCS6490 RB3 Gen 2. KAS selects layers and the `qcom-armv8a` machine; the root
Makefile builds images, SDK/eSDK installers, WIC media, and SWUpdate packages.

## 1. Prerequisites

- Docker 20.10+, GNU Make 4+, `curl`, and `bmaptool` for flashing.
- Network access for the pinned kas-container (`KAS_VERSION=4.5`), Yocto layers,
  source downloads, and Docker images; large disk space is required for
  `build/` and `cache/`.
- A QCS6490 RB3 Gen 2 target and a carefully identified removable block device
  for `make flash`; never guess `DEVICE`.

## 2. Setup

The default board is `vela`, resolved through `kas/boards/vela.yaml`, whose
machine is `qcom-armv8a` and whose WKS config defines the A/B layout. `make
kas-image` builds the local KAS image; normal build targets automatically run
`ensure-image` and download the pinned kas-container when absent.

## 3. Build and compile

- `make build vela` or `make image vela` runs KAS for the selected board; `make`
  defaults to `build`.
- `make shell vela` opens a KAS shell for inspection.
- `make sdk vela` runs `populate_sdk`; `make esdk vela` runs
  `populate_sdk_ext`.
- Override `BOARD`, `IMAGE_TARGET`, `BUILD_DIR`, `CACHE_DIR`, and image names
  when a different configured board or storage location is required.

## 4. Tests and lint

The root Makefile exposes no unit-test or lint target. Validate KAS parsing,
BitBake output, package contents, boot, and update behavior as release checks;
run any layer-specific checks from inside `make shell <board>` when defined by
the selected layers.

## 5. Packaging and artifacts

`make build` copies `.wic.bz2` and `.wic.bmap` to `deploy/images/<board>_<timestamp>`.
`make sdk` and `make esdk` copy installer scripts to `deploy/sdk/...` and
`deploy/esdk/...`. `make swu` creates `<board>-<version>.swu` under `build/`
and copies it to `deploy/swu/...`; signing occurs only when `SWU_PRIV_KEY`
exists. To create the expected RSA-4096 key pair, run
`./scripts/generate-swu-keys.sh` before a signed package build. `make
deploy-images`, `deploy-sdk`, `deploy-esdk`, and `deploy-swu` repeat the copy
steps.

## 6. Deployment, install, and run

Flash the latest WIC with `make flash vela DEVICE=/dev/sdX`; the target must be
a block device and `bmaptool` needs the matching `.bmap`. Apply an OTA package
with the target's SWUpdate integration after verifying the signed package and
recovery plan. `make completion` optionally installs Make completion into
`~/.bashrc`.

## 7. Cleanup

`make clean` removes `build/`; `make clean-build` is the explicit equivalent.
`make clean-docker` removes KAS/SDK/eSDK images. `make clean-all` also removes
download and sstate caches, forcing expensive redownloads.

## 8. Hardware, cloud, and manual verification caveats

A successful BitBake build does not prove the image boots, firmware matches the
board, partitions are correct, SWUpdate signatures are trusted, or A/B rollback
works. `make flash` is destructive and requires the correct physical device;
`make swu` is unsigned when the private key is absent. Credentials, layer
access, signing keys, board recovery, and network/update connectivity are
conditional and require explicit release-time manual verification.