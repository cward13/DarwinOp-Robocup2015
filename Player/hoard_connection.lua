module(... or '', package.seeall)
--setDebugFalse();
-- Get Platform for package path
doneReadyBefore = false;
cwd = '.';
local platform = os.getenv('PLATFORM') or '';
if (string.find(platform,'webots')) then cwd = cwd .. '/Player';
end
--setDebugFalse()
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
--setDebugFalse();
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
wcm.set_horde_timeOut(0);
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
	--if(false) then
	updateAllTimer2 = Body.get_time();
	--setDebugTrue();
--	print(HeadFSM.sm.get_current_state(HeadFSM.sm)._NAME .. " before motion")
	Motion.update();
	--HeadFSM.update();
	--if(false) then
	
--	print(HeadFSM.sm.get_current_state(HeadFSM.sm)._NAME .. " after motion, before body")
	
	--print("Body update");
	

       	Body.update();
	--HeadFSM.update();
--	print(HeadFSM.sm.get_current_state(HeadFSM.sm)._NAME .. " after  motion, before BodyFSM update")
	
	--end
	--print("body FSM update");
        BodyFSM.update();
	--HeadFSM.update();	
--	print(HeadFSM.sm.get_current_state(HeadFSM.sm)._NAME .. " after BodyFSM, before Headfsm")
	
	--print("HeadFSM update");
       -- end
	if(mcm.get_walk_isFallDown()==0) then
		--setDebugTrue();
		HeadFSM.update();
		--setDebugFalse();
	end
	--HeadFSM.update();
	--print(HeadFSM.sm.get_current_state(HeadFSM.sm)._NAME .. " after Headfsm update, before end of function")
--	GameFSM.update();
		
	fpsTimer = Body.get_time(); 
	updateAllTimer2 = Body.get_time() - updateAllTimer2;
	setDebugFalse();
end
count = 0;
sendFeaturesTimer2 = Body.get_time();
updateAllTimer2 = Body.get_time();
receiveClientTimer = Body.get_time();
--/sendFeatures
periodicSend = Body.get_time();
function sendFeatures (client)
        sendFeaturesTimer2 = Body.get_time();
	if(wcm.get_horde_sendStatus()~="StartSending") then
        	--print("Start sending was false");
		 	return;
        end
        
       
        
	--	print(" difference is : " .. tostring(Body.get_time() - sendFeaturesTimer));
		if(false or  Body.get_time() - sendFeaturesTimer < .025) then 
	--		print("is not sending")	
			return;
		end
		sendFeaturesTimer = Body.get_time();
		print("wcm send status was true");
		features = {}
        if(wcm.get_horde_dummyTraining() == 1) then
			features["playerID"] = wcm.get_horde_playerID();
		else
            features["playerID"] = Config.game.playerID;
        end
		if (wcm.get_horde_dummyTraining() == 0) then
		--setDebugTrue();
		--print("SENDING config role");
		--setDebugFalse();
		features["role"] = Config.game.role;
        else
			--setDebugTrue();
			print("sending dummy role");
			--setDebugFalse();
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
	features["timedOut"] = wcm.get_horde_timeOut();
	features["allYelledReady"] = wcm.get_team_yelledReady(); 
	features["allYelledKick"] = wcm.get_team_yelledKick();
	features["closestToBallLoc"] = wcm.get_team_closestToBallLoc();	
        features["ballDetect"] = vcm.get_ball_detect();
        features["ballX"] = wcm.get_ball_x();
        features["ballY"] = wcm.get_ball_y();
        features["doneApproach"] = wcm.get_horde_doneApproach();
        --features["particleX"] = wcm.get_particle_x();
        --features["particleY"] = wcm.get_particle_y();
	--features["particleA"] = wcm.get_particle_a();
	--print("gonna broadcast my features");
	features["yelledReady"] = wcm.get_horde_yelledReady();
	features["yelledKick"] = wcm.get_horde_yelledKick();
    	features["yelledFail"] = wcm.get_horde_yelledFail(); 
	features["isClosestToBall"] = wcm.get_team_is_smallest_eta();
	features["midpoint"] = wcm.get_horde_midpointBallGoal();
	features["isClosestToGoalDefend"] = wcm.get_team_isClosestToGoalDefend();
	features["isClosestToGoalOffend"] = wcm.get_team_isClosestToGoalOffend();
	features["penaltyBounds"] = getPenaltyBounds()
	features["declared"] = wcm.get_horde_declared()
	
	inPlay = 0;
	if(gcm.get_game_state()==3) then
		inPlay = 1;
		--features["inPlay"] = 1;
	end
	features["inPlay"] = inPlay;
	if (wcm.get_horde_dummyTraining() == 0) then
		getGoalSign();
	end
	features["goalSign"] = wcm.get_horde_goalSign(); -- not a feature but may become one... also it sets the value in the wcm
	
	features["status"] = wcm.get_horde_status();
	--print("sending some features, yo\n");-- wcm.set_horde_doneFrontApproach("true");
       -- print(json.encode(features) .. "\n");
		features["ackNumber"] = ackNumber;
		
