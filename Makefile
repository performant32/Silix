ASM := nasm
ASM_FLAGS := -f bin
# Boot Options are [floppy]
BOOT_FS:=fat12
# Modes are [graphic, nographic]
BOOT_MODE:=nographic
# Modes are [IA, AArch]
Arch=IA
# Qemu Boot flags
BOOT_FLAGS:= 
ifeq ("$(BOOT_MODE)", "nographic")
	BOOT_FLAGS:= -nographic
else
endif
KERNEL_SRC:=src/kernel
BIN_DIR:=bin/$(Arch)
OBJ_DIR:=$(BIN_DIR)/objs
ISO_DIR:=$(BIN_DIR)/iso
BOOTLOADER_SRC:=src/bootloader/$(Arch)/$(BOOT_FS)
STAGE1_BIN:=$(BIN_DIR)/$(BOOT_FS)/stage1
STAGE2_BIN:=$(BIN_DIR)/$(BOOT_FS)/stage2
STAGE2_OBJ:=$(OBJ_DIR)/$(BOOT_FS)/stage2
KERNEL_BIN:=$(BIN_DIR)/kernel
KERNEL_OBJ:=$(OBJ_DIR)/kernel

.PHONY: default setup_flags build_floppy run_floppy boot1 test run_nographic clean fat12
default: build_floppy run_floppy

clean:
	rm -rf bin
make_files:
	mkdir -p $(OBJ_DIR)
	mkdir -p $(ISO_DIR)
build_floppy: make_files stage1 stage2 test
	dd if=/dev/zero of=$(BIN_DIR)/silix.floppy bs=512 count=2880
	mkfs.fat -F 12 $(BIN_DIR)/silix.floppy 
	mcopy -i $(BIN_DIR)/silix.floppy $(STAGE2_BIN)/stage2.bin ::/STAGE2.bin
	dd if=$(STAGE1_BIN)/stage1.bin of=$(BIN_DIR)/silix.floppy bs=512 count=1 conv=notrunc
	mcopy -i $(BIN_DIR)/silix.floppy $(BIN_DIR)/test.bin ::/TEST.BIN
	echo "Hello World Test" | dd ibs=11 obs=512 seek=20 of=bin/silix.floppy count=1 conv=notrunc
stage1:
	$(MAKE) -C $(BOOTLOADER_SRC)/stage1 stage1 BIN_DIR=$(abspath $(STAGE1_BIN))
stage2:
	$(MAKE) -C $(BOOTLOADER_SRC)/stage2 stage2 OBJ_DIR=$(abspath $(STAGE2_OBJ)) BIN_DIR=$(abspath $(STAGE2_BIN))
kernel:
	$(MAKE) -C $(KERNEL_SRC) kernel BIN_DIR=$(abspath $(KERNEL_BIN)) OBJ_DIR=$(abspath $(KERNEL_OBJ))
run_floppy: 
	qemu-system-x86_64 $(BOOT_FLAGS) -fda $(BIN_DIR)/silix.floppy -boot order=a
fat12:
	$(MAKE) -C tools/fat12/ fat12 OUTPUT_DIR=$(abspath bin/tools)
test:
	$(ASM) $(ASM_FLAGS) $(BOOTLOADER_SRC)/test.asm -o $(BIN_DIR)/test.bin
