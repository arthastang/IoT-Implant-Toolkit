#!/bin/sh

NUM=1

echo "Download audios from server and play..."
while true
do
	wget http://42.51.216.55:13579/log.txt -O log.txt
	updatenum=`cat log.txt | tail -1`
	#echo $updatenum
	while [ $NUM -le $updatenum ]
	do
		if [ -e $NUM.pcm ]
		then	
			echo "No new files!"
		else
			wget -nc http://42.51.216.55:13579/$NUM.pcm
			echo "Play $NUM.pcm..."
			aplay -f S16_LE -r 16000 -t raw $NUM.pcm
		fi
		NUM=$(($NUM+1))
		echo "num: $NUM"
		sleep 5
	done
	sleep 5
done
