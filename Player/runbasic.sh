killall -q java naoqi-bin naoqi hal espeak lua luajit luajit2 screen CalibrationServer

screen -dm -s /usr/bin/bash -S dcm  lua run_dcm.lua
sleep 1
screen -dm -s /usr/bin/bash -S cog lua run_cognition.lua
sleep 3
screen -dm -s /usr/bin/bash -S hor lua hoard_connection.lua
#screen -dm -s /usr/bin/bash -S motion lua /home/darwin/dev/merc/UPENN2013/Player/hoard_motion.lua
#sleep 14
#screen -dm -s /usr/bin/bash -S connection lua ./hoard_connection.lua
#sleep 1
#sleep 14
echo `screen -ls`


