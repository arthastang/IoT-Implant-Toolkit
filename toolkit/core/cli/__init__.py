#!/usr/bin/python3

import inspect
import argparse
import importlib
from cmd2 import Cmd, with_argument_list
from toolkit.core.toollist import ToolList

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

        self.toollist = {}

        self.runtool = argparse.ArgumentParser(prog="run", description="Exec a plugin")
        self.runtool.add_argument("pluginname", help="name of the plugin")

    def do_list(self, args):
        '''
        List the tools avaliable
        '''
        tlist = ToolList()
        self.toollist = tlist.tooltable
        print("{:<20} {:<30} {}".format("PLUGINS", "CATEGORY", "DESCRIPTIONS"))
        print("{:<20} {:<30} {}\n".format("*******", "********", "************"))

        for eachtool in self.toollist.keys():
            print("{:<20} {:<30} {}".format(eachtool, self.toollist[eachtool]['category'], self.toollist[eachtool]['description']))
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

        plugin_name = toolname.pluginname

        print("Run plugin:{} with arguments:{}".format(plugin_name, str(toolarg)))

        if plugin_name in self.toollist.keys():
            #get the class name from toollist dict
            import_mod = importlib.import_module(self.toollist[plugin_name]['modulepath'])
            for tname, obj in inspect.getmembers(import_mod):
                if inspect.isclass(obj) and tname == self.toollist[plugin_name]['classname']:
                    tool_ins = obj()
                    tool_ins.run(toolarg)
        else:
            print("Plugin not found.")

        print()


