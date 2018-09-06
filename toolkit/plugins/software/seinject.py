#!/usr/bin/python3
'''
seinject class defination
not finish ye
'''
import os
from toolkit.core.basic import Plugin


class SeInject(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "seinject",
                         description = "SE inject tool for Android",
                         classname = "SeInject",
                         author = "xmikos",
                         ref = "https://github.com/xmikos/setools-android",
                         category = "Software Analysis",
                         usage = 'SE inject tool for Android')

    def execute(self):
        pass
