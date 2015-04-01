
# Take one optional arg of the default configuration to use.  If not given
# it will build for A20-OLinuXino-Lime2_defconfig
build_uboot() { 
	#builds uboot from sources Submodule of repo is https://github.com/RobertCNelson/u-boot
	pushd u-boot &> /dev/null
	echo -n "*********************** Checking if we need to build u-boot: "
	[ -f ../$OUTPUT_DIR/u-boot_4.0.0-rc4.tgz ] && echo " nope" && popd && return;
	echo "yep."
	
	echo "*********************** uboot: Cleaning"
	make -s  CROSS_COMPILE=arm-linux-gnueabihf- clean
	if [ -z $1 ]; then
		echo "*********************** uboot: using default Lime2 config"
		make -j5 CROSS_COMPILE=arm-linux-gnueabihf- A20-OLinuXino-Lime2_defconfig &> ../$OUTPUT_DIR/u-boot.log
	else
		echo "*********************** uboot: Provided config."
		make -j5 CROSS_COMPILE=arm-linux-gnueabihf- $1 &> ../$OUTPUT_DIR/u-boot.log
	fi
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit 
	echo "*********************** uboot: Building"
	make -j5 CROSS_COMPILE=arm-linux-gnueabihf-  &>> ../$OUTPUT_DIR/u-boot.log #build u-boot
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit
	echo "*********************** uboot: Packaging"
	#package it
	tar cPfz ../$OUTPUT_DIR/u-boot_4.0.0-rc4.tgz u-boot-sunxi-with-spl.bin &>> ../$OUTPUT_DIR/u-boot.log
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit
	echo "*********************** uboot: Done"
	popd &> /dev/null
}