#!/bin/bash

source config.sh

prep #setup needed output folder, etc

#first build u-boot
build_uboot

#then make the rootfs
make_rootfs
