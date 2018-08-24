#!/bin/sh

. /sbin/aw_upgrade_utils.sh
. /sbin/aw_upgrade_image.sh
if [ -f /sbin/aw_upgrade_vendor.sh ]; then
	. /sbin/aw_upgrade_vendor.sh
else
	. /sbin/aw_upgrade_vendor_default.sh
fi

#UPGRADE_SH=/sbin/aw_upgrade_image.sh
UPGRADE_SH=do_upgrade

download_image(){
    # $1 image name  $2 DIR
    image_name=$1
    store_dir=$2
    type download_image_vendor 1>/dev/null 2>/dev/null
    [ $? -ne 0 ] && {
        echo "vendor download image is available!"
        exit $ERR_VENDOR_HOOK_NOT_SUPPORT
    }
    download_image_vendor $image_name $store_dir $URL
}
try_mount(){
    # $1 partition name $2 mount dir
    format_list="ext4 jffs2 vfat"
    for i in $format_list; do
        echo "mounting $i /dev/by-name/$1 -> $2"
        mount -t $i /dev/by-name/$1 $2
        [ $? -eq 0 ] && break
    done
}
check_network(){
    type check_network_vendor 1>/dev/null 2>/dev/null
    [ $? -ne 0 ] && {
        echo "vendor check network is no available!"
        exit $ERR_VENDOR_HOOK_NOT_SUPPORT
    }

    check_network_vendor $1
    [ $? -ne 0 ] && {
        exit $ERR_NETWORK_FAILED
    }
}
set_version(){
    # $1 version
    $UPGRADE_SH version $1
}
upgrade_start(){
    # return  0 -> start upgrade 1 -> no upgrade
    type upgrade_start_vendor 1>/dev/null 2>/dev/null
    [ $? -ne 0 ] || {
        upgrade_start_vendor $@
        return $?
    }
    return 1
}
upgrade_finish(){
    type upgrade_finish_vendor 1>/dev/null 2>/dev/null
    [ $? -ne 0 ] || {
        upgrade_finish_vendor
    }
}
download_prepare_image(){
    # $1 image
    if [ x$IS_COMPRESS_IMAGE = x"--none-compress" ];then
        [ x$1 = x$RAMDISK_PKG ] && {
            file=$RAMDISK_IMG
            download_image $file /tmp
            $UPGRADE_SH prepare /tmp $file $IS_COMPRESS_IMAGE
        }
        [ x$1 = x$TARGET_PKG ] && {
            file=$BOOT_IMG
            download_image $file /tmp
            $UPGRADE_SH prepare /tmp $file $IS_COMPRESS_IMAGE
            file=$ROOTFS_IMG
            download_image $file /tmp
            $UPGRADE_SH prepare /tmp $file $IS_COMPRESS_IMAGE
        }
        [ x$1 = x$USR_PKG ] && {
            file=$USR_IMG
            download_image $file /tmp
            $UPGRADE_SH prepare /tmp $file $IS_COMPRESS_IMAGE
        }
    else
        download_image $1 /tmp
        $UPGRADE_SH prepare /tmp $1 $IS_COMPRESS_IMAGE
    fi
}
get_args(){
    [ -f $UPGRADE_SETTING_PATH/.image_path ]     && export LOCAL_IMG_PATH=`cat $UPGRADE_SETTING_PATH/.image_path`
    [ -f $UPGRADE_SETTING_PATH/.image_compress ] && export IS_COMPRESS_IMAGE=`cat $UPGRADE_SETTING_PATH/.image_compress`
    [ -f $UPGRADE_SETTING_PATH/.image_domain ]   && export DOMAIN=`cat $UPGRADE_SETTING_PATH/.image_domain`
    [ -f $UPGRADE_SETTING_PATH/.image_url ]      && export URL=`cat $UPGRADE_SETTING_PATH/.image_url`

    echo setting args LOCAL_IMG_PATH:    $LOCAL_IMG_PATH
    echo setting args IS_COMPRESS_IMAGE: $IS_COMPRESS_IMAGE
    echo setting args DOMAIN:            $DOMAIN
    echo setting args URL:               $URL
}
boot_recovery_mode(){
    # boot-reocvery mode
    # -->get target_sys.tar.gz
    # ---->write image to "boot", "rootfs", "extend" partition
    echo "boot_recovery_mode"

    # umount the usr partition; if failed, ignore
    umount /usr
    umount /usr

    #try to mount rootfs_data partition
    try_mount "rootfs_data" "/overlay"
    try_mount "UDISK" "/mnt/UDISK"

    $UPGRADE_SH clean

    upgrade_start boot_recovery

    get_args

    if [ -f $LOCAL_IMG_PATH/$TARGET_PKG ] && [ -f $IMG_PATH/$USR_PKG; then
        $UPGRADE_SH prepare $LOCAL_IMG_PATH $TARGET_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH prepare $LOCAL_IMG_PATH $USR_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
    else
        # get current wifi wpa_supplicant.conf
        [ -f /overlay/etc/wifi/wpa_supplicant.conf ] && {
            echo "get wpa_supplicant from overlay"
            echo "old wpa_supplicant.config"
            cat /etc/wifi/wpa_supplicant.conf
            cp /overlay/etc/wifi/wpa_supplicant.conf /etc/wifi/
            echo "new wpa_supplicant.config"
            cat /etc/wifi/wpa_supplicant.conf
        }

        check_network $DOMAIN

        download_prepare_image $TARGET_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
        download_prepare_image $USR_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
    fi

    #upgrade_start boot_recovery
    #$UPGRADE_SH upgrade
    upgrade_finish
}
upgrade_pre_mode(){
    # upgrade_pre mode
    # -->get ramdisk_sys.tar.gz target_sys.tar.gz
    # ---->write ramdisk to "extend"
    # ------>write image to "boot", "rootfs", "extend" partition
    echo "upgrade_pre_mode"

    # umount the usr partition; if failed, ignore
    umount /usr
    umount /usr

    $UPGRADE_SH clean

    upgrade_start pre

    get_args

    if [ -f $LOCAL_IMG_PATH/$RAMDISK_PKG ] && [ -f $LOCAL_IMG_PATH/$TARGET_PKG ]; then
        $UPGRADE_SH prepare $LOCAL_IMG_PATH $RAMDISK_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH prepare $LOCAL_IMG_PATH $TARGET_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH prepare $LOCAL_IMG_PATH $USR_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
    else
        check_network $DOMAIN
        download_prepare_image $RAMDISK_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
        download_prepare_image $TARGET_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
        download_prepare_image $USR_PKG $IS_COMPRESS_IMAGE
        $UPGRADE_SH upgrade
    fi

    #upgrade_start pre

    #if [ $? -eq 0 ] || [ ! x$NORMAL_MODE = x"normal" ]; then
    #    $UPGRADE_SH upgrade
    #fi
    upgrade_finish
}
upgrade_post_mode(){
    # upgrade_post mode
    # -->get usr_sys.tar.gz
    # ---->write image to "extend" partition
    echo "upgrade_post_mode"

    umount /usr
    umount /usr

    $UPGRADE_SH clean

    get_args

    if [ -f $LOCAL_IMG_PATH/$USR_PKG ]; then
        $UPGRADE_SH prepare $LOCAL_IMG_PATH $USR_PKG $IS_COMPRESS_IMAGE
    else
        check_network $DOMIAN
        download_prepare_image $USR_PKG $IS_COMPRESS_IMAGE
    fi

    upgrade_start post
    if [ $? -eq 0 ] || [ ! x$NORMAL_MODE = x"normal" ]; then
        $UPGRADE_SH upgrade
    fi
    upgrade_finish
}
upgrade_end_mode(){
    # upgrade_end mode
    # wait for next upgrade
    echo "wait for next upgrade!!"
    #clear
    [ -f $UPGRADE_SETTING_PATH/.image_path ] && rm -rf $UPGRADE_SETTING_PATH/.image_path
    [ -f $UPGRADE_SETTING_PATH/.image_compress ] && rm -rf $UPGRADE_SETTING_PATH/.image_compress
    [ -f $UPGRADE_SETTING_PATH/.image_url ] && rm -rf $UPGRADE_SETTING_PATH/.image_url
    [ -f $UPGRADE_SETTING_PATH/.image_domain ] && rm -rf $UPGRADE_SETTING_PATH/.image_domain
}
####################################################
modeflag=0
check_mode(){
    [ $modeflag -eq 1 ] && {
        echo "mode conflict, must be set -p or -f"
        exit $ERR_ILLEGAL_ARGS
    }
    modeflag=1
}
while getopts "fpl:nu:d:" opt; do
    case $opt in
    f)
        check_mode
        mode="--force"
        ;;
    p)
        check_mode
        mode="--post"
        ;;
    l)
        [ ! -d $OPTARG ] && {
            echo "-l $OPTARG, the settting path is unavailable"
            exit $ERR_ILLEGAL_ARGS
        }
        mkdir -p $UPGRADE_SETTING_PATH
        echo $OPTARG > $UPGRADE_SETTING_PATH/.image_path
        ;;
    n)
        is_compress_image='--none-compress'
        mkdir -p $UPGRADE_SETTING_PATH
        echo $is_compress_image > $UPGRADE_SETTING_PATH/.image_compress
        echo "using none compress image to upgrade!"
        ;;
    u)
        mkdir -p $UPGRADE_SETTING_PATH
        echo $OPTARG > $UPGRADE_SETTING_PATH/.image_url
        echo "using setting URL: $OPTARG"
        ;;
    d)
        mkdir -p $UPGRADE_SETTING_PATH
        echo $OPTARG > $UPGRADE_SETTING_PATH/.image_domain
        echo "using setting DOMAIN: $OPTARG"
        ;;
    \?)
        echo "Invalid option: -$OPTARG"
        exit $ERR_ILLEGAL_ARGS
        ;;
    esac
done
# force to upgrade
if [ -n $mode ] && [ x$mode = x"--force" ]; then
    export NORMAL_MODE=normal
    upgrade_pre_mode
    exit 0
fi

if [ -n $mode ] && [ x$mode = x"--post" ]; then
    export NORMAL_MODE=normal
    upgrade_post_mode
    exit 0
fi

system_flag=`read_misc command`
if [ x$system_flag = x"boot-recovery" ]; then
    boot_recovery_mode
elif [ x$system_flag = x"upgrade_pre" ]; then
    upgrade_pre_mode
elif [ x$system_flag = x"upgrade_post" ]; then
    upgrade_post_mode
elif [ x$system_flag = x"upgrade_end" ]; then
    upgrade_end_mode
else
    upgrade_end_mode
fi
