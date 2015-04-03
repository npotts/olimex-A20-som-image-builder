# Olimex A20-SOM Image Builder

This was created in order to create a source controlled and customizable image for an A20-SOM. Since I am use the A20-SOM in a custom circuit board, I needed to change and control the set of packages installed as well as have more fine tunes control over the image.  If you want more of a one-step solution: look in [this] (https://github.com/igorpecovnik/Lime-Debian) [general] (https://github.com/igorpecovnik/Cubietruck-Debian) [direction] (https://github.com/igorpecovnik/lib).

# References
Information was gleaned from the following articles and tutorials
- [https://raymii.org/s/articles/Olimex_OlinuXino_A20_Lime2_Kernel_3.19_uBoot_Debian_7_image_building.html] (https://raymii.org/s/articles/Olimex_OlinuXino_A20_Lime2_Kernel_3.19_uBoot_Debian_7_image_building.html)
- [http://linux-sunxi.org/Mainline_Debian_HowTo](http://linux-sunxi.org/Mainline_Debian_HowTo)


# Host Requirements
- Ubuntu 14.10+ host

# Key Features
- Mainline Kernels
- (near) standard debian testing (jessie) rootfs
- Ability to fiddle with the settings
- uncompressed root image as output

#Usage

- Edit config.sh and then run build.sh

```sh
	
	git clone https://github.com/npotts/olimex-A20-som-image-builder.git
	cd olimex-A20-som-image-builder
  vim config.sh
	./build
	...
	#drink some coffee, this can take a bit
	...
	ls output/rootfs
	bin  kernel  rootfs.img  sdcard  u-boot.log  u-boot-sunxi-with-spl.bin
```

#TODO
This is a work in progress
- Move configuration items into single location
- Better Documentation


#Caveats & Notes:
- I treat the A20-SOM much like a Lime2 board.  From what I understand, the Lime2 is a derivitive of the A20-SOM
- Buried [here](https://github.com/OLIMEX/OLINUXINO/blob/master/SOFTWARE/A20/A20-build/README.txt "Useful tidbits here!") is the following useful comparison between revA-B and revC-D A20-SOM boards:
```
2.2 A20-SOM board

Note that there is 2 different types of A20-SOM boards. The main differences are in DDR3 memory bus
speed. 

A20-SOM up to rev.B  - DDR3 memory bus speed is 384MHz(6 layer PCB)

A20-SOM after rev.D - DDR3 memory bus speed is 480MHz(8 layer PCB)

2.2.1 For A20-SOM up to rev.B type 

# make A20-SOM_config ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

2.2.2 For A20-SOM after rev.D you can use the u-boot settings for A20-Lime2

# make A20-OLinuXino_Lime2_config ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-

```
- The following line is critical if you want your ethernet to work.  Mainline GMAC uses the stmmac driver:
```sh
	cat /etc/rc.local
	/proc/irq/\$(cat /proc/interrupts | grep eth0 | cut -f 1 -d ":" | tr -d " ")/smp_affinity
```
