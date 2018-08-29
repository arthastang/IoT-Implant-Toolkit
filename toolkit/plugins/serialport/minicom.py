#!/usr/bin/python3
'''
minicom class defination
not finish yet
'''
import os
from toolkit.core.basic import Plugin


class MiniCom(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "minicom",
                         description = "Modem control and terminal emulation",
                         classname = "MiniCom",
                         author = " ",
                         ref = "https://github.com/pyserial/pyserial",
                         category = "Serial port debugging",
                         usage = 'Run "run mksquashfs" will compress outputs/squashfs-root/ to new.squashfs .Run "run mksquashfs help" to see more parameters.')

        self.argparser.add_argument("--input", default="./outputs/squashfs-root/", help="squashfs dir")
        self.argparser.add_argument("--output", default="./outputs/new.squashfs", help="new squashfs file")
        self.argparser.add_argument("--comp", default="xz", help="compress method")

    def execute(self):
        #print("Run mksquashfs with parameter {}".format(str(self.args)))
        os.system("mksquashfs {} {} -comp {} -noappend -always-use-fragments".format(self.args.input, self.args.output, self.args.comp))
