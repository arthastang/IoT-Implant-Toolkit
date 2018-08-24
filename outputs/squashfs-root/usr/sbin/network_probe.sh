#! /bin/sh

host_list="www.mi.com www.baidu.com www.taobao.com www.qq.com"

gateway_check() {
    local dev="$1"
    local gw="$2"

    if [ "$gw" = "" ] || [ "$dev" = "" ]; then
	return 1
    fi

    ping -c 2 -W 2 -q "$gw" > /dev/null 2>&1
    if [ $? = 0 ]; then
	return 0
    fi

    arping -f -q -c 3 -w 2 -I "$dev" "$gw"
    if [ $? = 0 ]; then
	return 0
    fi 

    return 1
}

dns_check() {
    for th in $host_list; do
	/usr/bin/nslookup "$th" > /dev/null 2>&1
	if [ $? = 0 ]; then
            return 0
        fi
    done
    return 1
}

internet_check() {
    for th in $host_list; do
	ping -c 2 -W 2 -q "$th" > /dev/null 2>&1
        if [ $? = 0 ]; then
	    return 0
	fi
    done
    return 1
}

network_check() {
    local gw=$(/sbin/route -n | grep 'UG[ \t]' | awk '{print $2}')
    local dev=$(/sbin/route -n | grep 'UG[ \t]' | awk '{print $8}')
    local wireless=0 #0:ok; 1:error;
    local dns=0 #0:ok; 1:error;
    local internet=0 #0:ok; 1:error;

    gateway_check "$dev" "$gw" || {
        wireless=1
    }
    dns_check || {
	dns=1
    }
    internet_check || {
        internet=1
    }
    echo "wireless=""$wireless"";dns=""$dns"";internet=""$internet" > /tmp/mibrain/network_status
}

network_check
