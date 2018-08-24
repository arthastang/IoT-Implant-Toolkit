#!/bin/sh
#

. /bin/boardupgrade.sh

hndmsg() {
	if [ -n "$msg" ]; then
		echo "$msg" >> /dev/kmsg 2>/dev/null
		if [ `pwd` = "/tmp" ]; then
			rm -rf $filename 2>/dev/null
		fi
		exit 1
	fi
}

upgrade_param_check() {
	if [ -z "$1" -o ! -f "$1" ]; then
		klogger "USAGE: $0 input.bin [1:restore defaults, 0:don't] [1:don't reboot, 0:reboot]"
		exit 1
	fi
	
	flg_ota=`read_misc ota_reboot`
	if [ "$flg_ota" = "1" ]; then
		klogger "flag_ota_reboot is set ?"
		exit 1
	fi

	cur_ver=`cat /usr/share/mico/version | grep "option ROM" | awk '{ print $3 }'`
	klogger "Begin Ugrading..., current version: $cur_ver"
	echo 3 > /proc/sys/vm/drop_caches
}

upgrade_prepare_dir() {
	absolute_path=`echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"`
	mount -o remount,size=80% /tmp
	rm -rf /tmp/system_upgrade
	mkdir -p /tmp/system_upgrade

	if [ ${absolute_path:0:4} = "/tmp" ]; then
		file_in_tmp=1
		mv $absolute_path /tmp/system_upgrade/
	else
		file_in_tmp=0
		cp $absolute_path /tmp/system_upgrade/
	fi
}

upgrade_done_set_flags() {
	# tell server upgrade is finished

	# update setting when upgrading
	write_misc -o 1
	/bin/show_led 0

	if [ "$3" = "1" ]; then
		klogger "Skip rebooting..."
	else
		klogger "Rebooting..."
		set_upgrade_status 'reboot'
		reboot
	fi
}

#check pid exist
pid_file="/tmp/pid_xxxx"
if [ -f $pid_file ]; then
	exist_pid=`cat $pid_file`
	if [ -n $exist_pid ]; then
		kill -0 $exist_pid 2>/dev/null
		if [ $? -eq 0 ]; then
			klogger "Upgrading, exit... $?"
			exit 1
		else
			echo $$ > $pid_file
		fi
	else
		echo $$ > $pid_file
	fi
else
	echo $$ > $pid_file
fi

upgrade_param_check $1

# image verification...
klogger -n "Verify Image: $1..."
mkxqimage -r -v "$1"
if [ "$?" = "0" ]; then
	klogger "Checksum O.K."
else
	msg="Check Failed!!!"
	hndmsg
fi

# stop services
board_prepare_upgrade
board_start_upgrade_led

# prepare to extract file
filename=`basename $1`
upgrade_prepare_dir $1
cd /tmp/system_upgrade

# start board-specific upgrading...
klogger "Begin Upgrading and Rebooting..."
board_system_upgrade $filename $2 $3

# some board may reset after system upgrade and not reach here
# clean up
cd /
rm -rf /tmp/system_upgrade

upgrade_done_set_flags $1 $2 $3

