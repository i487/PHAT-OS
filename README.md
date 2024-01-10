# PHAT-OS
My own operating system written in x86 Asm

This is my first attempt of creating my own operating system in x86 assembly.

## Build
Before compiling the system you can check the enviroment with `env_chck.sh`
System is compiled with NASM.
To build the system simply run `make`. This will generate floppy.img file which is a bootable floppy image.

## Runing the system
To run the system you can simply boot from floppy.img using qemu or you can write this image to a media and run the system on real hardware. Makefile also provides `run` and `debug` targets which run the system automaticaly using Qemu










P.S. Keep in mind I'm 15 years old...
