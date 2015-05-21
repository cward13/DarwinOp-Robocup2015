#!/bin/bash

## The camera died!
## so run the CameraCleanup.lua file
cd /home/darwin/dev/merc/darwin/UPENN2013/Player/
touch cameradied.bad
lua CameraCleanup.lua

