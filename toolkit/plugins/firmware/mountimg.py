#!/usr/bin/python3
'''
mountimg class defination
not finish yet
'''
import os
from toolkit.core.basic import Plugin


class MountImg(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "mountimg",
                         description = "Mount Android ext4 filesystem",
                         classname = "MountImg",
                         author = "Marvel Team",
                         ref = "https://github.com/arthastang/IoT-Implant-Toolkit",
                         category = "Firmware Pack&Unpack",
                         usage = 'We will open-source it later.')


    def execute(self):
        pass
