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
hfa = require('hfa')
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
unix.usleep(2*1E6);
--gcm.say_id();
Speak.talk("My Player ID Is defiantly the number " .. Config.game.playerID);
darwin = true;

lastTimeFound = Body.get_time();
ready = true;
smindex = 0;
initToggle = true;
updateAllTimer=0;
sendFeaturesTimer =0;
-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();
connected = false;

function inspect(key, value)
	table.foreach(value,print)
end

function connectToHorde(port)
		local socket = require("socket")
                local client = assert(socket.connect("127.0.0.1", port))
                --local client = server:accept()
              	return client;
end

function executeMachine(myMachine)
        gcm.set_game_state(3); -- this probably wont do anything... trying to prevent a bug where the robot doesnt stand up immediately
	print("got into con thread");
	if( darwin ) then
                local tDelay = 0.005 * 1E6; -- Loop every 5ms


 -- setup the server
               client = connectToHorde(4009);--initialize connection, wait for it.....
               connected = true;
--               darwinComm = setupUDPDarwins();
                		startSending = {}
        	startSending.action="StartSending";
        	startSending.args = "";
		startSending.ackNumber = 0;
	        print("to send " .. tostring(json.encode(startSending)) .. " \n ");
       		client:send(json.encode(startSending) .. "\n");
		print("connected");
  		wcm.set_horde_ackNumber(1);
		setDebugTrue();
                while connected do
			--print("setting time out");
			client:settimeout(.05);
			--print("setting recval");
			recval = client:receive()
			--print("about to do my pcall");
			status, recJson = pcall(json.decode,recval);
			--print("comparing status");
			if(recval ~= nil and status == true) then
               		 status = string.sub(recval, 1, 1) == "{"
            		end
			if(recval == nil) then
				status = false;
			end
			--print("recjason is " .. tostring(recJson))
			setDebugTrue();
			if(recJson~=nil) then
			--	print("status is " .. tostring(status) .. " received acknumber: " .. tostring(recJson.ackNumber) .. "expected " .. tostring(wcm.get_horde_ackNumber())); 
				if (status == true and recJson.ackNumber == wcm.get_horde_ackNumber()) then
			--		print("I GOT A MESSAGE");
					isBallLost();
				    	--kitty.wcm.get_horde_ballLost() = wcm.get_horde_ballLost()	
					while wcm.get_horde_sentBehavior() == 0 do
			--			print("thinking of a new state for you....");
						isBallLost();
						--print("pulsing on " .. wcm.get_horde_ballLost());
						pulse(myMachine);
					end
					wcm.set_horde_sentBehavior(0);
	
			--		print("ball detect? : " .. tostring(vcm.get_ball_detect()));
					--pulse(myMachine);
				else
			--		print("waiting for an ack");
				end
				
			else
			--	print("havent Received a message since i sent the last one");
			end
		end
        end
end
function doAction(action)
	action["ackNumber"] = wcm.get_horde_ackNumber();

	wcm.set_horde_sentBehavior(1);-- let the pulsing machine know we sent a behavior, and we can wait for an ack

	wcm.set_horde_ackNumber( wcm.get_horde_ackNumber()+1);-- ack number we should expec back should be bigger

	client:send(json.encode(action) .. "\n");
end	
function isBallLost()
	--print("got into ball lost")
	if vcm.get_ball_detect() ~= 0 then
		wcm.set_horde_ballLost(0);
		lastTimeFound = Body.get_time();
	elseif(Body.get_time() - lastTimeFound > 5) then
		wcm.set_horde_ballLost(1);
	end
	return wcm.get_horde_ballLost();
	--print("got out of ball lost");
end

function setVelocity(x,y,a)
	action = {}
	action.args = {}
	if(x == nil)
	then	x =0; end
	if(y== nil) then y=0; end
	if(a == nil) then a=0;	 end
	if(x>.2) then x = .2; end
	if(y>.2) then y=.2; end
	if(x<-.2) then x = -.2 end
	if(y<-.2) then y=-.2 end
	
	action.args.x = x;
	action.args.y = y;
	action.args.a = a;
--	print("velocity is " .. x .. ", " .. y .. ", " .. a);
	wcm.set_horde_walkVelocity(vector.new({x,y,a}));
	vel = wcm.get_horde_walkVelocity();
	--print("velocity is " .. vel[1]
	action.action = "setVelocity";     	
	doAction(action);
end
function stop()
	action  = {}
        action["action"] = "stop";
        action["args"] = "";
	doAction(action);
end
function kickBall()
	action = {}
	action.args = "nan";
	action.action = "kickBall";
	doAction(action);
end
function scan()
	action = {}
	action.args = "nan";
	action.action = "scan";
	doAction(action);
end
function track()
	action = {}
	action.args = "nan"
	action.action = "track";
	doAction(action);
end
function lookGoal()
	action = {}
	action.args = "nan";
	action.action = "lookGoal";
	doAction(action);
end

