#!/bin/bash

sudo /home/linuxbrew/.linuxbrew/sbin/rfkill toggle bluetooth
pkill -SIGRTMIN+8 waybar
