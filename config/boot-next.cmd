setenv bootargs console=tty1 root=/dev/mmcblk0p1 rootwait panic=10
ext4load mmc 0 0x49000000 /boot/dtb/4.0.0-rc5-lime2${fdtfile}
ext4load mmc 0 0x46000000 /boot/vmlinuz-4.0.0-rc5-lime2
env set fdt_high ffffffff
bootz 0x46000000 - 0x49000000