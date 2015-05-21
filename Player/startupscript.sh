#!/bin/bash
echo 'hi'
#`echo "111111" | sudo killall -q naoqi-bin naoqi hal espeak lua luajit luajit2 screen`

screen -dm -s /usr/bin/bash -S dcm  lua ./run_dcm.lua
sleep 1

screen -dm -s /usr/bin/bash -S buttons lua ./gmu_buttons.lua


