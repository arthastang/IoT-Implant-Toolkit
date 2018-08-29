#!/usr/bin/python3
'''
odex2jar class defination
not finish yet
'''
import os
from toolkit.core.basic import Plugin


class Odex2Jar(Plugin):
    '''
    inherit from class Plugin
    '''
    def __init__(self):
        super().__init__(name = "odex2jar",
                         description = "odex to jar for Android",
                         classname = "Odex2Jar",
                         author = "Marvel Team",
                         ref = "https://github.com/arthastang/IoT-Implant-Toolkit",
                         category = "Software Analysis",
                         usage = 'Run "run odex2jar --input [odex folder]" will convert odex file to jar file.Run "run odex2jar help" to see more parameters.')

        self.argparser.add_argument("--input", help="input odex file")
        self.argparser.add_argument("--output", default="./outputs/new.jar", help="output java file")

    def execute(self):
        #print("Run plugin with parameter {}".format(str(self.args)))
        os.system("java -jar oat2dex.jar -o outputs/ odex {}".format(self.args.input))
        dexname = self.args.input.replace("odex", "dex")
        os.system("tookit/tools/dex-tools-2.1/d2j-dex2jar.sh {} -o {}".format(dexname, self.args.output))

