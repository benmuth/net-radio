#!/bin/bash
# Copy net-radio project to the VM
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Copying project to VM..."
rsync -avz --exclude '.git' --exclude 'test/vm/*.qcow2' --exclude 'test/vm/*.iso' \
    -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2222" \
    "$PROJECT_DIR/" user@localhost:~/net-radio/

echo "Done. SSH in and run:"
echo "  cd ~/net-radio"
echo "  go build -o nr-server nr-server.go"
echo "  ./stream.sh &"
echo "  ./nr-server &"
