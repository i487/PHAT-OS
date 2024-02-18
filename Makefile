#   This file is part of PHAT-OS.
#
#   PHAT-OS is free software: you can redistribute it and/or modify it under the terms of the 
#    GNU General Public License as published by the Free Software Foundation, either version 3 
#    of the License, or (at your option) any later version.
#
#    PHAT-OS is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
#    without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#    See the GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along with PHAT-OS. 
#    If not, see <https://www.gnu.org/licenses/>. 

BUILD_DIR=build
SOURCE_DIR=src
TOOL_DIR=tool
TOOL_BUILD_DIR=build/tool

DISK_IMAGE=floppy.img

ASM=nasm
CC=gcc
QEMU=qemu-system-i386

DEBUG_QEMU_ARGS=--monitor stdio -fda $(BUILD_DIR)/$(DISK_IMAGE)
RUN_QEMU_ARGS=-fda $(BUILD_DIR)/$(DISK_IMAGE)
ASM_FLAGS=-D LOGO_ENABLE

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
	$(ASM) $(ASM_FLAGS) -i $(SOURCE_DIR) $(SOURCE_DIR)/kernel.asm -f bin -o $(BUILD_DIR)/kernel.bin

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

run:
	$(QEMU) $(RUN_QEMU_ARGS)

debug: floppy
	$(QEMU) $(DEBUG_QEMU_ARGS)