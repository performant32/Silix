OUTPUT_DIR:=bin
SRC_DIR:=src
.PHONY: default always fat12

default: fat12
always:
	mkdir -p $(OUTPUT_DIR)
fat12: always
	$(CC) $(SRC_DIR)/main.c -o $(OUTPUT_DIR)/fat12
