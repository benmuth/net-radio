#!/bin/bash
# Stop the VM
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

PID_FILE="vm.pid"

if [[ ! -f "$PID_FILE" ]]; then
    echo "No VM PID file found. VM may not be running."
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping VM (PID $PID)..."
    kill "$PID"
    rm -f "$PID_FILE"
    echo "VM stopped."
else
    echo "VM process not found (stale PID file)."
    rm -f "$PID_FILE"
fi
