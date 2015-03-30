
# Take one optional arg of the default configuration to use.  If not given
# it will build for A20-OLinuXino-Lime2_defconfig
build_uboot() { 
	#builds uboot from sources Submodule of repo is https://github.com/RobertCNelson/u-boot
	pushd u-boot
	echo -n "Checking for u-boot ..."
	[ -f ../$OUTPUT_DIR/u-boot_4.0.0-rc4.tgz ] && echo " already exists" && popd && return;
	echo "no u-boot.  Proceeding with building"
	
	make -s  CROSS_COMPILE=arm-linux-gnueabihf- clean
	if [ -z $1 ]; then
		make -j5 CROSS_COMPILE=arm-linux-gnueabihf- $1
	else
		make -j5 CROSS_COMPILE=arm-linux-gnueabihf- A20-OLinuXino-Lime2_defconfig
	fi
	make -j5 CROSS_COMPILE=arm-linux-gnueabihf- #build u-boot
	#package it
	tar cPfz ../$OUTPUT_DIR/u-boot_4.0.0-rc4.tgz u-boot-sunxi-with-spl.bin
	popd
}