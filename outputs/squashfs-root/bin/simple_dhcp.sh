#!/bin/sh

MICO_SYSLOG_BINDDEVICE="[MICOREGISTER] "
MICO_SYSLOG_PERFORMANCE="[performance] "
export LED_PARENT=simple_dhcp.sh

mico_log() {
    logger -t dhcp_done -p 3 "${MICO_SYSLOG_BINDDEVICE} ${MICO_SYSLOG_PERFORMANCE} $*"
}

[ -z "$1" ] && echo 'Error: should be called from udhcpc' && exit 1

RESOLV_CONF="/tmp/resolv.conf.auto"
RESOLV_CONF_TMP="/tmp/resolv.conf.auto.tmp"
[ -n "$broadcast" ] && BROADCAST="broadcast $broadcast"
[ -n "$subnet" ] && NETMASK="netmask $subnet"

setup_interface () {
    /sbin/ifconfig $interface $ip $BROADCAST $NETMASK

    if [ -n "$router" ] ; then
	while route del default gw 0.0.0.0 dev $interface ; do
            true
        done
	
        for i in $router ; do
            route add default gw $i dev $interface
        done
    fi
    echo -n > $RESOLV_CONF_TMP
    [ -n "$domain" ] && echo search $domain >> $RESOLV_CONF_TMP
    for i in $dns ; do
        echo nameserver $i >> $RESOLV_CONF_TMP
    done
    cp $RESOLV_CONF_TMP $RESOLV_CONF -f >> /dev/null
}

deconfig_interface() {
    /sbin/ifconfig $interface 0.0.0.0
}

case "$1" in
	deconfig)
		deconfig_interface
	;;
	renew)
		setup_interface
                mico_log "[renew dhcp]"
	;;
        bound)
                setup_interface
                /etc/init.d/dnsmasq  restart 1>/dev/null 2>&1
                mkdir -p /data/status/
                
                [ -f /data/status/dhcp_done ] && logger stat_points_none spk_wifi_reconnect=1
                [ ! -f /data/status/dhcp_done ] && logger stat_points_none spk_wifi_connect=1
                echo "$interface $ip $router" > /data/status/dhcp_done
                mico_log "[dhcp restart services, services:[dlna,mitv-disc,alarm]]"
                /etc/init.d/dlnainit restart 1>/dev/null 2>&1
                /etc/init.d/mitv-disc  restart 1>/dev/null 2>&1
                /etc/init.d/alarm restart 1>/dev/null 2>&1
#                /etc/init.d/messagingagent restart 1>/dev/null 2>&1
                /bin/shut_led 6
        ;;
esac
