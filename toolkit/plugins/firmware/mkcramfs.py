#!/usr/bin/python3
'''
mkcramfs class defination
not finish yet
'''
import os
from toolkit.core.basic import Plugin


class MkCramfs(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "mkcramfs",
                         description = "pack&unpack for cramfs filesystem",
                         classname = "MkCramfs",
                         author = " ",
                         ref = "https://sourceforge.net/projects/cramfs/files/cramfs/1.1",
                         category = "Firmware Pack&Unpack",
                         usage = 'We will open-source it later.')


    def execute(self):
        print("We will open-source it later.")
