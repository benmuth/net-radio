
BUTTON_PIN=27

while true; do
  STATE=$(gpioget 0 $BUTTON_PIN)
  # STATE=$(cat button-state)
  if [ "$STATE" = "1" ]; then
    curl -X POST "localhost/next"
    sleep 0.2
  fi
  sleep 0.1
done


# TODO: nr-server
# make it possible for the station file to have multiple stations
# add a station index file
# 
# edit the file manually to have multiple stations
# render multiple stations on the webpage
#
# make "add station" form field
#
# make "next station" form field
#
# add a /next endpoint that cycles the station index
#
# TODO: button.sh
# make the button script call the /next endpoint
