#!/bin/bash
#MUST run with root permisions
# if down and up wlan0 and eth0?  anything else?
sudo ifdown wlan0
#sudo ifup wlan0

sudo ifdown eth0
sudo ifup eth0


