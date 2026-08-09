ARG KAS_VERSION=4.5
FROM ghcr.io/siemens/kas/kas:${KAS_VERSION}

# Install bmap-tools (efficient SD card flashing) and a few extras
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bmap-tools \
        fdisk \
        parted \
        file \
    && rm -rf /var/lib/apt/lists/*
