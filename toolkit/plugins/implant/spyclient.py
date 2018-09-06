#!/usr/bin/python3
'''
spyclient class defination
'''
import os
from toolkit.core.basic import Plugin


class SpyClient(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "spyclient",
                         description = "stable spy client for malware implantation",
                         classname = "SpyClient",
                         author = "MarvelTeam",
                         ref = "https://github.com/arthtang/IoT-Implant-Toolkit",
                         category = "Binary implantation",
                         usage = 'See scripts in toolkit/tools/spyclient')

    def execute(self):
        pass
