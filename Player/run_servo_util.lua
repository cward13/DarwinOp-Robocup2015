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
myFunctions = {}



myFunctions["getServos"] = function (args, client)
	print("You found getServos with args " .. args);
	thedata = Body.get_sensor_data();
	table.foreach(thedata, inspect);
	client:send(json.encode(thedata));
	print("Sent the sevo data!")
	print(json.encode(thedata))
end

myFunctions["setServos"] = function (args, client)

	print("You found setServos!!!");
	table.foreach(args, print)
	print(args.index .. " " .. args.current);
	Body.set_servo_command(args.index, math.pi/180*args.current)
end

myFunctions["setServoHardness"] = function (args, client)

	print("you called setServoHardness");
	Body.set_servo_hardness(args.index, args.hardness);

end

co = nill;--coroutine.create(function (args, client)
	
--	client:send(json.encode(thedata));
	-- Send the features to horde via the client
	-- args may contain the amount of time to wait between sending
	
--)
myFunctions["StartSending"] = function (args, client)
	coroutine.resume(co,args, client);
end

myFunctions["StopSending"] = function (args, client)
	coroutine.yield(co)
end


myFunctions["disconnect"] = function (args, client)
	client:close();
	connected = false;
end


myFunctions["doHordeMotion"] = function(args, client)

	hordeFunctions[args.action](args.args, client);

end

hordeFunctions = {}

hordeFunctions["headMotion"] = function(args, client)

end




function update(servData, client)
  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  vcm.set_camera_teambroadcast(1); --Turn on wireless team broadcast
	print("In update")
	req = json.decode(servData)

	print("Received action "..req.action);
	myFunctions[req.action](req.args, client)
    
  Motion.update();
  Body.update();
end

--package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
--require('HeadFSM')
--HeadFSM.entry();
--HeadFSM.sm:set_state('headStart');
--Body.set_head_hardness(.5); -- required to at least set the hardness in order for motions to work
leftArmMotion = math.pi/180*vector.new({60,30,-30});
--Body.set_larm_hardness({0.5,0.5,0.5});
--Body.set_larm_command(leftArmMotion);
function inspect(key, value)
	table.foreach(value,print)
end

--table.foreach(Body.get_sensor_data(),inspect)


if( darwin ) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms


 -- setup the server
  local socket = require("socket")
  local server = assert(socket.bind("*", 40009))

  local client = server:accept()
  connected = true;
  print("connected")
  


  while connected do
    --client:settimeout(10)
    local line, err = client:receive()
    
    if not err then
      print(line);
      update(line, client);
    elseif err == "closed" then
	print(err)
	connected = false;
    else
	print(err)
    end
    --client:close()
    
    unix.usleep(tDelay);
  end
end

