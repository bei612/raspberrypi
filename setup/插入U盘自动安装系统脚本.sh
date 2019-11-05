
KERNEL=="sda1",SUBSYSTEM=="block",RUN+="/home/pi/install-os.sh"


KERNEL!="sd*", GOTO="media_by_label_auto_mount_end"
SUBSYSTEM!="block",GOTO="media_by_label_auto_mount_end"
IMPORT{program}="/sbin/blkid -o udev -p %N"
ENV{ID_FS_TYPE}=="", GOTO="media_by_label_auto_mount_end"
ENV{ID_FS_LABEL}!="", ENV{dir_name}="%E{ID_FS_LABEL}"
ENV{ID_FS_LABEL}=="", ENV{dir_name}="Untitled-%k"
ACTION=="add", ENV{mount_options}="relatime,sync" 
ACTION=="add", ENV{ID_FS_TYPE}=="vfat", ENV{mount_options}="iocharset=utf8,umask=000"
ACTION=="add", ENV{ID_FS_TYPE}=="ntfs", ENV{mount_options}="iocharset=utf8,umask=000"
ACTION=="add", RUN+="/bin/mkdir -p /media/%E{dir_name}", RUN+="/bin/mount -o $env{mount_options} /dev/%k /media/%E{dir_name}"
ACTION=="remove", ENV{dir_name}!="", RUN+="/bin/umount -l /media/%E{dir_name}", RUN+="/bin/rmdir /media/%E{dir_name}"  
LABEL="media_by_label_auto_mount_end"

#!/bin/bash
logpath=/var/log/usbmount.log
counterpath=/home/pi/count
ls $counterpath >/dev/null
if [ $? == 0 ]
then
    echo $(expr $(cat $counterpath) + 1) > $counterpath
else
    echo 1 > $counterpath
fi
counter=$(cat $counterpath)
if [ $counter -gt 254 ]
then
	echo 1 > $counterpath
    counter=$(cat $counterpath)
fi
if [ $ACTION == "add" ]
then
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> find usb device inserted! Installation process begins..." >> $logpath
    lsblk >> $logpath
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> step 1: dd os image...(about 5 minutes)" >> $logpath
    dd bs=4M if=/home/pi/2019-07-10-raspbian-buster-lite.img of=/dev/sda conv=fsync
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> step 2: mounting to /home/pi/boot/..." >> $logpath
    mkdir -p /home/pi/boot
    mount /dev/sda1 /home/pi/boot
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> step 3: changing configuration in /home/pi/boot/..." >> $logpath
    ls /home/pi/boot >> $logpath    
    touch /home/pi/boot/ssh.txt
    sed -ri "s/ rootwait / rootwait ip=192.168.100.$counter::192.168.0.1:255.255.0.0:rpi:eth0:off /" /home/pi/boot/cmdline.txt
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> step 4: umount from /home/pi/boot/..." >> $logpath
    umount -l /home/pi/boot/
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> done! pelease remove usb device and insert another." >> $logpath
elif [ $ACTION == "remove" ]
then
    echo "[$(date '+%Y_%m_%d %H:%M:%S')]> find usb device removed!" >> $logpath
    umount -l /home/pi/boot
fi


