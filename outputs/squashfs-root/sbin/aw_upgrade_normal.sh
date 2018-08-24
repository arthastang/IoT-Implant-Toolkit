#!/bin/sh

local flg_try_sys1=`read_misc sys1_failed`
local flg_try_sys2=`read_misc sys2_failed`
local flg_last=`read_misc last_success`
local flg_ota=`read_misc ota_reboot`

if [ x"$flg_try_sys1" != x"0" ] || [ x"$flg_try_sys1" != x"0" ]; then
	echo "save crash log"
fi

write_misc -a 0 -d 0 -o 0
write_misc -l `read_misc boot_rootfs`

echo "all servers are OK"
write_misc -b 1

echo "LED boot ok."
#echo 50 50 50 > /proc/ws2812/rgb0
