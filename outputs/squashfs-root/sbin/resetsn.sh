#!/bin/sh

[ -f /data/etc/binfo ] && {
	rm /data/etc/binfo
}

echo "please enter sn:"
read sn
write_private -s $sn

echo "please enter mac_wifi:"
read mac_wifi
write_private -w $mac_wifi

echo "please enter mac_bt:"
read mac_bt
write_private -b $mac_bt

echo "please enter miio_did:"
read miio_did
write_private -d $miio_did

echo "please enter miiio_key:"
read miio_key
write_private -k $miio_key

echo "system will reboot"

sync

reboot
