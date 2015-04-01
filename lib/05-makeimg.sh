mount_chroot_env() {
	echo -n "*********************** Mounting chroot"
	sudo losetup -o 1048576 /dev/loop0 $ROOT_IMG
	sudo mount -t ext4 /dev/loop0 $FAKEROOT

	sudo mount -t proc chproc $FAKEROOT/proc
	sudo mount -t sysfs chsys $FAKEROOT/sys
	sudo mount -t devtmpfs chdev $FAKEROOT/dev
	sudo mkdir -p FAKEROOT/pts
	sudo mount -t devpts chpts $FAKEROOT/pts
	echo "  ok"
}

unmount_chroot_env() {
	echo -n "*********************** Unmounting chroot"
	sudo umount $FAKEROOT/proc
	sudo umount $FAKEROOT/sys
	sudo umount $FAKEROOT/dev
	sudo umount $FAKEROOT/pts

	sudo umount /dev/loop0
	sudo losetup -d /dev/loop0

	echo " ok"
}

chroot_install() {

	mount_chroot_env

	echo "*********************** Creating default source list"
	sudo cp $OUTPUT_DIR/../configs/sources.list $FAKEROOT/etc/apt/sources.list

	echo "*********************** Creating SSH Keys if needed "
	echo "*********************** If you want to use pre-made keys, place them in $OUTPUT_DIR/ssh_[r|d|ecd]sa]_key"
	[ ! -e $OUTPUT_DIR/ssh_host_dsa_key ] ssh-keygen -b 1024 -t dsa -N "" -f $OUTPUT_DIR/ssh_host_dsa_key
	[ ! -e $OUTPUT_DIR/ssh_host_rsa_key ] ssh-keygen -b 4096 -t rsa -N "" -f $OUTPUT_DIR/ssh_host_rsa_key
	[ ! -e $OUTPUT_DIR/ssh_host_ecdsa_key ] ssh-keygen -b 521  -t ecdsa -N "" -f $OUTPUT_DIR/ssh_host_ecdsa_key
	sudo cp $OUTPUT_DIR/ssh_host_dsa_key $OUTPUT_DIR/ssh_host_rsa_key $OUTPUT_DIR/ssh_host_ecdsa_key $FAKEROOT/etc/ssh/


	echo "*********************** Copying Needed files to chroot's /tmp"
	sudo cp -fr $OUTPUT_DIR/*deb config/boot-next.cmd config/firmware.zip $FAKEROOT/tmp

	echo "*********************** Copying in system-builder script"
	sudo cp $OUTPUT_DIR/../libs/system-builder $FAKEROOT/root
	sudo chmod +x $FAKEROOT/root/system-builder

	echo "*********************** Entering chroot"
	LC_ALL=C LANGUAGE=C LANG=C chroot $FAKEROOT /bin/bash -c '/root/system-builder'
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
	dd if=$OUTPUT_DIR/u-boot-sunxi-with-spl.bin of=/dev/loop1 bs=1024 seek=8 status=noxfer
	sudo losetup -d /dev/loop0

	mount_chroot_env
	echo "*********************** debootstrap'ing stage 2"
	sudo chroot $FAKEROOT /bin/bash -c '/debootstrap/debootstrap --second-stage'
	sudo chroot `pwd` /bin/bash -c '/debootstrap/debootstrap --second-stage'

	unmount_chroot_env

	chroot_install

	echo "*********************** Image created"
}
