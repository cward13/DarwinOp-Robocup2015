module(... or '', package.seeall)
--setDebugFalse();
-- Get Platform for package path
cwd = '.';
local platform = os.getenv('PLATFORM') or '';
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end
setDebugFalse()
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
require('World')
setDebugFalse();
local hoard_functions = require "hoard_functions"
json = require("json")
unix.usleep(2*1E6);
--gcm.say_id();
--Speak.talk("My Player ID Is defiantly the number " .. Config.game.playerID);
darwin = true;

ready = true;
smindex = 0;
initToggle = true;
updateAllTimer=0;
sendFeaturesTimer =0;
-- main loop
count = 0;
lcount = 0;
ackNumber = 0;
tUpdate = unix.time();
connected = false;

package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
package.path = cwd..'/GameFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;


package.path = cwd..'/BodyFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
--currentBodyFSM = require('BodyFSM')
require('BodyFSM');
require('HeadFSM');
--HeadFSM.entry();
--HeadFSM.sm:set_state('headStart');
--Body.set_head_hardness(.5); -- required to at least set the hardness in order for motions to work
leftArmMotion = math.pi/180*vector.new({60,30,-30});
--Body.set_larm_hardness({0.5,0.5,0.5});
--Body.set_larm_:command(leftArmMotion);
function inspect(key, value)
	table.foreach(value,print)
end
Lgoalie_corner = Config.world.Lgoalie_corner; -- we need the goalie stuff
--table.foreach(Body.get_sensor_data(),inspect)

--my stuff, ugly
--        gcm.set_game_state(3);
setBodyFSM = true;-- assume we start with GMU fsm
previousState = "nil";
fpsTimer = Body.get_time();
lastCommand = nil;
function updateAll(newState)
	--gcm.set_game_state(3);
       	--print("Motion update");
	Motion.update();
	--print("Body update");
       	Body.update();
	--print("body FSM update");
        BodyFSM.update();
	--print("HeadFSM update");
        HeadFSM.update();
--	GameFSM.update();	
	fpsTimer = Body.get_time(); 
end
count = 0;
function sendFeatures (client)
        if(wcm.get_horde_sendStatus()~="StartSending") then
        	--print("Start sending was false");
		 	return;
        end
        
       
        
	--	print(" difference is : " .. tostring(Body.get_time() - sendFeaturesTimer));
		if(Body.get_time() - sendFeaturesTimer < .5) then 
	--		print("is not sending")	
			return;
		end
		sendFeaturesTimer = Body.get_time();
		print("wcm send status was true");
		features = {}
        features["playerID"] = Config.game.playerID;
        if (wcm.get_horde_dummyTraining() == 0) then
		setDebugTrue();
		print("SENDING config role");
		setDebugFalse();
		features["role"] = Config.game.role;
        else
		setDebugTrue();
		print("sending dummy role");
		setDebugFalse();
		features["role"] = wcm.get_horde_role();
	end


	-- when I am disconnected from the team and I need to play kiddie soccer
        -- so send the features that say kiddie soccer
        features["connected"] = wcm.get_team_connected();
        features["goalieCloseEnough"] = wcm.get_horde_goalieCloseEnough();
	if(wcm.get_horde_dummyTraining()==1) then
		
		features["poseX"] = wcm.get_team_teamPoseX();
        	features["poseY"] = wcm.get_team_teamPoseY();
        	features["poseA"] = wcm.get_team_teamPoseA();
        	features["poseX"][Config.game.playerID] = wcm.get_horde_pose()[1]
		features["poseY"][Config.game.playerID] = wcm.get_horde_pose()[2]
		features["poseA"][Config.game.playerID] = wcm.get_horde_pose()[3]
	
	else
		features["poseX"] = wcm.get_team_teamPoseX();
        	features["poseY"] = wcm.get_team_teamPoseY();
        	features["poseA"] = wcm.get_team_teamPoseA();
		 
	end
	features["allYelledReady"] = wcm.get_team_yelledReady(); 
	features["allYelledKick"] = wcm.get_team_yelledKick();
	features["closestToBallLoc"] = wcm.get_team_closestToBallLoc();	
        features["ballDetect"] = vcm.get_ball_detect();
        features["ballX"] = wcm.get_ball_x();
        features["ballY"] = wcm.get_ball_y();
        features["doneApproach"] = wcm.get_horde_doneApproach();
        --[[features["particleX"] = wcm.get_particle_x();
        features["particleY"] = wcm.get_particle_y();
		features["particleA"] = wcm.get_particle_a();
	]]--print("gonna broadcast my features");
	features["yelledReady"] = wcm.get_horde_yelledReady();
	features["yelledKick"] = wcm.get_horde_yelledKick();
    	features["yelledFail"] = wcm.get_horde_yelledFail(); 
	features["isClosestToBall"] = wcm.get_team_is_smallest_eta();
	features["midpoint"] = wcm.get_horde_midpointBallGoal();
	features["isClosestToGoalDefend"] = wcm.get_team_isClosestToGoalDefend();
	features["isClosestToGoalOffend"] = wcm.get_team_isClosestToGoalOffend();
	features["penaltyBounds"] = getPenaltyBounds()
	features["declared"] = wcm.get_horde_declared()
	if (wcm.get_horde_dummyTraining() == 0) then
		getGoalSign();
	end
	features["goalSign"] = wcm.get_horde_goalSign(); -- not a feature but may become one... also it sets the value in the wcm
	features["status"] = wcm.get_horde_status();
	--print("sending some features, yo\n");-- wcm.set_horde_doneFrontApproach("true");
       -- print(json.encode(features) .. "\n");
		features["ackNumber"] = ackNumber;
		client:settimeout(.01);
		client:send(json.encode(features) .. "\n");
        -- Send the features to horde via the client
        -- args may contain the amount of time to wait between sending

