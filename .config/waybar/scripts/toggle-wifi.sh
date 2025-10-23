#!/bin/bash

sudo /home/linuxbrew/.linuxbrew/sbin/rfkill toggle wifi
pkill -SIGRTMIN+8 waybar
