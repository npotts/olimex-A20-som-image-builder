
build_sunxitools_local() {
	echo -n "Checking for native sunxi-tools ..."
	[ -f ../$OUTPUT_DIR/bin-local/bin2fex ] && [ -f ../$OUTPUT_DIR/bin-local/fex2bin ] && [ -f ../$OUTPUT_DIR/bin-local/fexc ] && [ -f ../$OUTPUT_DIR/bin-local/bootinfo ] && [ -f ../$OUTPUT_DIR/bin-local/fel ] && [ -f ../$OUTPUT_DIR/bin-local/pio ] && [ -f ../$OUTPUT_DIR/bin-local/nand-part ] && echo " already exist" && return
	echo " no native sunxi-tools.  Building"
	make clean
	make
	cp -rv fexc bin2fex fex2bin bootinfo fel pio nand-part ../$OUTPUT_DIR/bin-local/
}

build_sunxitools_arm() {
	echo -n "Checking for arm sunxi-tools ..."
	[ -f ../$OUTPUT_DIR/bin-arm/bin2fex ] && [ -f ../$OUTPUT_DIR/bin-arm/fex2bin ] && [ -f ../$OUTPUT_DIR/bin-arm/fexc ] && [ -f ../$OUTPUT_DIR/bin-arm/bootinfo ] && [ -f ../$OUTPUT_DIR/bin-arm/fel ] && [ -f ../$OUTPUT_DIR/bin-arm/pio ] && [ -f ../$OUTPUT_DIR/bin-arm/nand-part ] && echo " already exist" && return
	echo " no native sunxi-tools.  Building"
	make clean
	make
	cp -rv fexc bin2fex fex2bin bootinfo fel pio nand-part ../$OUTPUT_DIR/bin-arm/
}

#builds the sunxi tools
build_sunxitools() {
	pushd sunxi-tools
	build_sunxitools_local
	build_sunxitools_arm
	popd
}
