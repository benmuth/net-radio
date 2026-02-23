#!/bin/bash
# Simulate a button press on GPIO 27
MOCK_DIR="$HOME/.gpio-mock"

echo "1" > "$MOCK_DIR/27"
sleep 0.3
echo "0" > "$MOCK_DIR/27"
echo "Button pressed"
