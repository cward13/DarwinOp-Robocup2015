#!/bin/bash
killall -9 lua java
GODIR=/home/darwin/dev/merc/darwin/UPENN2013/Player
cd $GODIR
#screen -dm -L -s /usr/bin/bash -S dcm  
lua run_dcm.lua &
echo "ran dcm `date`" | cat >> dcmlog.txt
sleep 2
lua gmu_buttons.lua &
echo "ran gmu_buttons `date`" | cat >> gmu_buttonslog.txt
