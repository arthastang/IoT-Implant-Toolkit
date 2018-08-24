#!/bin/sh

IFNAME=$1
CMD=$2
echo "$CMD"  >> /tmp/wifi_event.log

if [ "$CMD" = "CONNECTED" ]; then
    SSID=`wpa_cli -i$IFNAME status | grep ^ssid= | cut -f2- -d=`
    # configure network, signal DHCP client, etc.
fi

if [ "$CMD" = "DISCONNECTED" ]; then
    # remove network configuration, if needed
#    show_led 6
    /etc/init.d/dhcpc restart
fi
