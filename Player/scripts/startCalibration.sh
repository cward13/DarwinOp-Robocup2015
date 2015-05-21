#killall -q CalibrationServer naoqi-bin naoqi hal espeak lua luajit luajit2 screen
GODIR=/home/darwin/dev/merc/darwin/UPENN2013/Player/scripts
cd $GODIR
sh restartcam.sh &
sleep 13
./CalibrationServer & 

sleep 1
