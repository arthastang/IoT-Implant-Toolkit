#! /bin/sh

# this file maybe obsolete soon

device_id=""

_dummy_device_id_get(){
    local _sn=$(getmac.sh sn)
    local _mac=$(getmac.sh mac)
    
    if [ "" != $_sn ]; then
        device_id=$_sn
    elif [ "" != $_mac ]; then
        device_id=$_mac
    fi
}

_wuw_audio_upload(){
    local _vendor_name=$1
    local _file_name=$2
    
    _dummy_device_id_get
    [ "" = $device_id ] && {
        return
    }

    curl "https://speech-preview.ai.xiaomi.com/speech/v1.0/dump?app_id=2882303761517406012&token=5621740649012" \
        -H "Content-Type: audio/pcm; channel=1; rate=16000" \
        -H "X-Device-Id: "$device_id \
        -H "X-Request-Id:" \
        -H "X-Wakeup-Vendor: "$_vendor_name \
        -H "X-Wakeup-Word: %E4%BD%A0%E5%A5%BD%E5%B0%8F%E7%B1%B3" \
        --data-binary "@$_file_name" \
        --connect-timeout 3 \
        #-v

    return
}

if [ 2 != $# ]; then
    return;
fi
# $1: vendor name
# $2: file to upload
if [ ! -f $2 ]; then
    return
fi    

_wuw_audio_upload $1 $2
rm -f $2 # remove always
