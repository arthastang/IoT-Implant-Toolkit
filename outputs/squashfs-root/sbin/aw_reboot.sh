#!/bin/sh
REAL_REBOOT=/sbin/reboot
for i in $*; do
    [ x$i = x"efex" ] && {
        write_misc -c efex; /sbin/reboot -f $*
    }
    [ x$i = x"boot-recovery" ] && {
        write_misc -c boot-recovery; /sbin/reboot -f $*
    }
done
/sbin/reboot $*
