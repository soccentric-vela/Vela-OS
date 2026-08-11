# =============================================================================
# Vela OS — Qualcomm Snapdragon Yocto Build System
# =============================================================================

# --- Image names -------------------------------------------------------------
KAS_IMAGE        ?= vela-kas:latest
SDK_IMAGE        ?= vela-sdk:latest
ESDK_IMAGE       ?= vela-esdk:latest

# Pin to a specific kas release — https://github.com/siemens/kas/releases
KAS_VERSION      ?= 4.5

# Yocto image recipe built by build / sdk / esdk / rebuild-image targets
IMAGE_TARGET     ?= vela-image

# OTA package version (overridable: make swu SWU_VERSION=1.2.3)
SWU_VERSION      ?= $(shell date +%Y%m%d%H%M)
SWU_VERSION      := $(SWU_VERSION)

# RSA private key for signing .swu packages (optional — absent = unsigned)
SWU_PRIV_KEY     ?= meta/meta-vela/swupdate/keys/swupdate-private.pem

# --- Positional board argument -----------------------------------------------
# The board name is typed directly after the target — no BOARD= needed:
#   make image vela
_BOARD_TARGETS := image build rebuild-image sdk esdk sdk-image esdk-image shell swu flash

ifneq ($(filter $(_BOARD_TARGETS),$(firstword $(MAKECMDGOALS))),)
  _BOARD_ARG := $(word 2,$(MAKECMDGOALS))
  ifneq ($(_BOARD_ARG),)
    ifeq ($(origin BOARD),undefined)
      BOARD := $(_BOARD_ARG)
    endif
    $(eval $(_BOARD_ARG):;@true)
  endif
endif

# --- Board -------------------------------------------------------------------
# Select target board — must match a file in kas/boards/<BOARD>.yaml
# Boards: vela (QCS6490 RB3 Gen 2)
BOARD            ?= vela
KAS_CONFIG       := kas/boards/$(BOARD).yaml

# Derive MACHINE automatically from the kas yaml
MACHINE          := $(shell grep '^machine:' $(KAS_CONFIG) 2>/dev/null | awk '{print $$2}')

# --- Directories -------------------------------------------------------------
BUILD_DIR        ?= $(CURDIR)/build
CACHE_DIR        ?= $(CURDIR)/cache
DL_DIR           ?= $(CACHE_DIR)/downloads
SSTATE_DIR       ?= $(CACHE_DIR)/sstate-cache
DEPLOY_DIR       ?= $(CURDIR)/deploy

DEPLOY_TS        := $(shell date +%Y%m%d_%H%M%S)

SDK_INSTALL_DIR  ?= /opt/poky/sdk
ESDK_INSTALL_DIR ?= /opt/poky/esdk

# --- kas-container -----------------------------------------------------------
KAS_CONTAINER     := $(CURDIR)/kas-container
KAS_CONTAINER_URL  = https://raw.githubusercontent.com/siemens/kas/refs/tags/$(KAS_VERSION)/kas-container

KAS_ENV = \
	KAS_CONTAINER_IMAGE=$(KAS_IMAGE) \
	KAS_BUILD_DIR=$(BUILD_DIR) \
	DL_DIR=$(DL_DIR) \
	SSTATE_DIR=$(SSTATE_DIR) \
	KAS_SSH_DIR=$(HOME)/.ssh

KAS_RUN = $(KAS_ENV) $(KAS_CONTAINER)

_KAS_IMAGE_NAME  := $(firstword $(subst :, ,$(KAS_IMAGE)))
_KAS_IMAGE_TAG   := $(lastword  $(subst :, ,$(KAS_IMAGE)))
_SDK_IMAGE_NAME  := $(firstword $(subst :, ,$(SDK_IMAGE)))
_SDK_IMAGE_TAG   := $(lastword  $(subst :, ,$(SDK_IMAGE)))
_ESDK_IMAGE_NAME := $(firstword $(subst :, ,$(ESDK_IMAGE)))
_ESDK_IMAGE_TAG  := $(lastword  $(subst :, ,$(ESDK_IMAGE)))

