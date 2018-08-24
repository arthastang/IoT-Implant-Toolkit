#!/usr/bin/python3
'''
mkbootimg class defination
'''
import os
from toolkit.core.common.basic import Plugin


class MkBootimg(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "mkbootimg",
                         description = "pack&unpack for boot.img of Android",
                         classname = "MkBootimg",
                         author = "xiaolu",
                         ref = "https://github.com/xiaolu/mkbootimg_tools",
                         category = "Firmware Pack&Unpack",
                         usage = 'Run "run mkbootimg [boot.img] [folderout]" or "run mkbootimg [folder] [newboot.img]"')

        self.argparser.add_argument("--input", help="boot.img when unpack or folder when pack")
        self.argparser.add_argument("--output", help="folder when unpack or boot.img when pack")

    def execute(self):
        #print("Run mksquashfs with parameter {}".format(str(self.args)))
        os.system("./toolkit/tools/mkbootimg_tools/mkboot {} {}".format(self.args.input, self.args.output))
