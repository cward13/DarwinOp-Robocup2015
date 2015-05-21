module(... or '', package.seeall)

-- Get Platform for package path
cwd = '.';
local platform = os.getenv('PLATFORM') or '';
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end

-- Get Computer for Lib suffix
local computer = os.getenv('COMPUTER') or '';
if (string.find(computer, 'Darwin')) then
  -- MacOS X uses .dylib:
--  package.cpath = cwd .. '/Lib/?.dylib;' .. package.cpath;
  package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
else
  package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
end

package.path = cwd .. '/?.lua;' .. package.path;
package.path = cwd .. '/Util/?.lua;' .. package.path;
package.path = cwd .. '/Config/?.lua;' .. package.path;
package.path = cwd .. '/Lib/?.lua;' .. package.path;
package.path = cwd .. '/Dev/?.lua;' .. package.path;
package.path = cwd .. '/Motion/?.lua;' .. package.path;
package.path = cwd .. '/Motion/keyframes/?.lua;' .. package.path;
package.path = cwd .. '/Motion/Walk/?.lua;' .. package.path;
package.path = cwd .. '/Vision/?.lua;' .. package.path;
package.path = cwd .. '/World/?.lua;' .. package.path;
package.path = cwd .. '/Lib/json4lua-0.9.50/?/?.lua;' .. package.path
require('init')
require('unix')
require('Config')
require('shm')
require('vector')
require('vcm')
require('gcm')
require('wcm')
require('mcm')
require('Speak')
require('getch')
require('Body')
require('Motion')
json = require("json")
--client = "nil"
function sendFeatures (args, client)	
	features = {};
	features["poseX"] = wcm.get_pose().x;
	features["poseY"] = wcm.get_pose().y;
	features["poseA"] = wcm.get_pose().a;
	features["ballDetect"] = vcm.get_ball_detect();
	features["ballX"] = wcm.get_ball_x();
	features["ballY"] = wcm.get_ball_y();
        features["doneFrontApproach"] = wcm.get_horde_doneFrontApproach();	
	print("sending some features, yo\n");-- wcm.set_horde_doneFrontApproach("true");
	print(json.encode(features) .. "\n");
	client:send(json.encode(features) .. "\n");
	-- Send the features to horde via the client
	-- args may contain the amount of time to wait between sending
	
end
smindex=0
package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;

package.path = cwd..'/BodyFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
require('BodyFSM')
require('HeadFSM')
--HeadFSM.entry();
--HeadFSM.sm:set_state('headStart');
--Body.set_head_hardness(.5); -- required to at least set the hardness in order for motions to work
leftArmMotion = math.pi/180*vector.new({60,30,-30});
--Body.set_larm_hardness({0.5,0.5,0.5});
--Body.set_larm_:command(leftArmMotion);
function inspect(key, value)
	table.foreach(value,print)
end

--table.foreach(Body.get_sensor_data(),inspect)

--my stuff, ugly
count = 0;
function initMotion()
	BodyFSM.entry();
	Motion.entry();
        unix.usleep(1.00*1E6);

        Body.set_body_hardness(.50);
        Motion.event("standup");
        k = 0;
        while(.005 * k < 5.27) do
                Motion.update();
                Body.update();
                unix.usleep(.005*1E6);
                k=k+1;
        end
	Motion.event("standup");
	unix.usleep(3.0*1E6);
	BodyFSM.sm:set_state('bodyStop')		
	BodyFSM.update();
	
--	BodyFSM.entry();	
end
--start "main"
if(1) then 
	wcm.set_horde_sendStatus("nil");
	local socket = require("socket")
        print("socket assert");
        local server = assert(socket.bind("*", 4010))
        print("socket accept")
        local client = server:accept()
        print("setting global client");
        --      wcm.set_horde_client(client);
        print("socket accepted");
        local connected = true;
        print("connected")

	while (1) do	
   		--coroutine.resume(co,wcm.get_horde_client(),nil);	
		if(wcm.get_horde_sendStatus()=="StartSending") then
			sendFeatures(nil, client);--TODO NO NIL PLZ
		end
		unix.usleep(.005*1E6);
	end
end
--connection drew stuff, seriously i'm ruining this beautiful code

