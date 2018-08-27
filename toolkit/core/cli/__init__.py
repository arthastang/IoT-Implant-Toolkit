#!/usr/bin/python3

import argparse
#import pkgutil
from cmd2 import Cmd, with_argument_list
from toolkit.plugins.firmware.mksquashfs import MkSquashfs
from toolkit.plugins.firmware.unsquashfs import UnSquashfs
from toolkit.plugins.firmware.mkbootimg import MkBootimg
#from toolkit.core.toollist import ToolList

class Cli(Cmd):
    '''
    Class Cli defination

    '''
    Cmd.do_exit = Cmd.do_quit

    def __init__(self, prompt=None, intro=None, toollist=None):
        self.prompt = prompt
        self.intro = intro
        self.allow_cli_args = False
        self.allow_redirection = False
        self.locals_in_py = False
        super().__init__()
        #self.del_defaultcmds()

        self.toollist = toollist
        self.runtool = argparse.ArgumentParser(prog="run", description="Exec a plugin")
        self.runtool.add_argument("pluginname", help="name of the plugin")

    def do_list(self, args):
        '''
        List the tools avaliable
        '''
        print("{:<20} {:<30} {}".format("PLUGINS", "CATEGORY", "DESCRIPTIONS"))
        print("{:<20} {:<30} {}\n".format("*******", "********", "************"))

        for eachtool in self.toollist:
            print("{:<20} {:<30} {}".format(eachtool, self.toollist[eachtool][1], self.toollist[eachtool][2]))
        print()

    @with_argument_list
    def do_run(self, arglist):
        '''
        Run tool selected
        '''
        argnum = len(arglist)
        if argnum == 0 or (argnum == 1 and ('-h' in arglist or '--help' in arglist)):
            self.runtool.print_help()
            return

        toolname, toolarg = self.runtool.parse_known_args(arglist)

        pluginnam = toolname.pluginname

        print("Run plugin:{} with arguments:{}".format(pluginnam, str(toolarg)))

        if pluginnam in self.toollist.keys():
            #print(pluginnam)
            #get the class name from toollist dict
            toolobj = globals()[self.toollist[pluginnam][0]]
            #print(toolobj)
            toolinstance = toolobj()
            toolinstance.run(toolarg)
        else:
            print("Plugin not found.")

        print()


