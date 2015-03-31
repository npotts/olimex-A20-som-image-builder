mount_chroot_env() {
	FAKEROOT="${OUTPUT_DIR}/sdcard"
	sudo losetup -o 1048576 /dev/loop0 $ROOT_IMG
	sudo mount -t ext4 /dev/loop0 $FAKEROOT

	sudo mount -t proc chproc $FAKEROOT/proc
	sudo mount -t sysfs chsys $FAKEROOT/sys
	sudo mount -t devtmpfs chdev $FAKEROOT/dev
	sudo mkdir -p FAKEROOT/pts
	sudo mount -t devpts chpts $FAKEROOT/pts
}

unmount_chroot_env() {
	sudo umount $FAKEROOT/proc
	sudo umount $FAKEROOT/sys
	sudo umount $FAKEROOT/dev
	sudo umount $FAKEROOT/pts

	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0
}

packages_install() {
	FAKEROOT="${OUTPUT_DIR}/sdcard" 
	
	mount_chroot_env

	#put int some default source lists

	cat << EOF > $FAKEROOT/etc/apt/sources.list
deb http://ftp.nl.debian.org/debian unstable main contrib non-free
deb-src http://ftp.us.debian.org/debian unstable main contrib non-free

deb http://ftp.nl.debian.org/debian/ jessie-updates main contrib non-free
deb-src http://ftp.us.debian.org/debian/ jessie-updates main contrib non-free

deb http://security.debian.org/ jessie/updates main contrib non-free
deb-src http://security.debian.org/ jessie/updates main contrib non-free

EOF
	#update image
	LC_ALL=C
	LANGUAGE=C
	LANG=C
	sudo chroot $FAKEROOT /bin/bash -c 'apt-get -y update'

	#setup TTYs
	sed -e 's/1:2345:respawn:\/sbin\/getty 38400 tty1/1:2345:respawn:\/sbin\/getty --noclear 38400 tty1/g' -i $OUTPUT_DIR/etc/inittab
	sed -e s/3:23:respawn/#3:23:respawn/g -i $FAKEROOT/etc/inittab
	sed -e s/4:23:respawn/#4:23:respawn/g -i $FAKEROOT/etc/inittab
	sed -e s/5:23:respawn/#5:23:respawn/g -i $FAKEROOT/etc/inittab
	sed -e s/6:23:respawn/#6:23:respawn/g -i $FAKEROOT/etc/inittab
	echo T0:2345:respawn:/sbin/getty -L ttyS0 115200 vt100 >> $FAKEROOT/etc/inittab

	#setup locales
	chroot $FAKEROOT /bin/bash -c 'apt-get -y -qq install locales'
	sed -i 's/^# en_US.UTF-8/en_US.UTF-8/' $FAKEROOT/etc/locale.gen
	sudo chroot $FAKEROOT /bin/bash -c 'locale-gen en_US.UTF-8'
	sudo chroot $FAKEROOT /bin/bash -c 'LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 DEBIAN_FRONTEND=noninteractive  LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_MESSAGES=POSIX update-locale'
	
	#install some packages
	sudo chroot $FAKEROOT /bin/bash -c 'apt-get -y install automake bash-completion bc bridge-utils build-essential cmake curl dosfstools evtest figlet fping git haveged hddtemp hdparm  htop i2c-tools ifenslave-2.6 iperf ir-keytable iw less libbluetooth-dev libbluetooth3 libtool libwrap0-dev libfuse2 libnl-dev libssl-dev lsof makedev module-init-tools mtp-tools nano ntfs-3g ntp parted pkg-config pciutils pv python-smbus rfkill rsync screen stress sudo sysfsutils toilet u-boot-tools unattended-upgrades unzip usbutils wget zsh vim socat netcat nmap tmux'

	#set password
	sudo chroot $FAKEROOT /bin/bash -c '(echo 1234;echo 1234;) | passwd root'
	sudo chroot $FAKEROOT /bin/bash -c 'chage -d 0 root'

	unmount_chroot_env
}

make_format() {
	ROOT_IMG="${OUTPUT_DIR}/rootfs/rootfs.img"
	rm -fr $ROOT_IMG
	dd if=/dev/zero of=$ROOT_IMG bs=1M count=2000 status=noxfer

	#two EXT4 mounts
	sudo losetup /dev/loop0 $ROOT_IMG
	sudo parted -s /dev/loop0 -- mklabel msdos
	sudo parted -s /dev/loop0 -- mkpart primary ext4 2048s -1s
	sudo partprobe /dev/loop0 #update part table
	sudo losetup -d /dev/loop0

	#remount to new part table
	sudo losetup -o 1048576 /dev/loop0 $ROOT_IMG
	sudo mkfs.ext4 /dev/loop0
	#tuning so that if you power off before write occurs, you may end up with old data rather than corrupt data
	sudo tune2fs -o journal_data_writeback /dev/loop0
	sudo e2label /dev/loop0 a20som
	sudo mount -t ext4 /dev/loop0 $OUTPUT_DIR/sdcard
	sudo debootstrap --include=openssh-server,debconf-utils,tmux,zsh,vim,ser2net,nmap,socat --arch=armhf --foreign jessie $OUTPUT_DIR/sdcard

	#copy qemu binary debian style
	sudo cp /usr/bin/qemu-arm-static $OUTPUT_DIR/sdcard/usr/bin/

	sudo mkdir -p $OUTPUT_DIR/pts

	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0

	mount_chroot_env

	sudo chroot $OUTPUT_DIR /bin/bash -c '/debootstrap/debootstrap --second-stage'

	unmount_chroot_env

	packages_install
	
}
