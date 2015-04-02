#!/bin/bash

MAKE_PROCS="-j5"
CROSS_PREFIX=arm-linux-gnueabihf-
OUTPUT_DIR="output"
FAKEROOT="${OUTPUT_DIR}/sdcard"
ROOT_IMG="${OUTPUT_DIR}/rootfs.img"

for i in $(ls lib/*.sh); do
	source $i
done
prep #setup needed output folder, etc


build_uboot
make_rootfs
#chroot_install




#build_sunxitools
#build_linux_mainline
#mount_chroot_env
#chroot_install
#