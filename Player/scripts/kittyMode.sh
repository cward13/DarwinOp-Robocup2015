#!/bin/bash

# starts robot in kitty soccer mode

cd $PLAYER # make sure you are in the right folder
GODIR=/home/darwin/dev/merc/darwin/UPENN2013/Player
cd $GODIR
echo "`pwd`" | cat >> KITTYLOG.txt
screen -dm -s /usr/bin/bash -S kitty lua ./kittySoccerHFA.lua


