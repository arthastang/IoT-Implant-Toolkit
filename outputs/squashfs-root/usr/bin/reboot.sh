#!/bin/sh

/usr/bin/mphelper pause
/usr/sbin/easy_logcut
mkdir -p /data/status
touch /data/status/upload_log
/usr/bin/mphelper tone /usr/share/sound/shutdown.mp3
reboot


