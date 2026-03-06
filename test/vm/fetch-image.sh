#!/bin/bash
# Fetch Debian cloud image for the host architecture
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

DEBIAN_VERSION="12"
DEBIAN_RELEASE="20241004-1890"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        DEB_ARCH="amd64"
        ;;
    arm64|aarch64)
        DEB_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

IMAGE_NAME="debian-${DEBIAN_VERSION}-generic-${DEB_ARCH}-${DEBIAN_RELEASE}.qcow2"
IMAGE_URL="https://cloud.debian.org/images/cloud/bookworm/${DEBIAN_RELEASE}/${IMAGE_NAME}"
LOCAL_IMAGE="debian-cloud.qcow2"
DISK_IMAGE="disk.qcow2"

# Download if not present
if [[ ! -f "$LOCAL_IMAGE" ]]; then
    echo "Downloading Debian $DEBIAN_VERSION cloud image for $DEB_ARCH..."
    curl -L -o "$LOCAL_IMAGE" "$IMAGE_URL"
    echo "Download complete."
else
    echo "Base image already exists: $LOCAL_IMAGE"
fi

# Create a copy for our VM disk (so we can reset by re-copying)
if [[ ! -f "$DISK_IMAGE" ]]; then
    echo "Creating VM disk from base image..."
    cp "$LOCAL_IMAGE" "$DISK_IMAGE"
    # Resize to 10GB
    qemu-img resize "$DISK_IMAGE" 10G
    echo "VM disk created: $DISK_IMAGE (10GB)"
else
    echo "VM disk already exists: $DISK_IMAGE"
    echo "Delete it to recreate from base image."
fi

echo "Done."