# =============================================================================
# Targets
# =============================================================================
.PHONY: all build rebuild-image \
        kas-image image ensure-image \
        sdk-image ensure-sdk-image \
        esdk-image ensure-esdk-image \
        kas-container-script shell flash sdk esdk swu \
        deploy-images deploy-sdk deploy-esdk deploy-swu \
        clean clean-build clean-docker clean-all \
        completion help

all: build

kas-container-script:
	@if [ ! -f $(KAS_CONTAINER) ]; then \
	    echo "Downloading kas-container $(KAS_VERSION) ..."; \
	    curl -fsSL $(KAS_CONTAINER_URL) -o $(KAS_CONTAINER); \
	    chmod +x $(KAS_CONTAINER); \
	fi

kas-image:
	$(MAKE) -C docker/yocto \
	    IMAGE_NAME=$(_KAS_IMAGE_NAME) \
	    IMAGE_TAG=$(_KAS_IMAGE_TAG) \
	    KAS_VERSION=$(KAS_VERSION)

ensure-image:
	@docker image inspect $(KAS_IMAGE) >/dev/null 2>&1 \
	    || { echo "KAS image $(KAS_IMAGE) not found — building ..."; \
	         $(MAKE) kas-image; }

image: build

sdk-image: ensure-image kas-container-script
	@echo "Building Yocto SDK + Docker image for $(SDK_IMAGE)"
	@mkdir -p $(BUILD_DIR) $(DL_DIR) $(SSTATE_DIR)
	$(KAS_RUN) shell $(KAS_CONFIG) -c "bitbake -c populate_sdk $(IMAGE_TARGET)"
	@_SDK_SH="$$(find $(BUILD_DIR)/tmp/deploy/sdk -maxdepth 1 \
	    -name '*.sh' ! -name '*-ext-*' 2>/dev/null | sort -V | tail -1)"; \
	 test -n "$$_SDK_SH" || { echo "ERROR: SDK installer (.sh) not found"; exit 1; }; \
	 cp "$$_SDK_SH" docker/sdk/sdk.sh && chmod +x docker/sdk/sdk.sh
	$(MAKE) -C docker/sdk \
	    IMAGE_NAME=$(_SDK_IMAGE_NAME) \
	    IMAGE_TAG=$(_SDK_IMAGE_TAG) \
	    SDK_INSTALL_DIR=$(SDK_INSTALL_DIR)
	@$(MAKE) --no-print-directory deploy-sdk DEPLOY_TS=$(DEPLOY_TS)

esdk-image: ensure-image kas-container-script
	@echo "Building Yocto eSDK + Docker image for $(ESDK_IMAGE)"
	@mkdir -p $(BUILD_DIR) $(DL_DIR) $(SSTATE_DIR)
	$(KAS_RUN) shell $(KAS_CONFIG) -c "bitbake -c populate_sdk_ext $(IMAGE_TARGET)"
	@_ESDK_SH="$$(find $(BUILD_DIR)/tmp/deploy/sdk -maxdepth 1 \
	    -name '*-ext-*.sh' 2>/dev/null | sort -V | tail -1)"; \
	 test -n "$$_ESDK_SH" || { echo "ERROR: eSDK installer (*-ext-*.sh) not found"; exit 1; }; \
	 cp "$$_ESDK_SH" docker/esdk/esdk.sh && chmod +x docker/esdk/esdk.sh
	$(MAKE) -C docker/esdk \
	    IMAGE_NAME=$(_ESDK_IMAGE_NAME) \
	    IMAGE_TAG=$(_ESDK_IMAGE_TAG) \
	    ESDK_INSTALL_DIR=$(ESDK_INSTALL_DIR)
	@$(MAKE) --no-print-directory deploy-esdk DEPLOY_TS=$(DEPLOY_TS)

ensure-sdk-image:
	@docker image inspect $(SDK_IMAGE) >/dev/null 2>&1 \
	    || { echo "SDK image $(SDK_IMAGE) not found — running full sdk-image chain ..."; \
	         $(MAKE) sdk-image; }

