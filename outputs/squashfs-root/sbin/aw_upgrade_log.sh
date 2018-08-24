#!/bin/sh
if [ -e /dev/by-name/extend];then
    /sbin/aw_upgrade_process.sh 1>/dev/ttyS0 2>/dev/ttyS0
else
    /sbin/aw_upgrade_normal.sh 1>/dev/ttyS0 2>/dev/ttyS0
#    /bin/test_breath &
fi
