# IoT-Implant-Toolkit
A framework of useful tools for malware implantation research of IoT devices. 

## Implant Toolkit
A framework consisted of essential software tools for malware implantation research.

Tools/Plugins List:

Topic | Tool | Description | Source
:---------: | :---------:| :----------:| :----------:|
Serial port debugging | minicom/pyserial | modem control and terminal emulation program | https://github.com/pyserial/pyserial |
Serial port debugging | baudrate.py | find correct baudrate | https://github.com/devttys0/baudrate |
Firmware Pack&Unpack | mksquashfs | create and extract Squashfs filesystem | https://github.com/plougher/squashfs-tools |
Firmware Pack&Unpack | mkbootimg_tools | Unpack&repack boot.img for Android | https://github.com/xiaolu/mkbootimg_tools |
Software Analysis | setools-android | setools for Android with sepolicy-inject | https://github.com/xmikos/setools-android |
Software Analysis | odex unpack | Odex to smali for Android | on our Github |
Binary implant | spy client&server | a stable spy client and server, source and pre-built bins | on our Github |
Firmware Analysis | binwalk | a fast, easy to use tool for analyzing, reverse engineering, and extracting firmware images | https://github.com/ReFirmLabs/binwalk |
Firmware Modify |firmware mod kit | a collection of scripts and utilities to extract and rebuild linux based firmware images | https://github.com/rampageX/firmware-mod-kit |
Cross Compiler | buildroot | Cross Compiler for arm mips powerpc | https://buildroot.org/ |
filesystem Analysis | cramfs-1.1 | make cramfs filesystem |  https://sourceforge.net/projects/cramfs/files/cramfs/1.1/ |




### How to use
Make sure you have git, python3 and setuptools installed.


Download source code from our Github:
```bash
$ git clone https://github.com/arthastang/IoT-Implant-Toolkit.git

```
Set up environment and install dependencies:
```bash
$ cd IoT-Implant-Toolkit/
$ python3 setup.py install

```
Run the toolkit:
```bash
$ python3 IoT-Implant-Toolkit.py
 _____   _______   _____                 _             _       _______          _ _    _ _   
|_   _| |__   __| |_   _|               | |           | |     |__   __|        | | |  (_) |  
  | |  ___ | |______| |  _ __ ___  _ __ | | __ _ _ __ | |_ ______| | ___   ___ | | | ___| |_ 
  | | / _ \| |______| | | '_ ` _ \| '_ \| |/ _` | '_ \| __|______| |/ _ \ / _ \| | |/ / | __|
 _| || (_) | |     _| |_| | | | | | |_) | | (_| | | | | |_       | | (_) | (_) | |   <| | |_ 
|_____\___/|_|    |_____|_| |_| |_| .__/|_|\__,_|_| |_|\__|      |_|\___/ \___/|_|_|\_\_|\__|
                                  | |                                                        
                                  |_|                                                        
            
                                 IoT-Implant-Toolkit
            -------------------------------------------------------------
                      A Framework for IoT implantation research.

                                   by Marvel Team

            Command:
            list - List all tools
            run - Run a specific tool
            exit - Exit

                
[Implant-Toolkit]>

```


## Hardware tools
Essential hardware tools for malware implantation research.See pictures in HardwareTools/ .

Name | Description |
:---------: | :---------:|
Soldering Iron | - |
Solder wire | - |
... | ... |
