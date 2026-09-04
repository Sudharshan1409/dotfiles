#!/bin/bash

sudo rfkill toggle wifi
pkill -SIGRTMIN+8 waybar
