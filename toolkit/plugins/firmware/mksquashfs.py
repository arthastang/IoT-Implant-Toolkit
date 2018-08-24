#!/usr/bin/python3
'''
mksquashfs class defination
'''
import os
from toolkit.core.common.basic import Plugin


class MkSquashfs(Plugin):
    def __init__(self):
        super().__init__(name = "mksquashfs",
                         summary = "pack&unpack for squashfs filesystem",
                         description = "pack&unpack for squashfs filesystem",
                         author = "Plougher",
                         ref = "https://github.com/plougher/squashfs-tools",
                         category = "Firmware Pack&Unpack")

        self.argparser.add_argument("--input", default="./outputs/squashfs-root/", help="firmware dir")
        self.argparser.add_argument("--output", default="./outputs/new.squashfs", help="new squashfs file")
        self.argparser.add_argument("--comp", default="xz", help="compress method")

    def execute(self):
        print("Run mksquashfs with parameter {}".format(str(self.args)))
        os.system("mksquashfs {} {} -comp {} -noappend -always-use-fragments".format(self.args.input, self.args.output, self.args.comp))
