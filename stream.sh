#!/bin/bash

# set -eux

STATION_FILE="station.txt"
UNMUTE_PIN=17

function start_stream() {
	ffplay -nodisp -autoexit "$STREAM_URL" &
	echo "Stream started"
}

function stop_stream() {
	pkill ffplay
	echo "Stream stopped"
}

# Main loop
while true; do
	STATE=$(gpioget 0 $UNMUTE_PIN)

	OLD_URL=$STREAM_URL
	STREAM_URL=$(cat "$STATION_FILE")

	echo $OLD_URL
	echo $STREAM_URL

	if [[ "$OLD_URL" != "$STREAM_URL" ]]; then
		stop_stream
		start_stream
	fi

	if [ "$STATE" = "1" ]; then
		if ! pgrep ffplay >/dev/null; then
			start_stream
		fi
	elif [ "$STATE" = "0" ]; then
		if pgrep ffplay >/dev/null; then
			stop_stream
		fi
	else
		echo "Invalid state in $PIN_FILE. Use 1 to start or 0 to stop."
	fi

	sleep 0.1
done
