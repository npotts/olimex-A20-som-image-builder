
prep() {
	git submodule init
	git submodule update
	mkdir -p $OUTPUT_DIR/bin-local
	mkdir -p $OUTPUT_DIR/bin-arm
}
