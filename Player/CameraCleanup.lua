require('init')
require('gcm')
require('vcm')
require('wcm')
require('Body')
require('unix')
require('os')
require('Motion')
require('OPCommManager')

--first kill everything that could stop me from sitting
--os.execute("kill $(ps aux | grep '[l]ua run_cognition.lua' | awk '{print $2}')")
--os.execute("kill $(ps aux | grep '[l]ua hoard_connection.lua' | awk '{print $2}')")

-- set that he should be penalized to make it sit down.
-- TeamGeneral won't broadcast info when the robot is penalized
wcm.set_horde_visionPenalty(1);


-- Write log
file = io.open("CameraCleanup.txt", "a")
file:write("Camera died so I am penalized time = " .. tostring(os.date()).. "\n");
file:close()

