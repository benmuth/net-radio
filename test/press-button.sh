#!/bin/bash
# Simulate a button press on GPIO 27
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOCK_DIR="$SCRIPT_DIR/mock-gpio"

echo "1" > "$MOCK_DIR/27"
sleep 0.3
echo "0" > "$MOCK_DIR/27"
echo "Button pressed"
