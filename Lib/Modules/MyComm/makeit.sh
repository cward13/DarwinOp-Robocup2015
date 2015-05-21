#!/bin/bash
g++ localComm.cpp -llua -llualib -c -fPIC
g++ -shared -o MyComm.so localComm.o
cp MyComm.so ../../../Player/Lib/
