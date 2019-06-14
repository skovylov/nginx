#!/bin/sh

# set NGINX_TZ env var to right timezone
# by default no timezone is setted and uses UTC

ZONEPREF=/usr/share/zoneinfo/
[ -f $ZONEPREF$NGINX_TZ ] && ln -sf $ZONEPREF$NGINX_TZ /etc/localtime

nginx -g "daemon off;"
