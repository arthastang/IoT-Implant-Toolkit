#!/bin/sh

redundancy_mode=`uci get misc.log.redundancy_mode`

LOG_TMP_FILE_PATH="/tmp/mico.log"
LOG_ZIP_FILE_PATH="/tmp/log.tar.gz"

WIRELESS_FILE_PATH="/etc/config/wireless"
WIRELESS_STRIP='/tmp/wireless.conf'
NETWORK_FILE_PATH="/etc/config/network"
NETWORK_STRIP="/tmp/network.conf"
CRONTAB="/etc/crontabs/root"

LOG_DIR="/data/usr/log/"
LOGREAD_FILE_PATH="/data/usr/log/messages"
LOGREAD0_FILE_PATH="/data/usr/log/messages.0"
LOG_WIFI_AYALYSIS="/data/usr/log/wifi_analysis.log"
LOG_WIFI_AYALYSIS0="/data/usr/log/wifi_analysis.log.0.gz"
PANIC_FILE_PATH="/data/usr/log/panic.message"
TMP_LOG_FILE_PATH="/tmp/messages"
TMP_WIFI_LOG_ANALYSIS="/tmp/wifi_analysis.log"
TMP_WIFI_LOG="/tmp/wifi.log"
LOG_MEMINFO="/proc/meminfo"
LOG_SLABINFO="/proc/slabinfo"
GZ_LOGS=""

hardware=`uci get /usr/share/mico/mico_version.version.HARDWARE`

rm -f $LOG_TMP_FILE_PATH

cat $TMP_LOG_FILE_PATH >> $LOGREAD_FILE_PATH
> $TMP_LOG_FILE_PATH

cat $TMP_WIFI_LOG_ANALYSIS >> $LOG_WIFI_AYALYSIS
> $TMP_WIFI_LOG_ANALYSIS

echo "==========SN" >> $LOG_TMP_FILE_PATH
nvram get SN >> $LOG_TMP_FILE_PATH

echo "==========uptime" >> $LOG_TMP_FILE_PATH
uptime >> $LOG_TMP_FILE_PATH

echo "==========df -h" >> $LOG_TMP_FILE_PATH
df -h >> $LOG_TMP_FILE_PATH

echo "==========bootinfo" >> $LOG_TMP_FILE_PATH
bootinfo >> $LOG_TMP_FILE_PATH

echo "==========tmp dir" >> $LOG_TMP_FILE_PATH
ls -lh /tmp/ >> $LOG_TMP_FILE_PATH
du -sh /tmp/* >> $LOG_TMP_FILE_PATH

echo "==========ifconfig" >> $LOG_TMP_FILE_PATH
ifconfig >> $LOG_TMP_FILE_PATH

echo "==========/proc/net/dev" >> $LOG_TMP_FILE_PATH
cat /proc/net/dev >> $LOG_TMP_FILE_PATH

echo "==========/proc/bus/pci/devices" >> $LOG_TMP_FILE_PATH
cat /proc/bus/pci/devices >> $LOG_TMP_FILE_PATH

cat $NETWORK_FILE_PATH | grep -v -e'password' -e'username' > $NETWORK_STRIP

cat $WIRELESS_FILE_PATH | grep -v 'key' > $WIRELESS_STRIP

echo "==========ps" >> $LOG_TMP_FILE_PATH
ps >> $LOG_TMP_FILE_PATH


log_exec()
{
    echo "========== $1" >>$LOG_TMP_FILE_PATH
    eval "$1" >> $LOG_TMP_FILE_PATH
}

list_messages_gz(){
    for file in `ls /data/usr/log/ | grep ^messages\.[1-4]\.gz$`; do
        GZ_LOGS=${GZ_LOGS}" /data/usr/log/"${file}
    done
}

#On R1D, the follow print to UART.
echo "==========dmesg:" >> $LOG_TMP_FILE_PATH
dmesg >> $LOG_TMP_FILE_PATH
sleep 1
echo "==========meminfo" >> $LOG_TMP_FILE_PATH
cat $LOG_MEMINFO >> $LOG_TMP_FILE_PATH

echo "==========topinfo" >> $LOG_TMP_FILE_PATH
top -b -n1 >> $LOG_TMP_FILE_PATH

echo "==========slabinfo"  >> $LOG_TMP_FILE_PATH
cat $LOG_SLABINFO >> $LOG_TMP_FILE_PATH

list_messages_gz

# busybox's tar requires every source file existing!!
[ -e "$NETWORK_STRIP" ] || NETWORK_STRIP=
move_files="$LOG_TMP_FILE_PATH $NETWORK_STRIP $WIRELESS_STRIP"
[ -e "$CRONTAB" ] || CRONTAB=
dup_files="$CRONTAB"

[ -e "$LOGREAD_FILE_PATH" ] || LOGREAD_FILE_PATH=
[ -e "$LOGREAD0_FILE_PATH" ] || LOGREAD0_FILE_PATH=
[ -e "$PANIC_FILE_PATH" ] || PANIC_FILE_PATH=
[ -e "$LOG_WIFI_AYALYSIS" ] || LOG_WIFI_AYALYSIS=
[ -e "$LOG_WIFI_AYALYSIS0" ] || LOG_WIFI_AYALYSIS0=
[ -e "$GZ_LOGS" ] || GZ_LOGS=
[ -e "$LOG_DIR" ] || LOG_DIR=
[ -e "$TMP_WIFI_LOG" ] || TMP_WIFI_LOG=
if [ "$redundancy_mode" = "1" ]; then
    redundancy_files="$LOGREAD_FILE_PATH $LOGREAD0_FILE_PATH $PANIC_FILE_PATH $LOG_WIFI_AYALYSIS $LOG_WIFI_AYALYSIS0 $GZ_LOGS"
else
    redundancy_files="$LOG_DIR $PANIC_FILE_PATH $TMP_WIFI_LOG"
fi
tar -zcf $LOG_ZIP_FILE_PATH $move_files $dup_files $redundancy_files
rm "$move_files" > /dev/null