ensure-esdk-image:
	@docker image inspect $(ESDK_IMAGE) >/dev/null 2>&1 \
	    || { echo "eSDK image $(ESDK_IMAGE) not found — running full esdk-image chain ..."; \
	         $(MAKE) esdk-image; }

build: ensure-image kas-container-script
	@mkdir -p $(BUILD_DIR) $(DL_DIR) $(SSTATE_DIR)
	$(KAS_RUN) build $(KAS_CONFIG)
	@$(MAKE) --no-print-directory deploy-images DEPLOY_TS=$(DEPLOY_TS)

rebuild-image: ensure-image kas-container-script
	$(KAS_RUN) shell $(KAS_CONFIG) -c "bitbake -c cleansstate $(IMAGE_TARGET)"
	$(KAS_RUN) build $(KAS_CONFIG)
	@$(MAKE) --no-print-directory deploy-images DEPLOY_TS=$(DEPLOY_TS)

shell: ensure-image kas-container-script
	$(KAS_RUN) shell $(KAS_CONFIG)

sdk: ensure-image kas-container-script
	@mkdir -p $(BUILD_DIR) $(DL_DIR) $(SSTATE_DIR)
	$(KAS_RUN) shell $(KAS_CONFIG) -c "bitbake -c populate_sdk $(IMAGE_TARGET)"
	@$(MAKE) --no-print-directory deploy-sdk DEPLOY_TS=$(DEPLOY_TS)

esdk: ensure-image kas-container-script
	@mkdir -p $(BUILD_DIR) $(DL_DIR) $(SSTATE_DIR)
	$(KAS_RUN) shell $(KAS_CONFIG) -c "bitbake -c populate_sdk_ext $(IMAGE_TARGET)"
	@$(MAKE) --no-print-directory deploy-esdk DEPLOY_TS=$(DEPLOY_TS)

## Build a .swu OTA update package from the latest rootfs.ext4 image
swu: build
	$(eval ROOTFS := $(shell find $(BUILD_DIR)/tmp/deploy/images/$(MACHINE) \
	    -name "vela-image-$(MACHINE)*.rootfs.ext4" 2>/dev/null \
	    | sort -V | tail -1))
	@test -n "$(ROOTFS)" || \
	    { echo "ERROR: No .rootfs.ext4 found. Ensure 'ext4' is in IMAGE_FSTYPES."; exit 1; }
	@echo "Packaging OTA update from: $(ROOTFS)"
	@mkdir -p $(BUILD_DIR)/swu

	# --- rootfs ---
	@gzip -kfc "$(ROOTFS)" > "$(BUILD_DIR)/swu/rootfs.ext4.gz"

	# --- kernel + DTB (QCS6490) ---
	$(eval KERNEL := $(shell find $(BUILD_DIR)/tmp/deploy/images/$(MACHINE) \
	    \( -name 'boot-qcs6490-rb3gen2-qcom-armv8a.img' \
	       -o -name 'boot.img' \
	       -o -name 'Image' \) 2>/dev/null | sort -V | tail -1))
	$(eval DTB := $(shell find $(BUILD_DIR)/tmp/deploy/images/$(MACHINE) \
	    -name 'qcs6490-rb3gen2.dtb' 2>/dev/null | sort -V | tail -1))
	@test -n "$(KERNEL)" || \
	    { echo "WARNING: kernel (boot.img/Image) not found — kernel will not be updated in this .swu"; }
	@test -n "$(DTB)" || \
	    { echo "WARNING: qcs6490-rb3gen2.dtb not found — DTB will not be updated in this .swu"; }
	@[ -n "$(KERNEL)" ] && cp "$(KERNEL)" "$(BUILD_DIR)/swu/boot.img" || true
	@[ -n "$(DTB)" ]    && cp "$(DTB)"    "$(BUILD_DIR)/swu/qcom-qcs6490-rb3gen2.dtb" || true

	# --- sw-description ---
	@sed -e "s|@@VERSION@@|$(SWU_VERSION)|" \
	    -e "s|@@KERNEL@@|boot.img|" \
	    -e "s|@@DTB@@|qcom-qcs6490-rb3gen2.dtb|" \
	    meta/meta-vela/swupdate/sw-description \
	    > "$(BUILD_DIR)/swu/sw-description"
	@cp meta/meta-vela/swupdate/pre-install.sh  "$(BUILD_DIR)/swu/"
	@cp meta/meta-vela/swupdate/post-install.sh "$(BUILD_DIR)/swu/"
	@if [ -f "$(SWU_PRIV_KEY)" ]; then \
	    echo "Signing sw-description with RSA-4096 ..."; \
	    openssl dgst -sha256 \
	        -sign "$(SWU_PRIV_KEY)" \
	        -out  "$(BUILD_DIR)/swu/sw-description.sig" \
	        "$(BUILD_DIR)/swu/sw-description"; \
	    echo "Packing SIGNED .swu ..."; \
	    cd "$(BUILD_DIR)/swu" && \
	        printf 'sw-description\nsw-description.sig\npre-install.sh\npost-install.sh\nrootfs.ext4.gz\nboot.img\nqcom-qcs6490-rb3gen2.dtb\n' | \
	        cpio -ov -H newc > "$(BUILD_DIR)/$(BOARD)-$(SWU_VERSION).swu"; \
	else \
	    echo "WARNING: No private key found — packing UNSIGNED .swu (run scripts/generate-swu-keys.sh to enable signing)"; \
	    cd "$(BUILD_DIR)/swu" && \
	        printf 'sw-description\npre-install.sh\npost-install.sh\nrootfs.ext4.gz\nboot.img\nqcom-qcs6490-rb3gen2.dtb\n' | \
	        cpio -ov -H newc > "$(BUILD_DIR)/$(BOARD)-$(SWU_VERSION).swu"; \
	fi
	@echo "OTA package: $(BUILD_DIR)/$(BOARD)-$(SWU_VERSION).swu"
	@$(MAKE) --no-print-directory deploy-swu DEPLOY_TS=$(DEPLOY_TS) SWU_VERSION=$(SWU_VERSION)

