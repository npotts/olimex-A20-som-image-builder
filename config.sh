# This is a good starting point for users to enter in information that will be used 
# elsewhere in this build module.


#What default u-boot config should we use?  Avaliable options can be see by browsing u-boot/configs/
UBOOT_DEF_CFG="A20-OLinuXino-Lime2_defconfig"

#How agressive should we be when building u-boot
MAKE_PROCS="-j5"

#cross-compiler prefix.
CROSS_PREFIX=arm-linux-gnueabihf-



#where should the output files be shoved?
OUTPUT_DIR="output"

#where should the FAKEROOT image be mounted?
FAKEROOT="${OUTPUT_DIR}/sdcard"

#where should the rootfs image be placed?
ROOT_IMG="${OUTPUT_DIR}/rootfs.img"


for i in $(ls lib/*.sh); do
  source $i
done

