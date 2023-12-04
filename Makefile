BUILD_DIR=build
SOURCE_DIR=src
TOOL_DIR=tool
TOOL_BUILD_DIR=build/tool
ASM=nasm
CC=gcc

.PHONY: all floppy boot kernel clean always test

floppy: $(BUILD_DIR)/floppy.img
$(BUILD_DIR)/floppy.img: boot kernel
	dd if=/dev/zero of=$(BUILD_DIR)/floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "FS" $(BUILD_DIR)/floppy.img
	dd if=$(BUILD_DIR)/bootsec.bin of=$(BUILD_DIR)/floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/floppy.img $(BUILD_DIR)/kernel.bin ::/

boot: $(BUILD_DIR)/boot.bin
$(BUILD_DIR)/boot.bin: always
	$(ASM) -i $(SOURCE_DIR) $(SOURCE_DIR)/bootsec.asm -f bin -o $(BUILD_DIR)/bootsec.bin

kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(ASM) -i $(SOURCE_DIR) $(SOURCE_DIR)/kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

tool-lba: $(TOOL_BUILD_DIR)/lba
$(TOOL_BUILD_DIR)/lba: always
	$(CC) -g -o0 $(TOOL_DIR)/lba.c -o $(TOOL_BUILD_DIR)/lba

tools-install:
	cp $(TOOL_BUILD_DIR)/* /bin

always:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(TOOL_BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*
test: floppy
	qemu-system-i386 -monitor stdio -fda $(BUILD_DIR)/floppy.img

