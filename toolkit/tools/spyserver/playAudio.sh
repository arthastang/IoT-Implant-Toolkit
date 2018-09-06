#!/bin/sh

echo "Play Audio..."
nc -lp 2222 | aplay -r 48000 -f S16_LE -t raw
