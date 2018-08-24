#!/bin/sh
MICO_SYSLOG_BINDDEVICE="[MICOREGISTER]"

mico_log() {
    logger -t miio_helper -p 3 "${MICO_SYSLOG_BINDDEVICE} $*"
}

restart_bind_service() {
    /usr/bin/mphelper pause
    mico_log "unregister device & reboot"
    rm -r -f /data/* > /dev/null 2>&1
    rm -r -f /data/.* >/dev/null 2>&1
    /usr/bin/mphelper tone /usr/share/sound/shutdown.mp3
    reboot
}

case $1 in
*)
restart_bind_service
;;
esac
