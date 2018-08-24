#!/bin/sh
# Copyright (C) 2006-2009 OpenWrt.org

set_state() { echo $1 > /tmp/booting_state; }
