![py3.6](https://img.shields.io/badge/python-3.6-blue.svg)
![MIT](https://img.shields.io/github/license/mashape/apistatus.svg)


# IoT-Implant-Toolkit
IoT-Implant-Toolkit is a framework of useful tools for malware implantation research of IoT devices. It is a toolkit consisted of essential software tools on firmware modification, serial port debugging, software analysis and stable spy clients. With an easy-to-use and extensible shell-like environment, IoT-Implant-Toolkit is a one-stop-shop toolkit simplifies complex procedure of IoT malware implantation. 

In our reasearch, we are able to implant Trojans in devices such as smart speakers, cameras, driving recorders and mobile translators With IoT-Implant-Toolkit.

## How to use

### Installation

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

### Run

Run the toolkit:
```bash
$ python3 -B IoT-Implant-Toolkit.py
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
Three commands supported：  
list: list all plugins  
run: run a specific plugin with "run [plugin] [parameters]"  
exit: exit  

## Features
Each software tool acts as a plugin which can be easily added into the framework.
   
There are more than ten plugins in four categories, including topics on serial port debugging, firmware pack&unpack, software analysis, and implanted spy programs.

### List of Plugins

Existing plugins in our framework:

Categories | Tools | Descriptions | Reference |
:---------: | :---------:| :----------:| :----------:|
Serial port debugging | pyserial | modem control and terminal emulation program | https://github.com/pyserial/pyserial |
Serial port debugging | baudrate.py | find correct baudrate | https://github.com/devttys0/baudrate |
Firmware Pack&Unpack | mksquashfs | create and extract Squashfs filesystem | https://github.com/plougher/squashfs-tools |
Firmware Pack&Unpack | mkbootimg_tools | Unpack&repack boot.img for Android | https://github.com/xiaolu/mkbootimg_tools |
Firmware Pack&Unpack | cramfs | make cramfs filesystem |  https://sourceforge.net/projects/cramfs/files/cramfs/1.1/ |
Firmware Pack&Unpack | mountimg | mount&unmount ext4 filesystems for Android system.img&data.img |  On our github |
Software Analysis | setools-android | setools for Android with sepolicy-inject | https://github.com/xmikos/setools-android |
Software Analysis | odex unpack | Odex to smali for Android | on our Github |
Binary implant | spy client&server | a stable spy client and server, source and pre-built bins | on our Github |


### Create new plugins
Code structure:

```bash
--IoT-Implant_toolkit.py         #Startup script
--outputs/                       #Default folder of outputs
--toolkit/                       
  |---core/                      
      |---basic/                 #Basic plugin class defination
      |---cli/                   #Shell-like cli defination
      |---toollist/              #Auto updating toollist of plugins 
  |---plugins/                   
      |---firmware/              #Plugins for firmware modification
      |---implant/               #Plugins for generate spy programs
      |---serialport/            #Plugins for serial port debugging
      |---software/              #Plugins for software analysis especially for Android
  |---tools/                     #Other tools

```

Create [newplugin].py in corresponding folder(category) and define init attributes to add a new plugin to IoT-Implant-Toolkit.The framework will detect new plugin automatically when startup.


## Other tools

### Hardware tools

Essential hardware tools for malware implantation research.See pictures in HardwareTools/ .

Name | Description |
:---------: | :---------:|
Soldering Iron | Solder tools |
Solder Wire | Solder tools |
Solder Paste | Solder tools |
Solder Wick | Solder tools |
Hot Air Gun | Solder tools |
Reballing Tool | Reballing tool |
usb to ttl | Debug / Console cable |
Dupont Wire | Electrical wire |
EPROM Burner Programmer | Burner Programmer |

### Other useful software tools
We have not added more plugins due to time limitation.

Chart below are tools not fits our framework, but may be useful.

We hope that IoT-Implant-Tookit will be an essential toolkit in malware implantation.

Categories | Tools | Descriptions | Reference |
:---------: | :---------:| :----------:| :----------:|
Firmware Analysis | binwalk | a fast, easy to use tool for analyzing, reverse engineering, and extracting firmware images | https://github.com/ReFirmLabs/binwalk |
Firmware Modify |firmware mod kit | a collection of scripts and utilities to extract and rebuild linux based firmware images | https://github.com/rampageX/firmware-mod-kit |
Cross Compiler | buildroot | Cross Compiler for arm mips powerpc | https://buildroot.org/ |
