
# Take one optional arg of the default configuration to use.  If not given
# it will build for A20-OLinuXino-Lime2_defconfig
build_linux_mainline() { 
	#builds uboot from sources Submodule of repo is https://github.com/RobertCNelson/u-boot
	pushd linux-mainline &> /dev/null
	echo -n "*********************** linux-mainline checking if we need to build: "
	[ -f ../$OUTPUT_DIR/zImage ] && echo " nope" && popd && return;
	echo "yep. "
	
	[ ! -e .config ] && echo "*********************** linux: Getting Stock Config" && cp ../config/linux-sunxi-next.config.txt .config

	echo "*********************** linux: Configurating"
	echo "*********************** linux: Configurating" > ../$OUTPUT_DIR/kernel.log
	make -j5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit


	echo "*********************** linux: Building"
	echo "*********************** linux: Building" >> ../$OUTPUT_DIR/kernel.log
	make -j5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all zImage modules_prepare &>> ../$OUTPUT_DIR/kernel.log
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit


	echo "*********************** linux: packaging"
	echo "*********************** linux: packaging" >> ../$OUTPUT_DIR/kernel.log
	make -j1 deb-pkg KDEB_PKGVERSION=1.5 LOCALVERSION=-lime2 KBUILD_DEBARCH=armhf ARCH=arm 'DEBFULLNAME=npotts' DEBEMAIL=npotts@some-domain.tld CROSS_COMPILE=arm-linux-gnueabihf- &>> ../$OUTPUT_DIR/kernel.log
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit


	echo "*********************** linux: copying products to output" 
	echo "*********************** linux: copying products to output" >> ../$OUTPUT_DIR/kernel.log
	cp arch/arm/boot/zImage ../$OUTPUT_DIR/zImage &>> ../$OUTPUT_DIR/kernel.log
	mv ../*deb ../$OUTPUT_DIR &>> ../$OUTPUT_DIR/kernel.log
	[ ! $? -eq 0 ] && echo "FAILED!!!!!!" && exit
	popd &> /dev/null
}