setDebugTrue();
		print("yeah i'm sending");
		--Speak.talk("sending");
		client:settimeout(.01);
		if(Body.get_time() - periodicSend > .1) then 
			client:send(json.encode(features) .. "\n");
			periodicSend = Body.get_time();
		end
        -- Send the features to horde via the client
        -- args may contain the amount of time to wait between sending
	sendFeaturesTimer2 = Body.get_time() - sendFeaturesTimer2;
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
        -- so get the xposition of the front of the penalty box
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
		print("send features timer"  .. sendFeaturesTimer2);
        	print("client receive features timer " .. clientReceiveTimer);
		print("updateAll timer " .. updateAllTimer2);
	end
end
function connectToHorde(port)
		local socket = require("socket")
                local server = assert(socket.bind("*", port))
                local client = server:accept()
              	unix.usleep(.5 * 1E6);
		return client;
end
lastReceivedState = nil;
lastStateForTime = 0
lastTimeReceived = Body.get_time();
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
             local state = gcm.get_game_state();
    		 --setDebugTrue();
			if (state == 1 and lastStateForTime ~= 1) then 
				print(" state 1 ")
				timeReady = Body.get_time();
				if(Config.game.role ~= 0) then 
					lastState = 1;
			end
    			wcm.set_horde_timeOut(0);
			elseif(state ==1) then
				print( "state 1, but last state was also 1");
				if(Body.get_time()- timeReady > 30.0) then
				wcm.set_horde_timeOut(1);
				end
			else	
				print("reset to zero timer");
				wcm.set_horde_timeOut(0);
			end
			lastStateForTime = state;
			--setDebugFalse();

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
			local line, err = nil,nil
			clientReceiveTimer = Body.get_time();
			if( true or Body.get_time() - lastTimeReceived > .025) then	
				line,err = client:receive() -- read in horde commands
				lastTimeReceived = Body.get_time();
			end
			clientReceiveTimer = Body.get_time() - clientReceiveTimer;
			if(line~=nil) then
				
				--client:send("ack\n")
				
				print("---------------------------- ACK Number IS " .. ackNumber .. " ----------------------------------")
				--globalJsonDecoded = json.decode(line);
				local req = json.decode(line);	
				local err = req==nil;
				action = req.action
				action = string.sub(line, string.find(line, "action") or 0, #line);
				setDebugTrue();
				if(line~=nil) then
					print("Received: " .. tostring(line))
				end
				setDebugFalse();
				if(req.ackNumber ==  ackNumber) then
					ackNumber = ackNumber+1;
					print("Sending Features!!!");
					sendFeatures(client);--send all the features to horde
				else
					print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!GOT A BAD ACK NUMBER - " .. ackNumber .. " ~=  " .. req.ackNumber .. "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
				--	if(req.ackNumber<ackNumber) then
				--		print("maybe no big deal?");
				--	else
						return;
				--	end
				end
				
				
			end
			--setDebugTrue()
			print("am i in penalty?? " .. tostring(in_penalty()))
			print("hey am i close enough? " .. tostring(wcm.get_horde_goalieCloseEnough()));
			print("oh yeah, and is it on my side? " .. wcm.get_horde_goalieCertainBallOnMySide() .. " and ball " .. wcm.get_horde_ballLost());

			
			--setDebugFalse()
			if(not in_penalty() and wasJustInPenalty) then 
				hoard_functions.initPenalized = false;
				wasJustInPenalty = false;
				walk.start()
				walk.set_velocity(0,0,0);
			
		
				BodyFSM.sm:set_state('bodyReady') -- ready
				BodyFSM.update();
				BodyFSM.update();
				BodyFSM.update();
				BodyFSM.sm:set_state('bodyReadyMove') -- ready
				HeadFSM.sm:set_state('headLookGoalGMU')
			
			end
			--print("are we in penalty?")
			--print("vector of penalites: ", gcm.get_game_penalty())	
			--print("printing: ".. tostring(in_penalty()));
			--print("maybe? doing horde stuff, idk " .. wcm.get_horde_sendStatus() .. " " .. gcm.get_game_state() .. " " .. tostring(in_penalty()));
		        if(line ~=nil and string.find(line, "StartSending")) then
				updateAction(line, client)		
			elseif ((gcm.get_game_state() ~= 3 and not (Config.game.role~=0 and gcm.get_game_state() == 1)) or in_penalty()) then
			--elseif ((gcm.get_game_state() ~= 3 or in_penalty())) then
				
				
				
				print("JUST DOING UPENN STUFF")
				if(in_penalty()) then
					wasJustInPenalty = true;
				end
				setDebugTrue();
				if(string.find(tostring(line),"gotoPose")) then
					print("HEY THIS IS IMPORTANT");
				end
				if(line~=nil and not string.find(line, "update") and not err) then
					print("setting last command to " .. tostring(line));
					lastCommand = line
				end
				setDebugFalse();
				--print("not doing horde stuff, that's for sure " .. wcm.get_horde_sendStatus() .. " " .. gcm.get_game_state() .. " " .. tostring(in_penalty()));
				--print("not calling horde function");
				local state = gcm.get_game_state();
				
		        	if state ~= 3 or in_penalty() then
  					if (state == 0 and lastState ~= 0) then
    						doneReadyBefore = false;
						BodyFSM.sm:set_state('bodyIdle')-- 'initial';
  						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.sm:set_state('bodyStop');
						--HeadFSM.sm:set_state('headIdle')
					--upenn or us?	
					--elseif state == 1 and lastState ~= 1  and Config.game.role == 0 then -- only if you're goalie and in ready 
						elseif state == 1 and lastState ~= 1  then -- only if you're goalie and in ready 
	
						BodyFSM.sm:set_state('bodyReady') -- ready
						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.sm:set_state('bodyReadyMove') -- ready
						HeadFSM.sm:set_state('headLookGoalGMU')
					elseif (state == 2 and lastState ~=2 and not in_penalty() ) then
    						BodyFSM.sm:set_state('bodyStop') --'set';
  						HeadFSM.sm:set_state('headTrack');
				--	elseif (state == 3) then
    				--		return 'playing';
  					elseif ((state == 4 and lastState ~=4) or in_penalty()) then
    						BodyFSM.sm:set_state('bodyIdle')	-- 'finished';
  						--HeadFSM.sm:set_state('headIdle');
						 doneReadyBefore = false;
					end
					
					--GameFSM.update();
				end
				lastState = state;
				if in_penalty() then
					hoard_functions.hordeFunctions["position"](nil,nil); -- if we are not playing, do upenn positions
				end
			elseif not err and not in_penalty() then
				--local currentState = gcm.get_game_state();
				state = gcm.get_game_state();
				--upenn or us?
				if( not doneReadyBefore and state<3) then --and false) then
						doneReadyBefore = true;
						BodyFSM.sm:set_state('bodyReady') -- ready
						BodyFSM.update();
						BodyFSM.update();
						BodyFSM.update();
						--BodyFSM.sm:set_state('bodyReadyMove') -- ready
						HeadFSM.sm:set_state('headLookGoalGMU')
				
				 		i = Body.get_time();
						while(Body.get_time() - i < 7.2) do
							setDebugTrue()	
							print("this print statment gets on EVERYBODY's NERVES everybody's nerves EVERYBODY's NERVES");
							setDebugFalse();
								updateAll();
							end

						while i<100 do
							updateAll();		
							unix.usleep(.005 * 1E6);
							i=i+1;
						end
						unix.usleep(.005*1E6);	

				end
 				lastState = 3;
                --print(line);
		--lineAction = json.decode(line);
		if(action==lastReceivedState) then
			maintainState();
		end
                if(line~=nil and (action~=lastReceivedState or string.find(action,"update"))) then -- uf we received somethin:
		
					if lastCommand ~= nil then
						
						setDebugTrue();
						print("last ccommand sent (about to exewcute)" .. tostring(lastCommand));
						setDebugFalse();

						updateAction(lastCommand,client);
						if(string.find(lastCommand,"kick")) then
							while i<100 do
								updateAll();		
								unix.usleep(.005 * 1E6);
								i=i+1;
							end	
						end
						lastCommand = nil;
						i=0;
						if(gcm.get_game_state() == 1) then
							i = Body.get_time();
							while(Body.get_time() - i < 7.2) do
							setDebugTrue()	
							print("this print statment gets on EVERYBODY's NERVES everybody's nerves EVERYBODY's NERVES");
							setDebugFalse();
								updateAll();
							end
						end
					else

						setDebugTrue();
						print("last Received was " .. tostring(lastReceivedState));
						setDebugFalse();
						updateAction(line, client);
						i = 0
						if string.find(line,"kick") then
							while i<100 do
								updateAll();		
								unix.usleep(.005 * 1E6);
								i=i+1;
							end
						end	
						lastReceivedState = action;
					end
				end
				print("update success\n");
                if err == "closed" then
                               connected = false;
                end
			end    
            end
			 unix.usleep(tDelay);
			checkTimeout();
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
	return p or (wcm.get_horde_visionPenalty()==1);
end
function maintainState()
	hoard_functions.maintainState();
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
	setDebugTrue()
	print("MOST IMPORTANT: Received action "..req.action);
	
	--BodyFSM = require('BodyFSM');
	print("before action is... " .. tostring(BodyFSM.sm.get_current_state(BodyFSM.sm)._NAME))
	
--	if(req~=nil and hoard_functions~=nil) then
		
		hoard_functions.hordeFunctions[req.action](req.args, client)--this is wrong, only here for the send.... TODO
--	end
--	print("after action is... " .. tostring(BodyFSM.sm.get_current_state(BodyFSM.sm)._NAME))
	setDebugTrue();
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

