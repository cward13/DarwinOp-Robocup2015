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
require('hfa')
require('kitty')
require('kittyOrPassHFA')
require('supportHFA')
require('offenseHFA')
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
tUpdate = unix.time();
connected = false;

function inspect(key, value)
	table.foreach(value,print)
end

sentBehavior = false;
function sendBehavior(sendInfo)
    client:send(sendInfo)
    wcm.set_horde_sentBehavior(1);
end


function connectToHorde(port)
		local socket = require("socket")
        local client = assert(socket.connect("127.0.0.1", port))
        --local client = server:accept()
        --client:settimeout(0);--non blocking read
		return client;
end

gotoPoseFacingStart = function(hfa) 
  			action  = {}
                        action["action"] = "gotoPoseFacing";
                        action["args"] = {};
			ballGlobal= {};
			ballGlobal.x = wcm.get_ballGlobal_x();
			ballGlobal.y = wcm.get_ballGlobal_y();
			print(ballGlobal)
 		    -- my pose global
       		pose=wcm.get_pose();

            -- determine which goal post the ball is closest to
       	    -- so need its global coords
       		--[[ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a})			
			ballGlobal.x = ballGlobal[1];
			ballGlobal.y = ballGlobal[2];
			--]]
			dest = getMidpoint()
			action.args.facing = {};
			action.args.facing.x = ballGlobal.x
			action.args.facing.y = ballGlobal.y
			action.args.facing.a = 0
			action.args.gotoPose = {};   
            action.args.gotoPose.x = dest.x
            action.args.gotoPose.y = dest.y
            action.args.gotoPose.a = 0
			action.ackNumber = wcm.get_horde_ackNumber();
            print("i am currently at: " .. pose.x .. ", " .. pose.y);
			print("trying to face " .. ballGlobal.x .. ", " .. ballGlobal.y);
			print("also moving to around " .. dest.x .. ", " .. dest.y);
			
			print(json.encode(action) .. "\n") 
           --if(vcm.get_ball_detect() == 1) then
                sendBehavior(json.encode(action) .. "\n");
           -- end
end	
gotoPoseFacingGo = function(hfa)
			action  = {}
            action["action"] = "updateGotoPoseFacing";
            action["args"] = {};
			--ball=wcm.get_ballGlobal();
 		    	
			ballGlobal= {};
            ballGlobal.x = wcm.get_ballGlobal_x();
            ballGlobal.y = wcm.get_ballGlobal_y();
            print(ballGlobal)

			-- my pose global
       		pose=wcm.get_pose();
            -- determine which goal post the ball is closest to
       	    -- so need its global coords
       		--[[ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a})			
			ballGlobal.x = ballGlobal[1];
			ballGlobal.y = ballGlobal[2];
			]]--
			dest = getMidpoint()
			action.args.facing = {};
			action.args.facing.x = ballGlobal.x
			action.args.facing.y = ballGlobal.y
			action.args.facing.a = 0
			action.args.gotoPose = {};   
            action.args.gotoPose.x = dest.x
            action.args.gotoPose.y = dest.y
            action.args.gotoPose.a = 0
			action.ackNumber = wcm.get_horde_ackNumber();
            print("i am currently at: " .. pose.x .. ", " .. pose.y);	
			print("trying to face " .. ballGlobal.x .. ", " .. ballGlobal.y);
			print("also moving to around " .. dest.x .. ", " .. dest.y);
			print(json.encode(action) .. "\n"); 
            
		    if(vcm.get_ball_detect() == 1) then		
				sendBehavior(json.encode(action) .. "\n");
			end
end
gotoPoseFacingStop = function (hfa)
end

stopStart = function(hfa)
	action  = {}
        action["action"] = "stop";
        action["args"] = "";
		action.ackNumber = wcm.get_horde_ackNumber();
        print(json.encode(action) .. "\n");
		sendBehavior(json.encode(action) .. "\n");
end
stopGo = function(hfa)
end
stopStop = function(hfa)
end

locateBallStart = function(hfa)
	print("locating ball") 
action  = {}
        action["action"] = "moveTheta";
        action["args"] = "";
		action.ackNumber =  wcm.get_horde_ackNumber();
		sendBehavior(json.encode(action) .. "\n");
