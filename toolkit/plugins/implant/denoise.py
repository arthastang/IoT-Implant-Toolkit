#!/usr/bin/python3
'''
denoise class defination
not finish yet
'''
import os
from toolkit.core.basic import Plugin


class DeNoise(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "denoise",
                         description = "denoise scripts for audio snooping",
                         classname = "DeNoise",
                         author = "MarvelTeam",
                         ref = "https://github.com/arthtang/IoT-Implant-Toolkit",
                         category = "Binary implantation",
                         usage = 'Run "run denoise [pcm] [noise sample]" will automatically convert pcm to wav files with denoising. Not finished yet.')

        #self.argparser.add_argument("--input", default="./outputs/squashfs-root/", help="squashfs dir")
        #self.argparser.add_argument("--output", default="./outputs/new.squashfs", help="new squashfs file")
        #self.argparser.add_argument("--comp", default="xz", help="compress method")

    def execute(self):
        print("Run denoise.")
        #os.system("mksquashfs {} {} -comp {} -noappend -always-use-fragments".format(self.args.input, self.args.output, self.args.comp))
