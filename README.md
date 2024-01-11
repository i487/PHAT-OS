# PHAT-OS
My own operating system written in x86 Asm

This is my first attempt of creating my own operating system in x86 assembly.

## Build

### Installing necesary packaes
Building the system requiers following packages: `nasm`, `make`, `mtools`.
However running the system also requires `qemu-system-i386`.
On Debian based distributions simply run `sudo apt install nasm mtools qemu`.
On Arch or Manjaro run `sudo pacman -S nasm mtools qemu-full`

### Compiling
Before compiling the system you can check the build enviroment with `env_chck.sh`
To build the system simply run `make`. This will generate floppy.img file which is a bootable floppy image.

## Runing the system
To run the system you can write `floppy.img` to a media and run the system on real or you can also use an emulator of your choise. Makefile also provides `run` and `debug` targets which run the system automaticaly using Qemu.










P.S. Keep in mind I'm 15 years old...
