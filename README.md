# Vela-OS

Containerized Yocto/OpenEmbedded build system using `kas` + Docker.
Hardware-neutral template targeting `genericx86-64` (EFI/GRUB boot) by
default, with A/B OTA updates via SWUpdate.

## Quick Start

```bash
# Build default board (generic x86-64)
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

Layer repos: `poky`, `meta-openembedded`, `meta-swupdate`, `meta-vela`.

## Common Targets

- `make build [board]` / `make image [board]`
- `make sdk [board]` / `make esdk [board]`
- `make shell [board]`
- `make flash [board] DEVICE=/dev/sdX`
- `make swu` (OTA package)
- `make help`

See `CLAUDE.md` / `REPO_MAP.md` for full details.
