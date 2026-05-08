#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GPIOMOCK="$SCRIPT_DIR/test/gpioget"

BUTTON_PIN=27

while true; do
  STATE=$("$GPIOMOCK" 0 $BUTTON_PIN)
  if [ "$STATE" = "1" ]; then
    curl -X POST "localhost/next"
    sleep 0.2
  fi
  sleep 0.1
done