## Flash to SD/eMMC.  Usage: make flash vela DEVICE=/dev/sdX
flash:
ifndef DEVICE
	$(error DEVICE is not set — example: make flash DEVICE=/dev/sdb)
endif
	@test -b "$(DEVICE)" || \
	    { echo "ERROR: '$(DEVICE)' is not a block device."; exit 1; }
	$(eval WIC := $(shell find $(BUILD_DIR)/tmp/deploy/images/$(MACHINE) \
	    -name "*.wic.bz2" 2>/dev/null | sort -V | tail -1))
	@test -n "$(WIC)" || \
	    { echo "ERROR: no .wic.bz2 found in $(BUILD_DIR)/tmp/deploy/images/$(MACHINE)"; exit 1; }
	@echo "Flashing $(WIC) → $(DEVICE)"
	bmaptool copy --bmap "$(WIC:.bz2=.bmap)" "$(WIC)" "$(DEVICE)"

deploy-images:
	@src="$(BUILD_DIR)/tmp/deploy/images/$(MACHINE)"; \
	 out="$(DEPLOY_DIR)/images/$(BOARD)_$(DEPLOY_TS)"; \
	 test -d "$$src" || { echo "ERROR: No image artifacts at $$src"; exit 1; }; \
	 mkdir -p "$$out"; \
	 find "$$src" -maxdepth 1 \( -type f -o -type l \) \
	     \( -name "*.wic.bz2" -o -name "*.wic.bmap" \) \
	     -exec cp -L {} "$$out/" \;; \
	 echo "  Done: $$out"

deploy-sdk:
	@src="$(BUILD_DIR)/tmp/deploy/sdk"; \
	 out="$(DEPLOY_DIR)/sdk/$(BOARD)_$(DEPLOY_TS)"; \
	 test -d "$$src" || { echo "ERROR: No SDK artifacts at $$src"; exit 1; }; \
	 mkdir -p "$$out"; \
	 find "$$src" -maxdepth 1 \( -type f -o -type l \) \
	     -name '*.sh' ! -name '*-ext-*' \
	     -exec cp -L {} "$$out/" \;; \
	 echo "  Done: $$out"

