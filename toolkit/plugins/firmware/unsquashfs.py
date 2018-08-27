#!/usr/bin/python3
'''
unsquashfs class defination
'''
import os
from toolkit.core.basic import Plugin


class UnSquashfs(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "unsquashfs",
                         description = "unpack squashfs filesystem",
                         classname = "UnSquashfs",
                         author = "Plougher",
                         ref = "https://github.com/plougher/squashfs-tools",
                         category = "Firmware Pack&Unpack",
                         usage = 'Run "run unsquashfs" will extract squashfs file system to outputs/squashfs-root.Run "run unsquashfs help" to see more parameters.')

        self.argparser.add_argument("--input", default="outputs/new.squashfs", help="squashfs dir")
        self.argparser.add_argument("--output", default="./outputs/squashfs-root/", help="new squashfs file")

    def execute(self):
        #print("Run mksquashfs with parameter {}".format(str(self.args)))
        os.system("unsquashfs -d {} {}".format(self.args.output, self.args.input))
