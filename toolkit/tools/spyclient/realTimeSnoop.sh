#!/bin/sh

echo "Send Audio..."
arecord -Dhw:0,0 -f S16_LE -r 48000 | nc 172.27.35.7 2222
