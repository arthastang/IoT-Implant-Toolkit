#!/usr/bin/python3

import os
import inspect
import pkgutil
import importlib

class ToolList():
    '''
    search classes in toolist/plugins/ to generate toollist automatically
    '''
    
    def __init__(self):
        #init the tool list
        self.tooltable = {}
        #print("ToolList init")
        self.import_plugins("toolkit.plugins")

    def import_plugins(self, pkgname):
        for root, dirs, files in os.walk("toolkit/plugins/"):
            for name in files:
                modname = root.replace("/", ".") + "." + name.strip(".py")
                #print(modname)
                pmod = importlib.import_module(modname)
                for tname, obj in inspect.getmembers(pmod):
                    #print(kclass)
                    if inspect.isclass(obj) and tname.lower() == name.strip(".py"):
                        obj_ins = obj()
                        self.tooltable[tname.lower()] = {'name':obj_ins.name, 'description':obj_ins.description, 'classname':obj_ins.classname, 'category':obj_ins.category, 'modulepath':modname}