end
--[[function setupUDPDarwins()
    --local myClient = 
   local host, port = "localhost", 4010
   -- load namespace
   local socket = require("socket")
   -- convert host name to ip address
   local ip = assert(socket.dns.toip(host))
   -- create a new UDP object
   local udp = assert(socket.udp())
   return udp
end]]--

function getGoalSign() 

	if gcm.get_team_color() == 1 then
                -- red attacks cyan goali
                print(" yellow ")
                postDefend = PoseFilter.postYellow;
        else
                print("not yellow")
                -- blue attack yellow goal
                postDefend = PoseFilter.postCyan;
        end

        -- global 
        LPost = postDefend[1];

        sign = LPost[1] / math.abs(LPost[1])
	wcm.set_horde_goalSign(sign);
	return sign
end


function getPenaltyBounds()
	if gcm.get_team_color() == 1 then
                -- red attacks cyan goali
                print(" yellow ")
                postDefend = PoseFilter.postYellow;
        else
                print("not yellow")
                -- blue attack yellow goal
                postDefend = PoseFilter.postCyan;
        end

        -- global 
        LPost = postDefend[1];

        sign = LPost[1] / math.abs(LPost[1])
        -- so get the x position of the front of the penalty box
        -- and add midpoint distance between that and the edge of the field
        -- then multiply by the sign.  note that the Lgoalie_corner should
        -- be positive but putting abs around just in case
        print(tostring(Lgoalie_corner[7][1]) .. " " .. tostring(Lgoalie_corner[9][1]))
        local xBound = (math.abs(Lgoalie_corner[7][1]) + (math.abs(Lgoalie_corner[9][1]) - math.abs(Lgoalie_corner[7][1])) / 2) * sign
	
	wcm.set_horde_penaltyBoundsX(xBound);
	wcm.set_horde_penaltyBoundsY(math.abs(LPost[2]));
	return {xBound, math.abs(LPost[2])}
end





lastState = 100;
function checkTimeout()
	--print("commparing values");
	if(wcm.get_horde_timeMark() ~= nil) then
	--	print(" " .. wcm.get_horde_timeMark()); 
	end
	if(Body.get_time() - wcm.get_horde_timeMark() > 5.0) then
	--	print("setting value");
		wcm.set_horde_passKick(0);
	end
	if((Body.get_time() - fpsTimer) > .1) then
                print("time since last frame: " .. (Body.get_time() - fpsTimer) .. updateAllTimer .. " " .. sendFeaturesTimer);
        end
