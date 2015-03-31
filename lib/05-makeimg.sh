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
	sudo umount /dev/loop0

}

