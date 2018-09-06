#!/bin/sh

NUM=`cat pcms/log.txt | tail -1`
NUM=$(($NUM+1))

echo "Start receiving audios...."
echo "File number start with: $NUM"

while true
do
	nc -lp 1111 > pcms/$NUM.pcm
	echo "Receive audio $NUM.pcm"
	echo "$NUM" > pcms/log.txt
	NUM=$(($NUM+1))
	#sleep 10
done