deploy-esdk:
	@src="$(BUILD_DIR)/tmp/deploy/sdk"; \
	 out="$(DEPLOY_DIR)/esdk/$(BOARD)_$(DEPLOY_TS)"; \
	 test -d "$$src" || { echo "ERROR: No eSDK artifacts at $$src"; exit 1; }; \
	 mkdir -p "$$out"; \
	 find "$$src" -maxdepth 1 \( -type f -o -type l \) \
	     -name '*-ext-*.sh' \
	     -exec cp -L {} "$$out/" \;; \
	 echo "  Done: $$out"

deploy-swu:
	@out="$(DEPLOY_DIR)/swu/$(BOARD)_$(DEPLOY_TS)"; \
	 mkdir -p "$$out"; \
	 cp -L "$(BUILD_DIR)/$(BOARD)-$(SWU_VERSION).swu" "$$out/"; \
	 echo "  Done: $$out"

clean: clean-build

clean-build:
	rm -rf $(BUILD_DIR)

clean-docker:
	docker rmi -f $(KAS_IMAGE) $(SDK_IMAGE) $(ESDK_IMAGE) 2>/dev/null || true

clean-all: clean-build
	rm -rf $(DL_DIR) $(SSTATE_DIR)

completion:
	@RCFILE="$$HOME/.bashrc"; \
	 LINE="source \"$(CURDIR)/vela-make-completion.bash\""; \
	 if grep -qF "$$LINE" "$$RCFILE" 2>/dev/null; then \
	     echo "Completion already enabled in $$RCFILE"; \
	 else \
	     printf '\n# Vela Makefile tab-completion\n%s\n' "$$LINE" >> "$$RCFILE"; \
	     echo "Added to $$RCFILE — run: source $$RCFILE"; \
	 fi

help:
	@printf "\nUsage: make <target> <board>\n"
	@printf "\n  Examples:\n"
	@printf "    make image  vela\n"
	@printf "    make sdk    vela\n"
	@printf "    make flash  vela DEVICE=/dev/sdb\n"
	@printf "\nYocto build:\n"
	@printf "  %-24s %s\n" "image"              "Build Yocto SD card image for BOARD"
	@printf "  %-24s %s\n" "build"              "Build Yocto SD card image for BOARD"
	@printf "  %-24s %s\n" "rebuild-image"      "cleansstate image recipe, then rebuild"
	@printf "  %-24s %s\n" "sdk"                "Build cross-toolchain SDK → deploy/sdk/"
	@printf "  %-24s %s\n" "esdk"               "Build extensible SDK     → deploy/esdk/"
	@printf "  %-24s %s\n" "shell"              "Interactive kas shell"
	@printf "  %-24s %s\n" "swu"                "Build .swu OTA package  [SWU_VERSION=YYYYMMDDHHMM]"
	@printf "  %-24s %s\n" "flash"              "Flash SD card  (requires DEVICE=/dev/sdX)"
	@printf "\nDocker images:\n"
	@printf "  %-24s %s\n" "kas-image"          "Build/rebuild KAS build container"
	@printf "  %-24s %s\n" "ensure-image"       "Build KAS image only when absent"
	@printf "  %-24s %s\n" "sdk-image"          "Full chain: SDK build → stage → docker build → deploy"
	@printf "  %-24s %s\n" "esdk-image"         "Full chain: eSDK build → stage → docker build → deploy"
	@printf "\nClean:\n"
	@printf "  %-24s %s\n" "clean"              "Remove build/"
	@printf "  %-24s %s\n" "clean-docker"       "Remove kas/sdk/esdk Docker images"
	@printf "  %-24s %s\n" "clean-all"          "Remove build/, downloads/, sstate-cache/"
	@printf "\nUtilities:\n"
	@printf "  %-24s %s\n" "completion"         "Install bash tab-completion"
	@printf "\nBoards:\n"
	@printf "  vela (QCS6490 RB3 Gen 2)\n"
	@printf "\n"
