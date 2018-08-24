#!/bin/sh

redundancy_mode=`uci get misc.log.redundancy_mode`

if [ "$redundancy_mode" = "1" ]; then
	cat /tmp/messages >> /data/usr/log/messages
	> /tmp/messages
	sync
	exit
fi

# for r1cm, etc
LOGGEN=5
# logfile
TMP_LOG=/tmp/messages
LOG=/data/usr/log/messages
INTER_LOG=/data/usr/log/messages.0

mkdir -p /data/usr/log

#
export LANG=C
#
. /lib/mico_common.sh

#
cat $TMP_LOG >> $LOG
> $TMP_LOG
sync

# we need to do the rotation
i=$LOGGEN
while [ $i -gt 0 ]; do
	# rotate one step
	newer=$(($i-1))
	# check if we need to compress
	if [ -f $LOG.$newer.gz ]; then
		# already compressed - just rotate
		mv $LOG.$newer.gz $LOG.$i.gz
	elif [ -f $LOG.$newer ]; then
		# need to compress
		mv $LOG.$newer $LOG.$i
		gzip $LOG.$i
	fi
	# next do the previous generation
	i=$(($i-1))
done

# rotate file: messages
mv $LOG $INTER_LOG
gzip $INTER_LOG
