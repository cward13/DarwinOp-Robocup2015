#!/bin/bash

# This is the regular mode and it will start up the processes that start
# dcm, cognition, horde connection, and horde itself.

screen -dm -s /usr/bin/bash -S horde lua ./hoard_connection.lua

sleep 3

# now start horde.  




