#!/usr/bin/python3
'''
Base class for plugins
'''
import sys
import argparse
#from os import geteuid

class Plugin:
    def __init__(self, **kwargs):
        self.name = kwargs["name"]
        self.summary = kwargs["summary"]
        self.description = kwargs["description"]
        self.author = kwargs["author"]
        self.ref = kwargs["ref"]
        self.category = kwargs["category"]
        self.needroot = kwargs["needroot"] if ("needroot" in kwargs.keys()) else False
        
        self.argparser = argparse.ArgumentParser(prog=self.name, description=self.description)
        self.args = None

    def execute(self):
        pass

    def intro(self):
        print("{:<15} {}".format("Plugin:", self.name))
        print("{:<15} {}".format("Author:", self.author))
        print("{:<15} {}".format("Description:", self.description))
        print("{:<15} {}".format("Reference:", self.ref))
        print("{:<15} {}".format("Category:", self.category))
        print()

    def run(self, arglist):
        self.args = self.argparser.parse_args(arglist)

        self.intro()
        self.execute()
    
    
