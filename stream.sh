#!/bin/bash

STATION_FILE="station.txt"
UNMUTE_PIN=17

function start_stream() {
	ffplay -nodisp -autoexit "$STREAM_URL" >/dev/null 2>&1 &

	# this is slower but will work with many more urls. ideally should just be
	# used as a fallback
	# ffplay -nodisp -autoexit "$(yt-dlp --get-url "$STREAM_URL")" >/dev/null 2>&1 &

	echo "Stream started"
}

function stop_stream() {
	pkill ffplay
	echo "Stream stopped"
}

# when ffplay fails (exits with non-0 code), could run ffplay "$(yt-dlp --get-url <stream-url>)”
# alternatively, should run that every time, but it's slow

# Main loop
while true; do
	# TODO: change this command based on machine
	STATE=$(gpioget 0 $UNMUTE_PIN)

	OLD_URL=$STREAM_URL
	STREAM_URL=$(cat "$STATION_FILE")

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

	# stop_stream doesn't run if stream.sh is manually killed
	# TODO: catch CTRL+C

	sleep 0.1
done
