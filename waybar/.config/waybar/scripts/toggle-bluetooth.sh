#!/bin/bash

sudo rfkill toggle bluetooth
pkill -SIGRTMIN+8 waybar
