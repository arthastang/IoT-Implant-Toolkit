#!/bin/sh
#

klogger(){
	local msg1="$1"
	local msg2="$2"

	if [ "$msg1" = "-n" ]; then
		echo  -n "$msg2" >> /dev/kmsg 2>/dev/null
	else
		echo "$msg1" >> /dev/kmsg 2>/dev/null
	fi

	return 0
}

stop_service(){
	echo 3 > /proc/sys/vm/drop_caches
}

restore_service(){
	return
}

write_partition(){
	echo $2
	echo $1
    busybox dd of=/dev/by-name/$2 if=$1 bs=1024
    sync
}


board_prepare_upgrade() {
	stop_service
}

board_start_upgrade_led() {
	/bin/show_led 2
	return
}

board_system_upgrade() {
	local filename=$1
	
	mkxqimage -r -x $filename
	[ "$?" = "0" ] || {
		klogger "OTA cannot extract files"
		rm -rf $filename
		#for stop key services before, now reboot
		/bin/show_led 0	
		reboot
		exit 1
	}
	[ -f lx01_version ] && {
		echo "updating to `cat lx01_version | grep "option ROM" | awk '{ print $3 }'`..."
	}
	
	os_cur=`read_misc boot_rootfs`

	if [ $os_cur -eq 0 ]; then
	  ota_part=2
	  echo "updating partition 2..."
  else
	  ota_part=1
	  echo "updating partition 1..."
  fi

  [ -f u-boot.fex ] && ota-burnuboot u-boot.fex
  #echo "burn uboot return $?"
  [ -f kernel.img ] && write_partition kernel.img kernel$ota_part
  [ -f rootfs.img ] && write_partition rootfs.img rootfs$ota_part

	return 0
}
