CC:=wcc
LD:=wlink
ASM:=nasm
CFLAGS:=-0 -zl -za -s -ecc
LD_FLAGS:=@linker.lk name $(BIN_DIR)/stage2.bin
ASM_FLAGS:=-f obj
SRC_DIR:=src
BIN_DIR:=
OBJ_DIR:=

ASM_OBJS:= $(patsubst src/%.asm,$(OBJ_DIR)/asm/%.obj,$(wildcard src/*.asm)) 
C_OBJS:= $(patsubst src/%.c,$(OBJ_DIR)/c/%.obj, $(wildcard src/*.c)) 
.PHONY: default always stage2
default: stage2 
always:
	mkdir -p $(BIN_DIR)/
	mkdir -p $(OBJ_DIR)/asm
	mkdir -p $(OBJ_DIR)/c
stage2: always $(ASM_OBJS) $(C_OBJS)
	$(LD) file {$(ASM_OBJS) $(C_OBJS)} $(LD_FLAGS) 
$(OBJ_DIR)/asm/%.obj: $(SRC_DIR)/%.asm
	echo $@
	$(ASM) $(ASM_FLAGS) $< -o $@
$(OBJ_DIR)/c/%.obj: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) $< -fo=$@
