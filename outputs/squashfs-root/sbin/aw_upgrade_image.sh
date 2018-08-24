#!/bin/sh
#$1: target upgrade package

. /sbin/aw_upgrade_utils.sh

UPGRADE_IMG_DIR=/tmp/upgrade
UPGRADE_LOG_FILE=/mnt/UDISK/upgrade.log

show_usage(){
    cat <<EOF
Usage: $0 prepare <image file> :
            prepare and md5 check image for upgrade. eg: $1 prepare /tmp/upgrade.tar.gz

       $0 upgrade :
            upgrade the prepared image.
       $0 version :
            set system version string
       $0 clean :
            clean the prepared image
EOF
}

upgrade_log(){
    #$1 msg
    busybox echo `busybox date`  $1
    #busybox echo `busybox date`  $1 >> $UPGRADE_LOG_FILE
}
set_system_version(){
    # $1 version string
    upgrade_log "set system version: $1"
    write_misc -v $1 >/dev/null
    sync
}
set_system_flag(){
    # $1 flag string
    upgrade_log "set system flag : $1"
    write_misc -c $1 >/dev/null
    sync
    #read_misc command
}
get_system_flag(){
    read_misc command
}
prepare_env(){
    #prepare env
    flag=`get_system_flag`

    if [ x$flag != x"boot-recovery" ]; then
        #current shell process is busybox, so busybox is already in dram
        #backup other needed tools
        UPGRADE_ROOT=/tmp/upgrade_root
        [ -f $UPGRADE_ROOT/bin/busybox ] && {
            upgrade_log "env already prepared!!"
            return 0
        }
        rm -rf $UPGRADE_ROOT
        mkdir -p $UPGRADE_ROOT/bin
        mkdir -p $UPGRADE_ROOT/sbin
        mkdir -p $UPGRADE_ROOT/lib

        #busybox
        cp /bin/busybox $UPGRADE_ROOT/bin/
        cp /lib/libcrypt.so* $UPGRADE_ROOT/lib/
        cp /lib/libm.so* $UPGRADE_ROOT/lib/
        cp /lib/libgcc_s.so* $UPGRADE_ROOT/lib/
        cp /lib/libc.so* $UPGRADE_ROOT/lib/

        shell_list="ls tar mkdir dd echo cat sh cp date df grep kill ln mount mv"
        for i in $shell_list; do
            ln -s $UPGRADE_ROOT/bin/busybox $UPGRADE_ROOT/bin/$i
        done
        ln -s $UPGRADE_ROOT/bin/busybox $UPGRADE_ROOT/bin/reboot

        #misc tools
        cp /sbin/read_misc $UPGRADE_ROOT/sbin/
        cp /sbin/write_misc $UPGRADE_ROOT/sbin/
        cp /sbin/aw_reboot.sh $UPGRADE_ROOT/sbin/

        export PATH=$UPGRADE_ROOT/bin/:$UPGRADE_ROOT/sbin/:$PATH
        export LD_LIBRARY_PATH=$UPGRADE_ROOT/lib

    fi
}
check_img_md5(){
    #$1 img file #2 md5 file
    #return: 0 - success ; 1 - fail
    md5_1=`busybox md5sum $1 | busybox awk '{print $1}'`
    md5_2=`cat $2`
    [ $md5_1 = $md5_2 ] && {
        upgrade_log "$1 md5 check success!"
        return 0
    }
    upgrade_log "check_img_md5 failed, target: $1 !"
    return 1
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
write_mmc_partition(){
    busybox dd of=/dev/by-name/$2 if=$1 bs=1024
    sync
}
write_mtd_partition(){
    #if varify failed,retry
    let retry=10
    while [ $retry -gt 0 ]
        do
        let retry=$retry-1
        verify_file=$UPGRADE_IMG_DIR/mtd_$2_verify
        mtd write $1 $2
        sync
        mtd verify $1 $2 &> $verify_file
        cat $verify_file | grep "Success"
        [ $? -eq 0 ] && {
            echo "$2: verify success!!!!"
            break
        }
        echo "$2: verify retry failed,retry $retry"
    done

}
write_emmc_partition(){
    # $1 img
    # $2 partition name
    upgrade_log "write_emmc_partition $1 > /dev/by-name/$2"
    [ -e /dev/by-name/$2 ] && {
        write_mmc_partition $1 $2
    }
}
write_nor_partition(){
    # $1 img
    # $2 partition name
    upgrade_log "write_nor_partition $1 > $2"
    cat /proc/mtd | grep "\"$2\""
    if [ $? -eq 0 ]; then
        write_mtd_partition $1 $2
    else
        upgrade_log "$2 mtd partition is not exsit"
    fi
}
write_nand_partition(){
    # $1 img
    # $2 partition name
    upgrade_log "write_nand_partition $1 > /dev/by-name/$2"
    [ -e /dev/by-name/$2 ] && {
        write_mmc_partition $1 $2
    }
}
do_write_partition(){
    # $1 img
    # $2 partition name
    [ -e $1 ] && {
        #emmc
        [ -e /dev/mmcblk0 ] && {
            write_emmc_partition $1 $2
        }
        #nand
        [ -e /dev/nanda ] && {
            write_nand_partition $1 $2
        }
        #nor
        [ -e /dev/mtdblock0 ] && {
            write_nor_partition $1 $2
        }
    }
}
do_upgrade_image(){
    echo do_upgrade_image ......

    prepare_env

    [ -f $UPGRADE_IMG_DIR/$RAMDISK_IMG ] && {
        #set system misc flag
        set_system_flag "upgrade_pre"
        #fail #1, reboot ->
        #         boot from boot partition ->
        #         upgrade process ->
        #         get all image ->
        #         do again
        if [ -e /dev/by-name/extend ];then
            do_write_partition $UPGRADE_IMG_DIR/$RAMDISK_IMG "extend"
        else
            do_write_partition $UPGRADE_IMG_DIR/$RAMDISK_IMG "recovery"
        fi
        #reboot -f #test
        set_system_flag "boot-recovery"
        #fail #1 end
        rm -rf $UPGRADE_IMG_DIR/$RAMDISK_IMG
    }

    flag=`get_system_flag`
    [ -f $UPGRADE_IMG_DIR/$BOOT_IMG ] && [ -f $UPGRADE_IMG_DIR/$ROOTFS_IMG ] && [ x$flag = x"boot-recovery" ] && {
        #if fail #2, reboot ->
        #            boot from extend partition(initramfs) ->
        #            upgrade process ->
        #            get target image ->
        #            do again
        #reboot -f #test
        do_write_partition $UPGRADE_IMG_DIR/$BOOT_IMG "boot"
        do_write_partition $UPGRADE_IMG_DIR/$ROOTFS_IMG "rootfs"

        #clear extroot-uuid flag
        mkdir -p /tmp/overlay
        try_mount "rootfs_data" "/tmp/overlay"
        [ -f /tmp/overlay/etc/.extroot-uuid ] && {
            upgrade_log "clear overlay extroot-uuid"
            rm /tmp/overlay/etc/.extroot-uuid
        }

        set_system_flag "upgrade_post"
        #fail #2 end
        rm $UPGRADE_IMG_DIR/$ROOTFS_IMG $UPGRADE_IMG_DIR/$BOOT_IMG
    }

    [ -f $UPGRADE_IMG_DIR/$USR_IMG ] && {
        #if fail #3, reboot ->
        #            boot from boot partition ->
        #            upgrade process ->
        #            get usr image ->
        #            upgrade $USR_IMG
        do_write_partition $UPGRADE_IMG_DIR/$USR_IMG "extend"

        set_system_flag "upgrade_end"

        #reboot -f #test
        #fail #3 end
        rm $UPGRADE_IMG_DIR/$USR_IMG
    }

}
do_prepare_image(){
    # $1 image file path
    # $2 image file name
    # $3 --none-compress image file is none compress
    #    no set image file is compress file
    upgrade_log "unpack image start..."

    if [ -n $3 ] && [ x$3 = x"--none-compress" ]; then
        mkdir -p $UPGRADE_IMG_DIR
        cp $1/$2 /tmp
        mv /tmp/$2  $UPGRADE_IMG_DIR
    else
        #copy package to dram
        cp $1/$2 /tmp/

        cd /tmp && {
            tar -zxvf /tmp/$2 && rm /tmp/$2
            [ $? -eq 1 ] && {
                upgrade_log "no enongh space to unpack"
                exit $ERR_NOT_ENOUGH_SPACE
            }
            [ -d $TARGET_DIR ] && list="$TARGET_DIR/$BOOT_IMG $TARGET_DIR/$ROOTFS_IMG"
            [ -d $RAMDISK_DIR ] && list="$RAMDISK_DIR/$RAMDISK_IMG"
            [ -d $USR_DIR ] && list="$USR_DIR/$USR_IMG"
            echo .......... $list
            for i in $list;do
                check_img_md5 $i $i.md5
                [ $? -eq 1 ] && {
                    rm -rf $RAMDISK_DIR $TARGET_DIR $USR_DIR
                    exit $ERR_MD5_CHECK_FAILED
                }
            done
            mkdir -p $UPGRADE_IMG_DIR
            mv $list $UPGRADE_IMG_DIR  #move
            rm -rf $RAMDISK_DIR $TARGET_DIR $USR_DIR   #clean
        }
    fi
    upgrade_log "unpack image finish..."
}
##############################################
#check args
do_upgrade(){
    if [ $# -lt 1 ]; then
        show_usage
        exit $ERR_ILLEGAL_ARGS
    elif [ x$1 = x"prepare" ] && [ $# -ge 3 ] && [ -f $2/$3 ]; then
        upgrade_log "start to prepare -->>> $2/$3 <<<--"
        do_prepare_image $2 $3 $4
    elif [ x$1 = x"upgrade" ]; then
        upgrade_log "start to upgrade"
        do_upgrade_image
    elif [ x$1 = x"clean" ]; then
        upgrade_log "clean the prepared image"
        rm -rf $UPGRADE_IMG_DIR
        rm -rf $RAMDISK_DIR* $TARGET_DIR*
    elif [ x$1 = x"version" ] && [ -ne $2 ]; then
        set_system_version $2
    else
        show_usage
        exit $ERR_ILLEGAL_ARGS
    fi
}
upgrade_log " "
upgrade_log " "