end
locateBallStop = function()end
locateBallGo = function()end
gotoBallGo = function()end
gotoBallStart = function()
	print("going to ball")
 	action  = {}
        action["action"] = "gotoBall";
        action["args"] = "";
		action.ackNumber =  wcm.get_horde_ackNumber();
        sendBehavior(json.encode(action) .. "\n");
end
gotoBallStop = function()end

approachTargetStart = function()
	print("approach target")
	action  = {}
        action["action"] = "approachBall";
        action["args"] = "";
	action.ackNumber =  wcm.get_horde_ackNumber();
        sendBehavior(json.encode(action) .. "\n");
end
approachTargetStop = function()end
approachTargetGo = function()end
kickBallStart = function() 
	print("kicking ball");
 	action  = {}
        action["action"] = "kickBall";
        action["args"] = "";
		action.ackNumber = wcm.get_horde_ackNumber();
        sendBehavior(json.encode(action) .. "\n");
end
kickBallStop = function()end
kickBallgo = function()end


stopPoseStart = function()
	print("Stop")

	action = {}
	action["action"] = "stop";
	action["args"] = "";
	action.ackNumber =  wcm.get_horde_ackNumber();
	sendBehavior(json.encode(action) .. "\n");
end
gotoPositionStart = function(behavior, targets)
	action = {}
	action["action"] = "gotoPose"
	action["args"]  = targets["openSpot"]
	action.ackNumber = wcm.get_horde_ackNumber();
	sendBehavior(json.encode(action) .. "\n");
end
gotoPosition = makeBehavior("gotoPosition", nil,nil,gotoPositionStart)
stopPose = makeBehavior("stopPose", nil, nil, stopPoseStart);
walkForward = makeBehavior("walkForward", nil, walkForwardStop, walkForwardStart);
stopMoving = makeBehavior("stopMoving", nil, nil, stopPoseStart);
gotoPoseFacing = makeBehavior("gotoPoseFacing", nil, gotoPoseFacingStop, gotoPoseFacingStart);
gotoBall = makeBehavior("gotoBall", nil, gotoBallStop, gotoBallStart);
approachTarget = makeBehavior("approachTarget", nil, approachTargetStop, approachTargetStart);
kickBall = makeBehavior("kickBall", nil, kickBallStop, kickBallStart);
locateBall = makeBehavior("locateBall",nil,nil,locateBallStart);
kittyOrPassMachine = kittyOrPassHFA.myMachine2
supportMachine = supportHFA.myMachine
offenseMachine = offenseHFA.myMachine
--kittyMachine
print(tostring(kittyMachine) .. " ok in full game")
print("support and offense Machine " .. tostring(supportMachine) .. " " .. tostring(offenseMachine))
--super SUPER SUPER SUPER TODO IMPORTANT TODO NOW--- 
-- IF YOU EXPECT THIS MACHINE TO WORK WITH MORE THAN ONE PLAYER LIKE A REAL GAME CHANGE THE LOGIC FOR CLOSEST BALL, IT'S COMPLETELY BACKWARDS ( ON PURPOSE FOR TESTING--
myMachine = makeHFA("myMachine", makeTransition({
	[start] =function() print("im in my START " .. tostring(offenseMachine)) return  {[0] = offenseMachine, ["openSpot"] = "openSpot"} end,
    [offenseMachine] = function() print("in offense, considering support"); if(wcm.get_team_closestToBallLoc()[1]<-.1) then return supportMachine; end return {[0] = offenseMachine, ["openSpot"] = "openSpot"} end,
    [supportMachine] =function() print("in support, considering offense");if(wcm.get_team_closestToBallLoc()[1]>.1) then return {[0] = offenseMachine, ["openSpot"] = "openSpot"}; end return supportMachine end
}),false);
wcm.set_horde_ballLost(1)
lastTimeFound = Body.get_time();
function isBallLost()
	--print("got into ball lost")
	if vcm.get_ball_detect() ~= 0 then
		wcm.set_horde_ballLost(0);
		lastTimeFound = Body.get_time();
	elseif(Body.get_time() - lastTimeFound > 5) then
		wcm.set_horde_ballLost(1);
	end
	--print("got out of ball lost");
end


function closestToBall()
	return wcm.get_team_is_smallest_eta();
end





