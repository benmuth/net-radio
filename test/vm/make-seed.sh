#!/bin/bash
# Create cloud-init seed ISO
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SEED_ISO="seed.iso"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_ed25519.pub}"

# Try common SSH key locations
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    for key in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub ~/.ssh/id_ecdsa.pub; do
        if [[ -f "$key" ]]; then
            SSH_KEY_PATH="$key"
            break
        fi
    done
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
    echo "No SSH public key found. Generate one with: ssh-keygen -t ed25519"
    echo "Or set SSH_KEY_PATH to your public key location."
    exit 1
fi

SSH_PUBKEY=$(cat "$SSH_KEY_PATH")
echo "Using SSH key: $SSH_KEY_PATH"

# Create user-data with actual SSH key
sed "s|SSH_PUBKEY_PLACEHOLDER|$SSH_PUBKEY|" user-data > user-data.tmp

# Create ISO
OS=$(uname -s)
if [[ "$OS" == "Darwin" ]]; then
    # macOS: use hdiutil
    mkdir -p seed-tmp
    cp user-data.tmp seed-tmp/user-data
    cp meta-data seed-tmp/meta-data
    hdiutil makehybrid -o "$SEED_ISO" -hfs -joliet -iso -default-volume-name cidata seed-tmp/
    rm -rf seed-tmp
elif command -v genisoimage &>/dev/null; then
    genisoimage -output "$SEED_ISO" -volid cidata -joliet -rock user-data.tmp meta-data
elif command -v mkisofs &>/dev/null; then
    mkisofs -output "$SEED_ISO" -volid cidata -joliet -rock user-data.tmp meta-data
else
    echo "No ISO creation tool found. Install genisoimage or mkisofs."
    rm -f user-data.tmp
    exit 1
fi

rm -f user-data.tmp
echo "Created cloud-init seed: $SEED_ISO"
