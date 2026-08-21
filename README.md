# Vela-OS

Containerized Yocto/OpenEmbedded build system using `kas` + Docker for the
**Qualcomm Snapdragon** platform (default board: QCS6490 RB3 Gen 2), with A/B
OTA updates via SWUpdate.

## Quick Start

```bash
# Build default board (QCS6490 RB3 Gen 2)
make image

# Explicit board selection
make image vela

# Open shell in build container
make shell vela

# Flash latest WIC image
make flash vela DEVICE=/dev/sdX
```

## Prerequisites

- Docker 20.10+
- GNU Make 4.0+
- curl
- bmaptool (for `make flash`)

## KAS Layout

- `kas/common.yaml`: shared distro/target/cache settings
- `kas/boards/*.yaml`: machine-specific board files
- `kas/repos/*.yaml`: external layer repository definitions

Layer repos: `poky`, `meta-arm`, `meta-openembedded`, `meta-qcom`,
`meta-swupdate`, `meta-vela`.

## Common Targets

- `make build [board]` / `make image [board]`
- `make sdk [board]` / `make esdk [board]`
- `make shell [board]`
- `make flash [board] DEVICE=/dev/sdX`
- `make swu` (OTA package)
- `make help`

See `CLAUDE.md` / `REPO_MAP.md` for full details.

## Project Summary

Vela-OS is the containerized Yocto/OpenEmbedded image-build repository for the
Vela device. It uses `kas` and Docker to assemble a Qualcomm Snapdragon image,
with `kas/boards/vela.yaml` defining the default QCS6490 RB3 Gen 2 target.
Shared settings are in `kas/common.yaml`, and repository definitions under
`kas/repos/` cover Poky, meta-arm, meta-openembedded, meta-qcom, meta-swupdate,
and meta-vela. The root Makefile exposes image/build, SDK, shell, flash, SWU,
and help workflows; Docker Makefiles provide Yocto, SDK, and eSDK environments.

The checked-in configuration demonstrates designed build paths, but does not
prove that external layers are available, an image builds in the current
environment, or a generated image boots on hardware. Flashing and A/B update
rollback are especially environment-dependent. Status below separates package
and configuration evidence from verified device behavior.

The KAS files are the controlling configuration for layer selection and board
composition; the Makefile is the user-facing wrapper around those containerized
operations. SDK and eSDK outputs are developer artifacts, whereas WIC flashing
and SWU updates affect a physical target. A build can therefore pass while a
bootloader, partition layout, SWUpdate policy, or rollback path still fails on
the board. The repository contains no evidence here of a completed image boot,
successful A/B rollback, or a tested external-layer mirror. Those checks need a
known board, storage device, network, and recovery plan. The status table names
the configured workflows and keeps those environmental limitations visible.

## Feature Status

| # | Name / Description | Implemented? | Test Coverage? | Manual Test |
|---:|---|---|---|---|
| 1 | KAS shared configuration and layer repositories | Implemented | Configuration present; build not verified | [ ] Manual verification required |
| 2 | Vela QCS6490 board definition | Implemented | Parse/build coverage unknown | [ ] Manual verification required |
| 3 | Dockerized Yocto build environment | Implemented | Config present; container run unknown | [ ] Manual verification required |
| 4 | Image build via `make image` / `make build` | Implemented | No successful build result established | [ ] Manual verification required |
| 5 | SDK and eSDK generation | Implemented | Generated SDK not verified | [ ] Manual verification required |
| 6 | Build-container shell | Implemented | Runtime verification unknown | [ ] Manual verification required |
| 7 | WIC flashing workflow | Implemented | Host/device dependent; not verified | [ ] Manual verification required |
| 8 | SWUpdate package generation | Implemented | Package generation not verified | [ ] Manual verification required |
| 9 | A/B OTA update integration | Partial | Configuration evidence; rollback unknown | [ ] Manual verification required |
| 10 | Reproducible release build | Partial | No current release result found | [ ] Manual verification required |

Use `make image vela`, `make shell vela`, `make sdk vela`, and `make swu` as
appropriate. Prerequisites include Docker, GNU Make, `curl`, and `bmaptool` for
flashing.
