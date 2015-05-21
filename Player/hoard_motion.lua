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
local hoard_functions = require "hoard_functions"
json = require("json")

gcm.say_id();

darwin = true;

ready = true;
smindex = 0;
initToggle = true;

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();
connected = false;

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
function initMotion()
	gcm.set_game_state(3);
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
	HeadFSM.entry();
	HeadFSM.sm:set_state('headStart');
	Body.set_head_hardness(.5);
--	HeadFSM.entry();
--	HeadFSM.sm:set_state('headStart');
--	headFSM.update();
--	BodyFSM.entry();	
end
previousState = "nil";
if(darwin) then
	wcm.set_horde_state("nil");
	initMotion();
	while(1) do
		gcm.set_game_state(3);
		Motion.update();
		Body.update();
		if(previousState ~= wcm.get_horde_state() and wcm.get_horde_state()~=nil) then
			print("doing some new state \"" .. wcm.get_horde_state().."\"")
			hoard_functions.hordeFunctions[wcm.get_horde_state()](nil,nil);
			--TODO not nil nil plz
			previousState = wcm.get_horde_state();	
		elseif (wcm.get_horde_state()==nil) then
			wcm.set_horde_state(previousState);
		end
		BodyFSM.update();	
		HeadFSM.update();	
		unix.usleep(.005*1E6);
	end	
end
