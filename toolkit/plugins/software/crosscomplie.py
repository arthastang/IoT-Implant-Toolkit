#!/usr/bin/python3
'''
crosscompile class defination
'''
import os
from toolkit.core.basic import Plugin


class CrossComplie(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "crosscomplie",
                         description = "Crosscomplie toolchain for ARMv7",
                         classname = "CrossComplie",
                         author = "Marvel Team",
                         ref = "https://github.com/arthastang/IoT-Implant-Toolkit",
                         category = "Software Anlysis",
                         usage = 'A wrapper of crosscompile toolchain for ARMv7.May support more structures later.')

    def execute(self):
        pass
