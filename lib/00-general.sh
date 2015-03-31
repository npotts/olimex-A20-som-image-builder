
prep() {
	git submodule init
	git submodule update
	mkdir -p $OUTPUT_DIR/kernel
	mkdir -p $OUTPUT_DIR/bin-local
	mkdir -p $OUTPUT_DIR/bin-arm
	mkdir -p $OUTPUT_DIR/rootfs $OUTPUT_DIR/sdcard $OUTPUT_DIR/kernel
}
