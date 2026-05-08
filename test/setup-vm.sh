#!/bin/bash
# Setup script for testing net-radio locally
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
MOCK_DIR="$SCRIPT_DIR/mock-gpio"

echo "=== Net-Radio Test Setup ==="

echo "Setting up mock GPIO files..."
mkdir -p "$MOCK_DIR"
echo "1" > "$MOCK_DIR/17"  # Unmute pin: 1 = audio on
echo "0" > "$MOCK_DIR/27"  # Button pin: 0 = not pressed

echo "Creating initial station file if missing..."
if [[ ! -f "$PROJECT_DIR/station.txt" ]]; then
    echo "https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one" > "$PROJECT_DIR/station.txt"
fi

# Build the Go server
echo "Building nr-server..."
cd "$PROJECT_DIR"
go build -o nr-server nr-server.go

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Mock GPIO controls:"
echo "  Mute:    echo 0 > $MOCK_DIR/17"
echo "  Unmute:  echo 1 > $MOCK_DIR/17"
echo "  Button:  $SCRIPT_DIR/press-button.sh"
echo ""
echo "Start the services:"
echo "  cd $PROJECT_DIR"
echo "  ./stream.sh &"
echo "  ./nr-server &"
echo "  ./button.sh &"
echo ""
echo "Web UI: http://localhost:80"
