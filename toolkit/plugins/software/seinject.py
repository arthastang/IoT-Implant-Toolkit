#!/usr/bin/python3
'''
seinject class defination
not finish yet
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
                         usage = 'Run "run mksquashfs" will compress outputs/squashfs-root/ to new.squashfs .Run "run mksquashfs help" to see more parameters.')

        self.argparser.add_argument("--input", default="./outputs/squashfs-root/", help="squashfs dir")
        self.argparser.add_argument("--output", default="./outputs/new.squashfs", help="new squashfs file")
        self.argparser.add_argument("--comp", default="xz", help="compress method")

    def execute(self):
        #print("Run mksquashfs with parameter {}".format(str(self.args)))
        os.system("mksquashfs {} {} -comp {} -noappend -always-use-fragments".format(self.args.input, self.args.output, self.args.comp))
