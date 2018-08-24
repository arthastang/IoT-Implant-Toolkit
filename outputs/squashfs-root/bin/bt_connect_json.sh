#!/bin/sh

CONFIGNAMETMP="mibt_config.json.tmp"

if [ $# -lt 2 ]; then
  echo "usage:$0 <config_file> <enable>"
  exit 1
fi

discoverable=`cat $1|grep discoverable | awk -F "[\"\"]" '{print $4}'`
connectable=`cat $1|grep connectable | awk -F "[\"\"]" '{print $4}'`

  cp -f $1 /tmp/${CONFIGNAMETMP}
  sed -i "s|discoverable.*|discoverable\": \"$2\",|" /tmp/${CONFIGNAMETMP}
  sed -i "s|connectable.*|connectable\": \"$2\",|" /tmp/${CONFIGNAMETMP}
  cp -f /tmp/${CONFIGNAMETMP} $1
  echo "Modift BT Connectable(JSON):$2"

sync

