ASM := nasm
ASM_FLAGS := -f bin
OBJ_DIR:=bin/objs
BIN_DIR:=bin
ISO_DIR:=bin/iso
BOOTLOADER_SRC:=src/bootloader
KERNEL_SRC:=src/kernel
STAGE1_BIN:=$(BIN_DIR)/stage1
STAGE2_BIN:=$(BIN_DIR)/stage2
STAGE2_OBJ:=$(OBJ_DIR)/stage2
BOOT_OPTIONS:=
.PHONY: default build_floppy run_floppy boot1 run_nographic clean fat12

default: build_floppy run_floppy

clean:
	rm -rf bin
make_files:
	echo $(wildcard src/boot/*.asm)
	mkdir -p $(OBJ_DIR)
	mkdir -p $(ISO_DIR)
build_floppy: make_files stage1 stage2
	dd if=/dev/zero of=bin/silix.floppy bs=512 count=2880
	mkfs.fat -F 12 bin/silix.floppy 
	mcopy -i bin/silix.floppy $(STAGE1_BIN)/stage1.bin ::/BOOT2.bin
	dd if=$(STAGE2_BIN)/stage2.bin of=bin/silix.floppy bs=512 count=1 conv=notrunc
stage1:
	$(MAKE) -C $(BOOTLOADER_SRC)/stage1 stage1 BIN_DIR=$(abspath $(STAGE1_BIN))
stage2:
	$(MAKE) -C $(BOOTLOADER_SRC)/stage2 stage2 OBJ_DIR=$(abspath $(STAGE2_OBJ)) BIN_DIR=$(abspath $(STAGE2_BIN))
run_floppy:
	qemu-system-x86_64 $(BOOT_OPTIONS) -fda $(BIN_DIR)/silix.floppy -boot  order=a
fat12:
	$(MAKE) -C tools/fat12/ fat12 OUTPUT_DIR=$(abspath bin/tools)
