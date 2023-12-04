nasm -i /home/dann/osTst/src src/bootsec.asm -o build/bootsec.bin
nasm -i /home/dann/osTst/src src/boot.asm -o build/boot.bin

dd if=/dev/zero of=build/floppy.img bs=512 count=2880
mkfs.fat -F 12 -n "FS" build/floppy.img
dd if=build/bootsec.bin of=build/floppy.img conv=notrunc
