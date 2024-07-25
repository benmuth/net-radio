#!/bin/sh

setcap CAP_NET_BIND_SERVICE=+eip /home/pidio/nr-server
/home/pidio/nr-server
