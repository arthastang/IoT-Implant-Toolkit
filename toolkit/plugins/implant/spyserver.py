#!/usr/bin/python3
'''
spyserver class defination
'''
import os
from toolkit.core.basic import Plugin


class SpyServer(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "spyserver",
                         description = "stable spy server for malware implantation",
                         classname = "SpyServer",
                         author = "Marvel Team",
                         ref = "https://github.com/arthastang/IoT-Implant-Toolkit",
                         category = "Binary implantation",
                         usage = 'See scripts in toolkit/tools/spyserver/')


    def execute(self):
        pass
