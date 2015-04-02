mount_chroot_env() {
	echo "*********************** Mounting chroot"
	#sudo losetup -o 1048576 /dev/loop0 $ROOT_IMG
	sudo losetup /dev/loop0 $ROOT_IMG
	[ ! $? -eq 0 ] && echo "Unable to setup losetup" && exit 
	sudo mount -t ext4 /dev/loop0 $FAKEROOT
	[ ! $? -eq 0 ] && echo "Unable to mount fs" && exit 
	sudo mount -t proc proc $FAKEROOT/proc
	[ ! $? -eq 0 ] && echo "Unable to mount proc" && exit 
	sudo mount -t sysfs sys $FAKEROOT/sys
	[ ! $? -eq 0 ] && echo "Unable to mount sys" && exit
	sudo mount -t devtmpfs dev $FAKEROOT/dev
	[ ! $? -eq 0 ] && echo "Unable to mount dev" && exit
	sudo mount -t devpts pts $FAKEROOT/dev/pts
	[ ! $? -eq 0 ] && echo "Unable to mount pts" && exit
	echo "*********************** chroot mounted"
}

dirty_unmount_chroot_env() {
	#this is nasty
	echo "*********************** This can be a nasty..."
	sudo fuser -k $FAKEROOT/sys
	sudo fuser -k $FAKEROOT/proc
	sudo fuser -k $FAKEROOT/pts
	sudo fuser -k $FAKEROOT/dev
	sudo fuser -k $FAKEROOT
	sudo umount $FAKEROOT/{sys,proc,pts,dev}  /dev/loop0
	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0
	echo "*********************** Ok.  ALl better now"
}
unmount_chroot_env() {
	sync
	echo "*********************** Unmounting chroot"
	sudo fuser -k $FAKEROOT/sys
	sudo fuser -k $FAKEROOT/proc
	sudo fuser -k $FAKEROOT/dev/pts
	sudo fuser -k $FAKEROOT/dev
	sudo fuser -k $FAKEROOT
	sudo umount $FAKEROOT/sys
	[ ! $? -eq 0 ] && echo "Unable to unmount sys" 
	sudo umount $FAKEROOT/proc
	[ ! $? -eq 0 ] && echo "Unable to unmount proc"
	sudo umount $FAKEROOT/dev/pts
	[ ! $? -eq 0 ] && echo "Unable to unmount pts"
	sudo umount $FAKEROOT/dev
	[ ! $? -eq 0 ] && echo "Unable to unmount dev"
	sudo umount /dev/loop0
	[ ! $? -eq 0 ] && echo "Unable to unmount /dev/loop0"
	sudo losetup -d /dev/loop0
	[ ! $? -eq 0 ] && echo "Unable to dislodge /dev/loop0"
	echo "*********************** done Unmounting chroot"
}

chroot_install() {

	mount_chroot_env

	echo "*********************** Moving files into the chroot"
	sudo cp config/sources.list $FAKEROOT/etc/apt/sources.list
	[ ! $? -eq 0 ] && echo "Unable to copy sources.list to final location" && exit
	sudo cp config/experimental /etc/apt/preferences.d/
	[ ! $? -eq 0 ] && echo "Unable to copy experimental to final location" && exit
	sudo cp config/kernel-cmdline.txt /etc/default/flash-kernel
	[ ! $? -eq 0 ] && echo "Unable to copy flash-kernel default command line to final location" && exit

	echo "*********************** Creating SSH Keys if needed "
	echo "*********************** If you want to use pre-made keys, place them in $OUTPUT_DIR/ssh_[r|d|ecd]sa]_key"
	[ ! -e $OUTPUT_DIR/ssh_host_dsa_key ] && ssh-keygen -b 1024 -t dsa -N "" -f $OUTPUT_DIR/ssh_host_dsa_key
	[ ! -e $OUTPUT_DIR/ssh_host_rsa_key ] && ssh-keygen -b 4096 -t rsa -N "" -f $OUTPUT_DIR/ssh_host_rsa_key
	[ ! -e $OUTPUT_DIR/ssh_host_ecdsa_key ] && ssh-keygen -b 521  -t ecdsa -N "" -f $OUTPUT_DIR/ssh_host_ecdsa_key
	sudo cp $OUTPUT_DIR/ssh_host_dsa_key $OUTPUT_DIR/ssh_host_rsa_key* $OUTPUT_DIR/ssh_host_ecdsa_key $FAKEROOT/etc/ssh/
	[ ! $? -eq 0 ] && echo "Unable to copy SSH keys properly" && exit


	#echo "*********************** Copying Needed files to chroot's /tmp"
	#sudo cp -fr $OUTPUT_DIR/*deb config/boot-next.cmd config/firmware.zip $FAKEROOT/tmp
	#[ ! $? -eq 0 ] && echo "Unable to copy needed files to chroot's /tmp" && exit

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
	[ ! $? -eq 0 ] && echo "Unable to create image file" && exit

	#two EXT4 mounts
	echo "*********************** Partitioning"
	sudo losetup /dev/loop0 $ROOT_IMG 
	[ ! $? -eq 0 ] && echo "Unable to mount as loopback fs" && exit
	sudo parted -s /dev/loop0 -- mklabel msdos
	[ ! $? -eq 0 ] && echo "Unable to set disk label" && exit
	sudo parted -s /dev/loop0 -- mkpart primary ext4 2048s -1s
	[ ! $? -eq 0 ] && echo "Unable to create file system" && exit
	sudo partprobe /dev/loop0 #update part table
	[ ! $? -eq 0 ] && echo "Unable to update partition table" && exit
	sudo dd if=$OUTPUT_DIR/u-boot-sunxi-with-spl.bin of=/dev/loop0 bs=1024 seek=8
	[ ! $? -eq 0 ] && echo "Unable to burn bootloader to image" && exit
	sudo losetup -d /dev/loop0
	[ ! $? -eq 0 ] && echo "Unable to dislodge disk image via losetup" && exit

	#remount directly on top of the start of the partition 1048576 = 512(bytes) * 2048sectors
	#sudo losetup -o 1048576 /dev/loop0 $ROOT_IMG
	sudo losetup /dev/loop0 $ROOT_IMG
	sync
	sudo mkfs.ext4 -FF /dev/loop0
	#tuning so that if you power off before write occurs, you may end up with old data rather than corrupt data
	sudo tune2fs -o journal_data_writeback /dev/loop0
	sudo e2label /dev/loop0 a20som
	sudo mount -t ext4 /dev/loop0 $FAKEROOT

	echo "*********************** debootstrap'ing stage 1"
	sudo DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true LC_ALL=C LANGUAGE=C LANG=C debootstrap --include=linux-image-armmp-lpae,openssh-server,debconf-utils,tmux,zsh,vim,ser2net,nmap,socat --arch=armhf --foreign jessie $OUTPUT_DIR/sdcard

	#copy qemu binary debian style
	sudo cp /usr/bin/qemu-arm-static $FAKEROOT/usr/bin/

	sudo mkdir -p $FAKEROOT/pts

	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0

	mount_chroot_env #use normal way ot accessing chroot with all the other mounts
	echo "*********************** debootstrap'ing stage 2"
	sudo chroot $FAKEROOT /bin/bash -c '/debootstrap/debootstrap --second-stage'
	unmount_chroot_env

	chroot_install

	echo "*********************** Image created"
}
