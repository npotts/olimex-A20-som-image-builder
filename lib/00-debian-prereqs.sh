debian_prereqs() {

	apt-get -y update
	apt-get -y install tmux zsh vim dkms virtualbox-guest-dkms
	apt-get -y install debconf-utils pv bc lzop zip binfmt-support bison build-essential ccache debootstrap flex gawk gcc-arm-linux-gnueabihf lvm2 qemu-user-static u-boot-tools uuid-dev zlib1g-dev unzip libusb-1.0-0-dev parted pkg-config expect gcc-arm-linux-gnueabi libncurses5-dev git vim screen

}
