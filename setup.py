#!/usr/bin/python3
'''
Setup
'''
from setuptools import setup, find_packages

setup(
    name="IoT-Implant-Toolkit",
    version="1.0",
    urls="https://github.com/arthastang/IoT-Implant-Toolkit",
    author="Demesne",
    author_email="demesne0.0@gmail.com",
    description="Toolkit for implant attack of IoT devices.",
    packages=find_packages(),
    scripts=["IoT-Implant-Toolkit.py"],
    install_requires=["cmd2>=0.9.4", "pyserial>=3.4"],
    python_requires=">=3.6"
        
)

