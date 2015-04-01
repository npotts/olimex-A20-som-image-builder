mount_chroot_env() {
	echo "*********************** Mounting chroot"
	sudo losetup -o 1048576 /dev/loop0 $ROOT_IMG
	[ ! $? -eq 0 ] && echo "Unable to setup losetup" && exit 
	sudo mount -t ext4 /dev/loop0 $FAKEROOT
	[ ! $? -eq 0 ] && echo "Unable to mount fs" && exit 
	sudo mount -t proc proc $FAKEROOT/proc
	[ ! $? -eq 0 ] && echo "Unable to mount proc" && exit 
	sudo mount -t sysfs sys $FAKEROOT/sys
	[ ! $? -eq 0 ] && echo "Unable to mount sys" && exit
	sudo mount -t devtmpfs dev $FAKEROOT/dev
	[ ! $? -eq 0 ] && echo "Unable to mount dev" && exit
	sudo mkdir -p $FAKEROOT/pts
	[ ! $? -eq 0 ] && echo "Unable to make pts path" && exit
	sudo mount -t devpts pts $FAKEROOT/pts
	[ ! $? -eq 0 ] && echo "Unable to mount pts" && exit
	echo "*********************** chroot mounted"
}

unmount_chroot_env() {
	echo "*********************** Unmounting chroot"
	sudo umount $FAKEROOT/sys
	[ ! $? -eq 0 ] && echo "Unable to unmount sys" && exit
	sudo umount $FAKEROOT/proc
	[ ! $? -eq 0 ] && echo "Unable to unmount proc" && exit
	sudo umount $FAKEROOT/dev
	[ ! $? -eq 0 ] && echo "Unable to unmount dev" && exit
	sudo umount $FAKEROOT/pts
	[ ! $? -eq 0 ] && echo "Unable to unmount pts" && exit
	sudo umount /dev/loop0
	[ ! $? -eq 0 ] && echo "Unable to unmount /dev/loop0" && exit
	sudo losetup -d /dev/loop0
	[ ! $? -eq 0 ] && echo "Unable to dislodge /dev/loop0" && exit
	echo "*********************** done Unmounting chroot"
}

chroot_install() {

	mount_chroot_env

	echo "*********************** Creating default source list"
	sudo cp config/sources.list $FAKEROOT/etc/apt/sources.list
	[ ! $? -eq 0 ] && echo "Unable to copy sources.list to final location" && exit

	echo "*********************** Creating SSH Keys if needed "
	echo "*********************** If you want to use pre-made keys, place them in $OUTPUT_DIR/ssh_[r|d|ecd]sa]_key"
	[ ! -e $OUTPUT_DIR/ssh_host_dsa_key ] && ssh-keygen -b 1024 -t dsa -N "" -f $OUTPUT_DIR/ssh_host_dsa_key
	[ ! -e $OUTPUT_DIR/ssh_host_rsa_key ] && ssh-keygen -b 4096 -t rsa -N "" -f $OUTPUT_DIR/ssh_host_rsa_key
	[ ! -e $OUTPUT_DIR/ssh_host_ecdsa_key ] && ssh-keygen -b 521  -t ecdsa -N "" -f $OUTPUT_DIR/ssh_host_ecdsa_key
	sudo cp $OUTPUT_DIR/ssh_host_dsa_key $OUTPUT_DIR/ssh_host_rsa_key* $OUTPUT_DIR/ssh_host_ecdsa_key $FAKEROOT/etc/ssh/
	[ ! $? -eq 0 ] && echo "Unable to copy SSH keys properly" && exit


	echo "*********************** Copying Needed files to chroot's /tmp"
	sudo cp -fr $OUTPUT_DIR/*deb config/boot-next.cmd config/firmware.zip $FAKEROOT/tmp
	[ ! $? -eq 0 ] && echo "Unable to copy needed files to chroot's /tmp" && exit

	echo "*********************** Copying in system-builder script"
	sudo cp $OUTPUT_DIR/../lib/system-builder $FAKEROOT/tmp
	[ ! $? -eq 0 ] && echo "Unable to copy in system-builder" && exit
	sudo chmod +x $FAKEROOT/tmp/system-builder
	[ ! $? -eq 0 ] && echo "Unable to set executable bit on system-builder" && exit

	echo "*********************** Entering chroot"
	sudo LC_ALL=C LANGUAGE=C LANG=C chroot $FAKEROOT /bin/bash -c '/tmp/system-builder'
	[ ! $? -eq 0 ] && echo "Unable to enter chroot and run system-builder" && exit
	echo "*********************** Exited chroot"
	
	unmount_chroot_env
}

make_rootfs() {
	echo "*********************** Making Rootfs Image"
	rm -fr $ROOT_IMG
  	sync
  	echo "*********************** Creating image file"
	dd if=/dev/zero of=$ROOT_IMG bs=1M count=2000 status=noxfer

	#two EXT4 mounts
	echo "*********************** Partitioning"
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
	sudo mount -t ext4 /dev/loop0 $FAKEROOT

	echo "*********************** debootstrap'ing stage 1"
	sudo debootstrap --include=openssh-server,debconf-utils,tmux,zsh,vim,ser2net,nmap,socat --arch=armhf --foreign jessie $OUTPUT_DIR/sdcard

	#copy qemu binary debian style
	sudo cp /usr/bin/qemu-arm-static $FAKEROOT/usr/bin/

	sudo mkdir -p $FAKEROOT/pts

	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0

	echo "*********************** Installing u-boot at the bootloader"
	sudo losetup /dev/loop0 $ROOT_IMG
	sudo dd if=$OUTPUT_DIR/u-boot-sunxi-with-spl.bin of=/dev/loop0 bs=1024 seek=8 status=noxfer
	sudo losetup -d /dev/loop0

	mount_chroot_env
	echo "*********************** debootstrap'ing stage 2"
	sudo chroot $FAKEROOT /bin/bash -c '/debootstrap/debootstrap --second-stage'

	unmount_chroot_env

	chroot_install

	echo "*********************** Image created"
}
