#!/bin/sh
MICO_SYSLOG_BINDDEVICE="[MICOREGISTER]"
export LED_PARENT=bind_device.sh

mico_log() {
    logger -t miio_helper -p 3 "${MICO_SYSLOG_BINDDEVICE} $*"
}

set_bind_and_restart_service() {
    sleep 20
    [ ! -f "/data/status/config_done" ] && {
        mico_log "set bind by messageagent"
        ubus call mibt ble '{"action":"hidden"}'
        mkdir -p /data/status
        touch /data/status/config_done
        /bin/shut_led 6
#do not notify
    }
}

case $1 in
*)
set_bind_and_restart_service
;;
esac
