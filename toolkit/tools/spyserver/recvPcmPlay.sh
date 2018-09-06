#!/bin/sh

NUM=`cat pcms/log.txt | tail -1`

echo "Start receiving audios..."
echo "File number start with: $NUM"

while true
do
	nc -lp 1111 > pcms/$NUM.pcm
	echo "Receive audio $NUM.pcm"
	echo "$NUM" > pcms/log.txt
	echo "Play $NUM.pcm"
	aplay -f S16_LE -r 16000 -t raw pcms/$NUM.pcm
	NUM=$(($NUM+1))

done
