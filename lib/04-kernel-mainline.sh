
# Take one optional arg of the default configuration to use.  If not given
# it will build for A20-OLinuXino-Lime2_defconfig
build_linux_mainline() { 
	#builds uboot from sources Submodule of repo is https://github.com/RobertCNelson/u-boot
	pushd linux-mainline
	echo -n "Checking for Kernel ..."
	[ -f ../$OUTPUT_DIR/zImage ] && echo " already exists" && popd && return;
	echo "no u-boot.  Proceeding with building"
	
	[ ! -e .config ] && cp ../config/linux-sunxi-next.config.txt .config

	make -j5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
	make -j5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all zImage modules_prepare

	fakeroot make -j1 deb-pkg KDEB_PKGVERSION=1.5 LOCALVERSION=-lime2 KBUILD_DEBARCH=armhf ARCH=arm 'DEBFULLNAME=npotts' DEBEMAIL=npotts@some-domain.tld CROSS_COMPILE=arm-linux-gnueabihf-

	cp arch/arm/boot/zImage ../$OUTPUT_DIR/zImage
	cp -rv *deb ../*deb $OUTPUT_DIR
	tar -cPf ../$OUTPUT_DIR/kernel/4.0.0-rc4-lime2-next.tar *.deb ../*.deb

	popd
}