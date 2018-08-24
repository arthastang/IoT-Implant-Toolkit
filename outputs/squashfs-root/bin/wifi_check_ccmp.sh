#!/bin/sh

MICO_SYSLOG_BINDDEVICE="[MICOREGISTER] "
MICO_SYSLOG_PERFORMANCE="[wificheck] "

mico_log() {
    logger -t dhcp_done -p 3 "${MICO_SYSLOG_BINDDEVICE} ${MICO_SYSLOG_PERFORMANCE} $*"
}

_dhcpcheck=0
_dnscheck=0

while true;
do
sleep 5
ccmperr=`wl counters | grep ccmpundec | awk '{print $2}'`
if [ $ccmperr != "" -a $ccmperr != "0" ]; then
   mico_log "restart wifi find ccmp err"
   wl counters >> /tmp/wifi_error.log
   echo "" >> /tmp/wifi_error.log
#   wpa_cli reassoc >> /tmp/wifi_error.log
   /etc/init.d/wireless restart "wificheck" >> /tmp/wifi_error.log
fi

_dhcpcheck=$(($_dhcpcheck + 1))

__ipaddr=`ifconfig wlan0 | grep "inet addr"`
[ "${__ipaddr}" != "" ] && {
  _dhcpcheck=0
}

[ ${_dhcpcheck} -ge 15 ] && {
   mico_log "restart wifi dhcp faild"
   /etc/init.d/wireless restart "wificheck" >> /tmp/wifi_error.log
}

_dnscheck=$(($_dnscheck + 1))
_nameserver=`cat /tmp/resolv.conf.auto | grep nameserver`
[ "${_nameserver}" != "" ] && {
  _dnscheck=0
}

[ ${_dnscheck} -ge 15 ] && {
   mico_log "restart wifi dns faild"
   /etc/init.d/wireless restart "wificheck" >> /tmp/wifi_error.log
}

done
