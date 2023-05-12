#!/bin/sh

P2MOUNT=/media/mmcblk0p2
PERSIST=/media/mmcblk0p2/persist.img
USERFILES=/media/mmcblk0p2/userfiles.img
PERMOUNT=/media/persist
P2APKS=/media/mmcblk0p2/apks

apk add e2fsprogs
apk add chrony
rc-update add chronyd
rc-service chronyd start

if [[ ! -e $P2MOUNT ]]; then
	mkdir -p $P2MOUNT
fi

if [[ ! -e $PERMOUNT ]]; then
	mkdir -p $PERMOUNT
fi

echo "/dev/mmcblk0p2 /media/mmcblk0p2 vfat rw,noatime,errors=remount-ro 0 0" >> /etc/fstab
mount /dev/mmcblk0p2
sleep 3

## Make persistence disk image on second uSD partition and mount it
if [[ ! -e $PERSIST ]]; then
        fallocate -l3G $PERSIST
	mkfs.ext4 $PERSIST
fi

if [[ -z "$(blkid -o value -s TYPE $PERSIST)" ]]; then
	mkfs.ext4 $PERSIST
fi

echo "/media/mmcblk0p2/persist.img /media/persist ext4 rw,relatime,errors=remount-ro 0 0" >> /etc/fstab

if [[ -e $PERSIST ]]; then
	mount $PERSIST
	sleep 3

	## Mount overlay for /usr from persistence disk image
	if [[ ! -e /media/persist/usr ]]; then
		mkdir -p /media/persist/usr
	fi

	if [[ ! -e /media/persist/.work_usr ]]; then
		mkdir -p /media/persist/.work_usr
	fi

	echo "overlay /usr overlay lowerdir=/usr,upperdir=/media/persist/usr,workdir=/media/persist/.work_usr 0 0" >> /etc/fstab
	mount -a
fi

sleep 3

## Make directory for extra APK packages on second uSD partition, add alpine package repos and download required packages 
if [[ ! -e $P2APKS ]]; then
        mkdir -p $P2APKS
fi

## Add Alpine repos
cat <<EOF >> /etc/apk/repositories
http://dl-cdn.alpinelinux.org/alpine/v3.17/main
http://dl-cdn.alpinelinux.org/alpine/v3.17/community
http://eu.edge.kernel.org/alpine/v3.17/main
http://eu.edge.kernel.org/alpine/v3.17/community
EOF

## Setup APK Cache
if [[ -e $P2APKS ]]; then
	setup-apkcache /media/mmcblk0p2/apks/

	## Install required packages, keeping them in /media/mmcblk0p2/apks cache for installing at next boot
	apk update
	apk add socat git make cmake pkgconf libtool libusb libusb-dev gcc g++ raspberrypi raspberrypi-libs raspberrypi-dev wiringpi-dev libftdi1-dev libc6-compat libusb-compat libusb-compat-dev nano tmux screen htop dosfstools 7zip curl

	## Copy Raspberry Pi support files and libraries to /usr/local (fixes bcm_ header files not found etc).
	cp -r /opt/vc/lib/* /usr/local/lib/; mkdir -p /usr/local/include; cp -r /opt/vc/include/* /usr/local/include/; cp -r /opt/vc/bin/* /usr/local/bin/
fi

## Start socat for serial UART bridge pass-through
## Use screen: using tmux or backgrounding socat (by appending ampersand [&] to command line) doesn't work and breaks this script
## either killing it prematurely and/or disallowing script to continue to next job - seems to be
## some kind of exit 0 or return to parent shell problem. Ideally tmux would be used due to it being already availble
## in default Alpine local apk repo so need to troubleshoot this
screen -d -m /usr/bin/socat /dev/ttyGS0,rawer,b2000000 /dev/ttyAMA0,rawer,b2000000

## Create home disk image for user files and mount it
if [[ ! -e $USERFILES ]]; then
        fallocate -l3G $USERFILES
	mkfs.ext4 $USERFILES
fi

if [[ -z "$(blkid -o value -s TYPE $USERFILES)" ]]; then
	mkfs.ext4 $USERFILES
fi

echo "/media/mmcblk0p2/userfiles.img /root ext4 rw,relatime,errors=remount-ro 0 0" >> /etc/fstab

if [[ -e $USERFILES ]]; then
	mount $USERFILES
	sleep 3

	if [[ ! -e /root/sources ]]; then 
		mkdir /root/sources
	fi

	## Clone xvcpi, change default JTAG GPIO pins and compile
	if [[ ! -e /usr/local/bin/xvcpi ]]; then
		cd /root/sources; rm -rf /root/sources/xvcpi; git clone https://github.com/derekmulcahy/xvcpi.git
		cd /root/sources/xvcpi; git checkout -b rugjam
		sed -i 's/tck_gpio = 11/tck_gpio = 25/g' xvcpi.c
		sed -i 's/tms_gpio = 25/tms_gpio = 27/g' xvcpi.c
		sed -i 's/tdi_gpio = 10/tdi_gpio = 26/g' xvcpi.c
		sed -i 's/tdo_gpio = 9/tdo_gpio = 24/g' xvcpi.c
		make
		cp xvcpi /usr/local/bin/
	fi

	## Start xvcpi
	xvcpi &
	
	## Clone xc3sprog, change default JTAG GPIO pins and compile
	if [[ ! -e /usr/local/bin/xc3sprog ]]; then
		cd /root/sources; rm -rf /root/sources/xc3sprog; git clone https://github.com/matrix-io/xc3sprog
		cd /root/sources/xc3sprog; git checkout -b rugjam; mkdir /root/sources/xc3sprog/build; cd /root/sources/xc3sprog/build;
		sed -i 's/ftdi.h/libftdi1\/ftdi.h/g' /root/sources/xc3sprog/Findlibftdi.cmake
		sed -i 's/\(^ \{12\}\)ftdi/\1ftdi1/g' /root/sources/xc3sprog/Findlibftdi.cmake
		sed -i 's/<ftdi.h>/<libftdi1\/ftdi.h>/g' /root/sources/xc3sprog/ioftdi.h
		sed -i 's/IOWiringPi(4, 17, 22, 27)/IOWiringPi(27, 25, 26, 24)/g' /root/sources/xc3sprog/iomatrixcreator.cpp
		cmake /root/sources/xc3sprog/; make; make install
	fi
fi