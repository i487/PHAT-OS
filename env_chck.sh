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

#!/bin/bash

#System check
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "Running Linux\n"
elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "Running Mac OS\n"
elif [[ "$OSTYPE" == "cygwin" ]]; then
        echo -e "Running in POSIX compatibility layer\n"
elif [[ "$OSTYPE" == "msys" ]]; then
        echo -e "Running in msys\n"
elif [[ "$OSTYPE" == "win32" ]]; then
        echo -e "Running Windows\n" #Not sure if this can happend 
elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo -e "Running BSD\n"
else
        echo -e "\e[33mRunning on an unknown system, but it could work!\n"
fi


#Check for nasm presense
if ! nasm --version &> /dev/null
then
        echo -e "\e[31mNASM could not be found!\e[0m\n"
        exit 1
else
        nasm --version | awk NR==1
        echo -e "\e[32mOK!\e[0m\n"
fi

#Check for qemu-system-i386 presense 
if ! qemu-system-i386 --version &> /dev/null
then
        echo -e "\e[33mqemu-sysytem-i386 could not be found!\n"
        echo -e "qemu is optional, system will still build\nbut \e[1mrun \e[0m\e[33mand \e[1mdebug \e[0m\e[33m make targets won't work!"
        exit 1
else
        qemu-system-i386 --version | awk NR==1
        echo -e "\e[32mOK!\e[0m\n"
fi

#Check for make presense 
if ! make --version &> /dev/null
then
        echo -e "\e[31mMake could not be found!\e[0m\n"
        exit 1
else
        make --version | awk NR==1
        echo -e "\e[32mOK!\e[0m\n"
fi

#Check for mtools presense
if ! mtools --version &> /dev/null
then
        echo -e "\e[31mMtools could not be found!\e[0m\n"
        exit 1
else
        mtools --version | awk NR==1
        echo -e "\e[32mOK!\e[0m\n"
fi

echo -e "\e[1m\e[32mAll good! Ready to build the system!\e[0m\n"