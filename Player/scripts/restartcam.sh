#!/bin/bash
#probably need to run as sudo
echo '1-8' | sudo tee /sys/bus/usb/drivers/usb/unbind
sleep 6
echo '1-8' | sudo tee /sys/bus/usb/drivers/usb/bind
sleep 6

uvcdynctrl -L default.gpfl

