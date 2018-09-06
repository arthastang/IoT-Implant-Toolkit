#!/usr/bin/python3
'''
baudrate class defination
'''
import os
from toolkit.core.basic import Plugin


class BaudRate(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "baudrate",
                         description = "Find correct baudrate",
                         classname = "BaudRate",
                         author = "Craig Heffner",
                         ref = "https://github.com/biw/Baudrate.py",
                         category = "Serial port debugging",
                         usage = 'find correct baud rate.')

    def execute(self):
        pass
