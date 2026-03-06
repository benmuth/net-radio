#!/bin/bash
# Start the VM with QEMU
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

DISK_IMAGE="disk.qcow2"
SEED_ISO="seed.iso"
PID_FILE="vm.pid"
LOG_FILE="vm.log"

# Check prerequisites
if [[ ! -f "$DISK_IMAGE" ]]; then
    echo "Disk image not found. Run ./fetch-image.sh first."
    exit 1
fi

if [[ ! -f "$SEED_ISO" ]]; then
    echo "Seed ISO not found. Run ./make-seed.sh first."
    exit 1
fi

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "VM already running (PID $PID). Use ./stop-vm.sh to stop it."
        exit 1
    fi
    rm -f "$PID_FILE"
fi

# Detect architecture and OS
ARCH=$(uname -m)
OS=$(uname -s)

case "$ARCH" in
    x86_64)
        QEMU_BIN="qemu-system-x86_64"
        MACHINE="-machine q35"
        CPU="-cpu host"
        ;;
    arm64|aarch64)
        QEMU_BIN="qemu-system-aarch64"
        MACHINE="-machine virt"
        CPU="-cpu host"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Detect acceleration
if [[ "$OS" == "Darwin" ]]; then
    ACCEL="-accel hvf"
elif [[ "$OS" == "Linux" ]] && [[ -e /dev/kvm ]]; then
    ACCEL="-accel kvm"
else
    echo "Warning: No hardware acceleration available, using TCG (slow)"
    ACCEL="-accel tcg"
    CPU=""  # host CPU requires accel
fi

# UEFI firmware for arm64
UEFI_ARGS=""
if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    # Try common UEFI firmware paths
    for fw in \
        /opt/homebrew/share/qemu/edk2-aarch64-code.fd \
        /usr/share/qemu/edk2-aarch64-code.fd \
        /usr/share/AAVMF/AAVMF_CODE.fd \
        /usr/share/edk2/aarch64/QEMU_CODE.fd; do
        if [[ -f "$fw" ]]; then
            UEFI_ARGS="-bios $fw"
            break
        fi
    done
    if [[ -z "$UEFI_ARGS" ]]; then
        echo "Warning: No UEFI firmware found for arm64. VM may not boot."
    fi
fi

echo "Starting VM..."
echo "  Architecture: $ARCH"
echo "  Acceleration: $ACCEL"
echo "  SSH: localhost:2222"
echo "  Web: localhost:8080"
echo ""

# Start QEMU in background
$QEMU_BIN \
    $MACHINE \
    $CPU \
    $ACCEL \
    $UEFI_ARGS \
    -m 1024 \
    -smp 2 \
    -drive file="$DISK_IMAGE",format=qcow2,if=virtio \
    -drive file="$SEED_ISO",format=raw,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
    -device virtio-net,netdev=net0 \
    -nographic \
    > "$LOG_FILE" 2>&1 &

echo $! > "$PID_FILE"
echo "VM started in background (PID $(cat $PID_FILE))"
echo ""
echo "Wait ~30-60 seconds for first boot, then:"
echo "  SSH:  ./ssh-vm.sh"
echo "  Logs: tail -f $LOG_FILE"
echo "  Stop: ./stop-vm.sh"
