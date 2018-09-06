#!/usr/bin/python3
'''
serialport class defination
not finish yet
'''
import os
import serial
from toolkit.core.basic import Plugin


class SerialPort(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "serialport",
                         description = "Modem control and terminal emulation",
                         classname = "SerialPort",
                         author = " ",
                         ref = "https://github.com/pyserial/pyserial",
                         category = "Serial port debugging",
                         usage = 'run minicom to setup debug terminal, with configuration(--conf)')

        self.argparser.add_argument("--conf", default="./outputs/default.conf", help="squashfs dir")

    def execute(self):
        pass
