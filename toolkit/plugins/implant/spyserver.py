#!/usr/bin/python3
'''
spyserver class defination
not finish yet
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
                         usage = 'Run "run mksquashfs" will compress outputs/squashfs-root/ to new.squashfs .Run "run mksquashfs help" to see more parameters.')

        self.argparser.add_argument("--input", default="./outputs/squashfs-root/", help="squashfs dir")
        self.argparser.add_argument("--output", default="./outputs/new.squashfs", help="new squashfs file")
        self.argparser.add_argument("--comp", default="xz", help="compress method")

    def execute(self):
        #print("Run mksquashfs with parameter {}".format(str(self.args)))
        os.system("mksquashfs {} {} -comp {} -noappend -always-use-fragments".format(self.args.input, self.args.output, self.args.comp))
