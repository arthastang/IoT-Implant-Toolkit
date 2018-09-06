#!/system/bin/sh

if [ -f /data/oldfiles.log ]
then
	while true
	do
		newfile=`ls -t /data/media/0/WifiTranslator/pcm/ | head -1`
		cat /data/oldfiles.log | grep $newfile >/dev/null
		if [ $? -eq 1 ]
		then
			echo "Find a new file:$newfile"
			echo "Send it to server..."
			sleep 2
			nc 192.168.0.123 1111 < /data/media/0/WifiTranslator/pcm/$newfile
			echo $newfile >> /data/oldfiles.log
		else
			echo "No new files"
		fi
	sleep 5
	done

else
	ls -t -r /data/media/0/WifiTranslator/pcm/ > /data/oldfiles.log
	echo "Save old files to log"
fi
