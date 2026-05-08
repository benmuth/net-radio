#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GPIOMOCK="$SCRIPT_DIR/test/gpioget"

STATION_FILE="station.txt"
UNMUTE_PIN=17

function start_stream() {
	$(ffplay -nodisp -autoexit "$STREAM_URL" >/dev/null 2>&1) || $(ffplay -nodisp -autoexit "$(yt-dlp --get-url "$STREAM_URL")" >/dev/null 2>&1) &

	echo "Stream started"
}

function stop_stream() {
	pkill ffplay
	echo "Stream stopped"
}

# Main loop
while true; do
	STATE=$("$GPIOMOCK" 0 $UNMUTE_PIN)

	OLD_URL=$STREAM_URL
	STREAM_URL=$(head -n 1 "$STATION_FILE")

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
		echo "Invalid state in gpio pin $UNMUTE_PIN. Use 1 to start or 0 to stop."
	fi

	sleep 0.1
done