function getMidpoint()

	
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
	RPost = postDefend[2];
	--print(tostring(LPost))
    --print(tostring(RPost))
    -- relative
	--ball=wcm.get_ballGlobal();
	
	ballGlobal= {};
    ballGlobal.x = wcm.get_ballGlobal_x();
    ballGlobal.y = wcm.get_ballGlobal_y();
    print(ballGlobal)



	-- my pose global
  	pose=wcm.get_pose();
	
	-- determine which goal post the ball is closest to
	-- so need its global coords
	--[[ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a})
	ballGlobal.x = ballGlobal[1];
	ballGlobal.y = ballGlobal[2];
    ]]--
	LPost.x = LPost[1]
	LPost.y = LPost[2]
	RPost.x = RPost[1]
	RPost.y = RPost[2]
    farPost = {}
	if dist(ballGlobal, LPost) > dist(ballGlobal, RPost) then
		farPost.x = LPost[1]
		farPost.y = LPost[2]
		print("the far post is at coordinates: " .. tostring(farPost.x) .. ", " .. tostring(farPost.y))
		print("the near post is at coordinates: " .. tostring(RPost.x) .. ", " .. tostring(RPost.y))
	else
		farPost.x = RPost[1]
		farPost.y = RPost[2]
	
		print("the far post is at coordinates: " .. tostring(farPost.x) .. ", " .. tostring(farPost.y))
		print("the near post is at coordinates: " .. tostring(LPost.x) .. ", " .. tostring(LPost.y))
	end
	--print("going to the po	
	midpoint = {}
	midpoint.x = (ballGlobal.x + farPost.x) / 2
	midpoint.y = (ballGlobal.y + farPost.y) /2
	midpoint.a = 0
		
	return midpoint
end

function distToMidpoint()
	return dist(wcm.get_pose(), getMidpoint());
end
-- simple dist function
function dist(curA, targetB)
    --print("curA: " .. tostring(curA));
    --print("targetB:  " .. tostring(targetB));
	--print("curA.x: " .. curA.x);
	--print("targetB.x " .. targetB.x);
	return math.sqrt(math.pow(curA.x - targetB.x,2) + math.pow(curA.y - targetB.y,2))
end


connectionThread = function ()
        print("got into con thread");
	if( darwin ) then
        --local tDelay = 0.005 * 1E6; -- Loop every 5ms
--      setup the server
        client = connectToHorde(4009);--initialize connection, wait for it.....
        connected = true;
		
		startSending = {}
        startSending.action="StartSending";
        startSending.args = "";
		startSending.ackNumber = 0;
        print("to send " .. tostring(json.encode(startSending)) .. " \n ");
        client:send(json.encode(startSending) .. "\n");

	-- kitty needs a client
	--kitty.client = client
		kittyOrPassHFA.setClient(client)
		kitty.setClient(client)
        offenseHFA.setClient(client)
		supportHFA.setClient(client)
		wcm.set_horde_ackNumber(1);
		print("connected")
        goalSideMultiply = -1;
	if gcm.get_team_color() == 1 then

                -- red attacks cyan goali
                print(" yellow ")
        else
				goalSideMultiply = 1;
                print("not yellow")
        end
            -- global 
     	while connected do
			client:settimeout(.05);
			recval = client:receive()
			-- convert the json to get the ackNumber
			status, recJson = pcall(json.decode,recval);
			if status == true then
                status = string.sub(recval, 1, 1) == "{"
            end

			--print(tostring(recJson))
			if (status == true and recJson.ackNumber == wcm.get_horde_ackNumber()) then
				isBallLost();
			    --kitty.wcm.get_horde_ballLost() = wcm.get_horde_ballLost()	
				while wcm.get_horde_sentBehavior() == 0 do
					pulse(myMachine, {["openSpot"] = {["x"] = goalSideMultiply * 1.8, ["y"] = goalSideMultiply * 1, ["a"]= goalSideMultiply* -1.57}});
				end
				wcm.set_horde_sentBehavior(0);
				print("cur rec number " .. tostring(wcm.get_horde_ackNumber()) .. "..........................................")
				wcm.set_horde_ackNumber(wcm.get_horde_ackNumber()+1)
			end
		end
    end
end

--start "main"
if(darwin) then 
		--        hoard_functions.hordeFunctions["murder all humans"](nil,nil);
	--Motion.event("standup");	
      	print("starting connection thread\n");
	--coroutine.resume(connectionThread);
	connectionThread()
	print("connection lost")
--	wcm.set_horde_state("gotoBall");
end
--connection drew stuff, seriously i'm ruining this beautiful code

