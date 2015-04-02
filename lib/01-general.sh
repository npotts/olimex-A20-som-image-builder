
prep() {
	echo "*********************** Updating Submodules....  This might take a while the first time go round"
	git submodule init
	git submodule update
	echo "*********************** Submodules updated"
	mkdir -p $OUTPUT_DIR/kernel
	mkdir -p $OUTPUT_DIR/bin
	mkdir -p $OUTPUT_DIR/sdcard
}
