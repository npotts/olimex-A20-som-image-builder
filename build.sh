#!/bin/bash

MAKE_PROCS="-j5"
CROSS_PREFIX=arm-linux-gnueabihf-
OUTPUT_DIR="output"


for i in $(ls lib/*); do
	source $i
done
prep #setup needed output folder, etc


build_uboot
build_sunxitools
build_linux_mainline