end
function connectToHorde(port)
		local socket = require("socket")
                local server = assert(socket.bind("*", port))
                local client = server:accept()
              	return client;
end
lastReceivedState = nil;
connectionThread = function ()
        print("got into con thread");
	if( darwin ) then
                local tDelay = 0.005 * 1E6; -- Loop every 5ms


 -- setup the server
               client = connectToHorde(4009);--initialize connection, wait for it.....
               connected = true;
--               darwinComm = setupUDPDarwins();
                     
		print("connected")
  
        while connected do			
                        --print("update all")
			updateAllTimer = Body.get_time();
			updateAll();--move mah body, update FSM
			updateAllTimer = Body.get_time()-updateAllTimer;
                        --print("send features");
			--sendFeaturesTimer = Body.get_time();
			sendFeatures(client);--send all the features to horde
			--sendFeaturesTimer = Body.get_time() - sendFeaturesTimer;
                        --print("checkTimeout");
			--checkTimeout(); -- very special case for passKick timing out the feature to 0 after a second
			client:settimeout(0);--non blocking read
			
			--client:send("request\n");
	--		print("sending request");
			local line, err = client:receive() -- read in horde commands
			
			if(line~=nil) then
				
				--client:send("ack\n")
				
				print("---------------------------- ACK Number IS " .. ackNumber .. " ----------------------------------")
				local req = json.decode(line);	
				local err = req==nil;
				action = req.action
				action = string.sub(line, string.find(line, "action") or 0, #line);
				print("Received: " .. tostring(line))
				if(req.ackNumber ==  ackNumber) then
					ackNumber = ackNumber+1;
					print("Sending Features!!!");
					sendFeatures(client);--send all the features to horde
				else
					print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!GOT A BAD ACK NUMBER - " .. ackNumber .. " ~=  " .. req.ackNumber .. "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
					if(req.ackNumber<ackNumber) then
						print("maybe no big deal?");
					else
						return;
					end
				end
				
				
			end
			--setDebugTrue()
			print("am i in penalty?? " .. tostring(in_penalty()))
			setDebugFalse()
			if(not in_penalty() and wasJustInPenalty) then 
				hoard_functions.initPenalized = false;
				wasJustInPenalty = false;
				walk.start()
				walk.set_velocity(0,0,0);
			end
			--print("are we in penalty?")
			--print("vector of penalites: ", gcm.get_game_penalty())	
			--print("printing: ".. tostring(in_penalty()));
			--print("maybe? doing horde stuff, idk " .. wcm.get_horde_sendStatus() .. " " .. gcm.get_game_state() .. " " .. tostring(in_penalty()));
		        if(line ~=nil and string.find(line, "StartSending")) then
				updateAction(line, client)		
			elseif (gcm.get_game_state() ~= 3 or in_penalty()) then
				if(in_penalty()) then
					wasJustInPenalty = true;
				end
				if(line~=nil and not string.find(line, "update") and not err) then
					lastCommand = line
				end
				--print("not doing horde stuff, that's for sure " .. wcm.get_horde_sendStatus() .. " " .. gcm.get_game_state() .. " " .. tostring(in_penalty()));
				--print("not calling horde function");
				local state = gcm.get_game_state();
				
		        	if state ~= 3 then
  					if (state == 0 and lastState ~= 0) then
    						
						BodyFSM.sm:set_state('bodyIdle')-- 'initial';
  						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.sm:set_state('bodyStop');
						HeadFSM.sm:set_state('headIdle')
						
					elseif state == 1 and lastState ~= 1 then
						BodyFSM.sm:set_state('bodyReady') -- ready
						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.sm:set_state('bodyReadyMove') -- ready
						HeadFSM.sm:set_state('headLookGoalGMU')
					elseif (state == 2 and lastState ~=2 ) then
    						BodyFSM.sm:set_state('bodyStop') --'set';
  						HeadFSM.sm:set_state('headTrack');
				--	elseif (state == 3) then
    				--		return 'playing';
  					elseif (state == 4 and lastState ~=4) then
    						BodyFSM.sm:set_state('bodyIdle')	-- 'finished';
  						HeadFSM.sm:set_state('headIdle');
					end
					
					--GameFSM.update();
				end
				lastState = state;
				if in_penalty() then
					hoard_functions.hordeFunctions["position"](nil,nil); -- if we are not playing, do upenn positions
				end
			elseif not err then
				lastState = 3;
                --print(line);
		--lineAction = json.decode(line);
                if(line~=nil and (action~=lastReceivedState or string.find(action,"update"))) then -- uf we received somethin:g
					print("last Received was " .. tostring(lastReceivedState));
					updateAction(line, client);
					i = 0
					while i<100 do
						updateAll();		
						unix.usleep(.005 * 1E6);
						i=i+1;
					end	
					lastReceivedState = action;
				end
				print("update success\n");
                if err == "closed" then
                               connected = false;
                end
				if lastCommand ~= nil then
					updateAction(lastCommand,client);
					lastCommand = nil;
				end
			end    
            end
			 unix.usleep(tDelay);

        end
end
function in_penalty() 
	--print(Config.game.playerID);
	
	--print(vector.tostring(gcm.get_game_penalty()));
	--print("if i error here i'm a lemon");
	local k = gcm.get_game_penalty();
	--print(vector.tostring(k));
	--print("okay, now if i error im a giant lemon");
	--print((k[Config.game.playerID]>0));	
	--print((k[Config.game.playerID]>0));
	--print((k[Config.game.playerID]>0));	
	--print((k[Config.game.playerID]>0));	
	--print((k[Config.game.playerID]>0));	
	--print((k[Config.game.playerID]>0));	
	--print((k[Config.game.playerID]>0));	
	local p = k[Config.game.playerID]>0;
	--print("p is .. ".. tostring(p));
	return p;
end
function updateAction(servData, client)
  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  vcm.set_camera_teambroadcast(1); --Turn on wireless team broadcast
        print("printing servData");
	--print(servData);  
	--print("In update")
	req = json.decode(servData)
        --print("fuckshit\n")
	print("unholywords\n");
	unix.usleep(.04*1E6);
	print("Received action "..req.action);
	--BodyFSM = require('BodyFSM');
	hoard_functions.hordeFunctions[req.action](req.args, client)--this is wrong, only here for the send.... TODO
	--print("after horde function");
	--unix.usleep(1*1E6);	
--updateAll
	--wcm.set_horde_state(req.action);
--  hordeFunctions["walkForward"](nil,nil);  
end

function initMotion()--should be cleaned up, gets servos hard and standing up
	BodyFSM.entry();
	Motion.entry();
  	BodyFSM.update();
	BodyFSM.update();
	BodyFSM.sm:set_state('bodyReady');
	BodyFSM.update();
	BodyFSM.update();
	BodyFSM.sm:set_state('bodyUnpenalized');
	BodyFSM.update();
	BodyFSM.update();
	BodyFSM.sm:set_state('bodyIdle');
	BodyFSM.update();
	BodyFSM.update();

	--      GameFSM.entry();
	
		Motion.update();
		Motion.update();
		Motion.update();
	unix.usleep(.05*1E6);
	
		Motion.update();
		Motion.update();
		Motion.update();--BodyFSM.sm:set_state('bodyIdle')
	--GameFSM.sm:set_state('gameInitial')
		
	--BodyFSM.update();
	
--	BodyFSM.entry();	
end
--start "main"
if(darwin) then 
	--        hoard_functions.hordeFunctions["murder all humans"](nil,nil);
	--Motion.event("standup");	
    wcm.set_horde_yelledReady(0);
	wcm.set_horde_yelledKick(0);
	initMotion();
	print("starting connection thread\n");
	--coroutine.resume(connectionThread);
	connectionThread();
	print("connection lost")
--	wcm.set_horde_state("gotoBall");
end
--connection drew stuff, seriously i'm ruining this beautiful code

