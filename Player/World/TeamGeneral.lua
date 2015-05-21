module(..., package.seeall);

require('Config');
require('Body');
require('Comm');
require('Speak');
require('vector');
require('util')
require('serialization');

require('wcm');
require('gcm');

Comm.init(Config.dev.ip_wireless,Config.dev.ip_wireless_port);
print('Receiving Team Message From',Config.dev.ip_wireless);
playerID = gcm.get_team_player_id();
lastTimeKicked = Body.get_time();
msgTimeout = Config.team.msgTimeout;
nonAttackerPenalty = Config.team.nonAttackerPenalty;
nonDefenderPenalty = Config.team.nonDefenderPenalty;
fallDownPenalty = Config.team.fallDownPenalty;
ballLostPenalty = Config.team.ballLostPenalty;

walkSpeed = Config.team.walkSpeed;
turnSpeed = Config.team.turnSpeed;

GOALIE_DEAD_THRESHOLD = 3
STATUS_DEAD_THRESHOLD = 3
CONNECTED_TIMEOUT = 3

setDebugFalse();

-- setting the distance as defined to be "close" for the goalie to the ball to be 1m
wcm.set_horde_goalCloseDist(1.25)
-- setting the distance that the other players need to be in order to set status to 1 or 3
wcm.set_horde_distN(1)


flip_correction = Config.team.flip_correction or 0;

confused_threshold_x= Config.team.confused_threshold_x or 3.0;
confused_threshold_y= Config.team.confused_threshold_y or 3.0;
flip_threshold_x= Config.team.flip_threshold_x or 1.0;
flip_threshold_y= Config.team.flip_threshold_y or 1.5;
flip_threshold_t= Config.team.flip_threshold_t or 0.5;
flip_check_t = Config.team_flip_check_t or 3.0;

confusion_handling = Config.confusion_handling or 0;

lastTimeDeclaredReceived = {Body.get_time(), Body.get_time(), Body.get_time()}
lastTimeReceivedFromGoalie = Body.get_time();

goalie_ball={0,0,0};

--Player ID: 1 to 5
--to prevent confusion, now we use these definitions
ROLE_GOALIE = 0;
ROLE_ATTACKER = 1;
ROLE_DEFENDER = 2;
ROLE_SUPPORTER = 3;
ROLE_DEFENDER2 = 4;
ROLE_CONFUSED = 5;
ROLE_RESERVE_PLAYER = 6;
ROLE_RESERVE_GOALIE = 7;

GOALIE_ID = 4;

countPackets = 0;

state = {};
state.robotName = Config.game.robotName;
state.teamNumber = gcm.get_team_number();
state.id = playerID;
state.teamColor = gcm.get_team_color();
state.time = Body.get_time();
state.role = -1;
state.pose = {x=0, y=0, a=0};
state.ball = {t=0, x=1, y=0, vx=0, vy=0, p = 0};
state.attackBearing = 0.0;--Why do we need this?
state.penalty = 0;
state.tReceive = Body.get_time();
state.battery_level = wcm.get_robot_battery_level();
state.fall=0;

role = Config.game.role
--Added key vision infos
state.goal=0;  --0 for non-detect, 1 for unknown, 2/3 for L/R, 4 for both
state.goalv1={0,0};
state.goalv2={0,0};
state.goalB1={0,0,0,0,0};--Centroid X Centroid Y Orientation Axis1 Axis2
state.goalB2={0,0,0,0,0};
state.landmark=0; --0 for non-detect, 1 for yellow, 2 for cyan
state.landmarkv={0,0};
state.corner=0; --0 for non-detect, 1 for L, 2 for T
state.cornerv={0,0};
state.ballLost = 0

--Game state info
state.gc_latency=0;
state.tm_latency=0;

--Body state 
state.bodyState = gcm.get_fsm_body_state();

--- SET THIS AT THE BEGINING OF THE MATCH TO SAY WHICH SIDE OF THE FIELD YOU will be placed for a penalty

	-- need something for everyone we just don't want to have to change it on every robot just change on the Goalie
	wcm.set_teamdata_penaltyLocation(-1.5);
if playerID == GOALIE_ID then -- GOALIE
	state.penaltyLocation = wcm.get_teamdata_penaltyLocation();
end


states = {};
states[playerID] = state;

--We maintain pose of all robots 
--For obstacle avoidance
poses={};
player_roles=vector.zeros(10);
t_poses=vector.zeros(10);
tLastMessage = 0;
tLastReceivedMessage = 0;


lastTimeFound = Body.get_time();
function isBallLost()
	--print("got into ball lost, get ball detect:  ".. vcm.get_ball_detect())
	if vcm.get_ball_detect() ~= 0 then
		state.ballLost = 0
		lastTimeFound = Body.get_time();
	elseif(Body.get_time() - lastTimeFound > 5) then
		state.ballLost = 1
	end
	--print("got out of ball lost");
end

function recv_msgs()
  print("@!@!trying to receive messages");
  
  while (Comm.size() > 0) do 
    print("@!@!about to get the message.....");
    msg=Comm.receive();
    --Ball GPS Info hadling
    if msg and #msg==14 then --Ball position message
      ball_gpsx=(tonumber(string.sub(msg,2,6))-5)*2;
      ball_gpsy=(tonumber(string.sub(msg,8,12))-5)*2;
      wcm.set_robot_gps_ball({ball_gpsx,ball_gpsy,0});
    else --Regular team message
      t = serialization.deserialize(msg);
      --    t = unpack_msg(msg);
      if t and (t.teamNumber) and (t.id) then
        tLastMessage = Body.get_time();
        --Messages from upenn code
        --Keep all pose data for collison avoidance 
        if t.teamNumber ~= state.teamNumber then
          poses[t.id+5]=t.pose;
          player_roles[t.id+5]=t.role;
          t_poses[t.id+5]=Body.get_time();
        elseif t.id ~=playerID then
          poses[t.id]=t.pose;
          player_roles[t.id]=t.role;
          t_poses[t.id]=Body.get_time();
        end
        --Is the message from our team?
        if (t.teamNumber == state.teamNumber) and (t.id ~= playerID) then
          t.tReceive = Body.get_time();
          tLastReceivedMessage = t.tReceive;
          print("@!@!deciding if message is from my team")
          t.labelB = {}; --Kill labelB information
          states[t.id] = t;
        end
      end
    end
  end
end

function update_obstacle()
  --Update local obstacle information based on other robots' localization info
  local t = Body.get_time();
  local t_timeout = 2.0;
  local closest_pose={};
  local closest_dist =100;
  local closest_index = 0;
  local closest_role = 0;
  pose = wcm.get_pose();
  avoid_other_team = Config.avoid_other_team or 0;
  if avoid_other_team>0 then num_teammates = 10;end
  obstacle_count = 0;
  obstacle_x=vector.zeros(10);
  obstacle_y=vector.zeros(10);
  obstacle_dist=vector.zeros(10);
  obstacle_role=vector.zeros(10);
  for i=1,10 do
    if t_poses[i]~=0 and 
      t-t_poses[i]<t_timeout and
      player_roles[i]<ROLE_RESERVE_PLAYER then
      obstacle_count = obstacle_count+1;
      local obstacle_local = util.pose_relative({poses[i].x,poses[i].y,0},{pose.x,pose.y,pose.a}); 
      dist = math.sqrt(obstacle_local[1]^2+obstacle_local[2]^2);
      obstacle_x[obstacle_count]=obstacle_local[1];
      obstacle_y[obstacle_count]=obstacle_local[2];
      obstacle_dist[obstacle_count]=dist;
      if i<6 then --Same team
        obstacle_role[obstacle_count] = player_roles[i]; --0,1,2,3,4
      else --Opponent team
        obstacle_role[obstacle_count] = player_roles[i]+5; --5,6,7,8,9
      end
    end
  end
  wcm.set_obstacle_num(obstacle_count);
  wcm.set_obstacle_x(obstacle_x);
  wcm.set_obstacle_y(obstacle_y);
  wcm.set_obstacle_dist(obstacle_dist);
  wcm.set_obstacle_role(obstacle_role);
  --print("Closest index dist", closest_index, closest_dist);
end

function entry()
end


function update()
  --print("====PLAYERID:",playerID);
  countPackets = countPackets + 1;
  state.time = Body.get_time();
  state.teamNumber = gcm.get_team_number();
  state.teamColor = gcm.get_team_color();
  state.pose = wcm.get_pose();
  state.ball = wcm.get_ball();
  state.role = role;
  state.attackBearing = wcm.get_attack_bearing();
  state.battery_level = wcm.get_robot_battery_level();
  state.fall=wcm.get_robot_is_fall_down();
  state.bodyState = gcm.get_fsm_body_state();
  state.yelledReady = wcm.get_horde_yelledReady();
  state.yelledKick = wcm.get_horde_yelledKick();
  state.status = wcm.get_horde_status();
  state.declared = wcm.get_horde_doDeclare();
  state.goalieCloseEnough = wcm.get_horde_goalieCloseEnough();
  state.ballRelative = util.pose_relative({wcm.get_ballGlobal_x(), wcm.get_ballGlobal_y(), 0}, {state.pose.x, state.pose.y, state.pose.a});
  state.ballGlobal = {wcm.get_ballGlobal_x(), wcm.get_ballGlobal_y()};
  state.ballRelative[3] = 0;
  state.ballDetect = vcm.get_ball_detect();
  state.count = countPackets
  
  -- if i am the goalie then set whether we think the ball is on my side.
  if playerID == GOALIE_ID then
  	state.goalieCertainBallOnMySide = wcm.get_horde_goalieCertainBallOnMySide();
  end
  
   
  --print("yelledReady = " .. tostring(state.yelledReady))
	isBallLost();

  if gcm.get_team_color() == 1 then

            -- red attacks cyan goali
        print("  yellow ")
            postDefend = PoseFilter.postYellow;
			postAttack = PoseFilter.postCyan;
    else
       -- print("not yellow")
            -- blue attack yellow goal
            postDefend = PoseFilter.postCyan;
			postAttack = PoseFilter.postYellow;
    end

    -- global 
    DLPost = postDefend[1];
    DRPost = postDefend[2];
	avgDGoal = {(DLPost[1] + DRPost[1]) / 2, (DLPost[2] + DRPost[2]) / 2, 0}

	ALPost = postAttack[1];
    ARPost = postAttack[2];
    avgAGoal = {(ALPost[1] + ARPost[1]) / 2, (ALPost[2] + ARPost[2]) / 2, 0}

	-- now calculate the distance the robot is from each of the goals

	state.distToGoalDefend = math.sqrt((avgDGoal[1] - state.pose.x) * (avgDGoal[1] - state.pose.x) + (avgDGoal[2] - state.pose.y)*(avgDGoal[2] - state.pose.y));
	state.distToGoalOffend = math.sqrt((avgAGoal[1] - state.pose.x) * (avgAGoal[1] - state.pose.x) + (avgAGoal[2] - state.pose.y)*(avgAGoal[2] - state.pose.y));

	if state.role == ROLE_GOALIE then
		--setDebugTrue();	
		-- calculate the distance and set the shared memory and the state
		goalieDist = get_distanceBetween(state.ballRelative, {0, 0});
		--print("DNW goalie dist = " .. tostring(goalieDist) .. " closeDist = " .. tostring(wcm.get_horde_goalCloseDist()) .. " ball lost = " .. tostring(state.ballLost));
		-- as long as the ball is close enough and i can see it then I am close enough
		goalieDistFromPosts = math.abs(wcm.get_ballGlobal_x()- (World.xMax*wcm.get_horde_goalSign()))
		teamGoalieDistFromPosts = math.abs(wcm.get_team_closestToBallLoc()[1] - World.xMax*wcm.get_horde_goalSign())
		if   goalieDistFromPosts<wcm.get_horde_goalCloseDist() then --or (state.ballLost == 1 and teamGoalieDistFromPosts < wcm.get_horde_goalCloseDist()) then
			state.goalieCloseEnough = 1;
			wcm.set_horde_goalieCloseEnough(1);
			--print("DNW Goalie is close enough state version = " .. tostring(state.goalieCloseEnough) .. " wcm version =" .. tostring(wcm.get_horde_goalCloseDist()));
		elseif(goalieDistFromPosts >  wcm.get_horde_goalCloseDist()*1.25) then
			state.goalieCloseEnough = 0;
			wcm.set_horde_goalieCloseEnough(0);
			--print("DNW Goalie is NOT close enough state version = " .. tostring(state.goalieCloseEnough) .. " wcm version =" .. tostring(wcm.get_horde_goalCloseDist()));
		end
		--setDebugTrue();
	end




  if gcm.in_penalty() then  state.penalty = 1;
  else  state.penalty = 0;
  end

  --Set gamecontroller latency info
  state.gc_latency=gcm.get_game_gc_latency();
  state.tm_latency=Body.get_time()-tLastMessage;
  
  teamLatency = Body.get_time() - tLastReceivedMessage;
  
  -- If I haven't received things from anyone in the last 3 seconds then I'm not connected
  if wcm.get_horde_dummyTraining() == 0 then
   if teamLatency > CONNECTED_TIMEOUT then
  	wcm.set_team_connected(0);
  else
  	wcm.set_team_connected(0);
  end
 end

  pack_vision_info(); --Vision info

  vision_send_interval = Config.team.vision_send_interval or 10;
--[[
  if count%vision_send_interval==0 then
    pack_labelB(); --labelB info
  end
  --]]

  --Now pack state name too
  state.body_state = gcm.get_fsm_body_state();
	--[[setDebugTrue();
	print("YOLO count = " .. countPackets .. " mod 10 = " .. math.mod(countPackets, 10))
	setDebugFalse();
	]]--
	if (math.mod(countPackets, 1) == 0 and gcm.in_penalty() == false) then --TODO: How often can we send team message?
		msg=serialization.serialize(state);
	
		sendStatus = Comm.send(msg, #msg);
		state.tReceive = Body.get_time();
		states[playerID] = state;
		setDebugFalse();
		
  end

  -- receive new messages every frame
  recv_msgs();

  -- eta and defend distance calculation:
  eta = {};
  ddefend = {};
  roles = {};
  t = Body.get_time();
  smallest = math.huge;
  smallest_id = 0;

  shortestDefendGoalDist = math.huge;
  shortestAttackGoalDist = math.huge;
  shortestDefendID = 0;
  shortestAttackID = 0

	--setDebugTrue()

	local numZero = 0
	local numOne = 0
	somebodyDeclared = {};
	-- assume they're all true first?
	--somebodyDeclared = wcm.get_horde_declared();
	somebodyDeclared[1] = 0;
	somebodyDeclared[2] = 0;
	somebodyDeclared[3] = 0;
	--print("Going to check declared ++++++++++++++++++++++++");
	
	
	local goalieBallGlobalX = -1
	for id = 1,5 do
		if states ~= nil and states[id] ~= nil and states[id].role == 0 then
			goalieBallGlobalX = states[id].ballGlobal[1];
		end
	end
	
	
	
	for myRole = 1,3 do 
        	for id = 1,5 do
			--check if nil, if this is not declared, and make sure this isn't the goalie
			if states[id] == nil or states[id].declared[myRole] == 0 or states[id].role == 0 or (states[id] and states[id].tReceive and
      (t - states[id].tReceive > STATUS_DEAD_THRESHOLD))then --  I haven't received a packet in a while 
				if states[id] == nil then
					--print("id " .. tostring(id) .. " no msg received")
				elseif states[id].role == 0 then
					--print("id " .. tostring(id) .. " is the goalie" )
				else
					--print("The robot is dead")
				end
				--somebodyDeclared[myRole] = 0;
			-- ^^ ignore him...^^
			else-- don't ignore him, he dclared, so note that somebody declared that role
							
				lastTimeDeclaredReceived[myRole] = Body.get_time();
				if states[id].declared[myRole] == 1 then
					
					--setDebugTrue();		
					print("ID " .. tostring(id) .. " declared the role " .. tostring(myRole));
					somebodyDeclared[myRole] = id;
					setDebugFalse();
					
					
					if myRole == 3 and playerID ~= id and  -- if the role is safety and its not me
					state.ballDetect == 1 and states[id].ballDetect == 1 and -- we can see the ball
						gcm.in_penalty() == false and gcm.get_game_state() == 3 and 
						state.role ~= 0 then -- and we can actually do something
					
						-- check if based off of the safety's global ball position I should flip
						if  states[id].ballGlobal[1] * state.ballGlobal[1] <= 0 and math.abs(states[id].ballGlobal[1] - state.ballGlobal[1]) > 0.75 and
						 	states[id].ballGlobal[1] * goalieBallGlobalX >= 0  and math.abs(goalieBallGlobalX) > .75 and math.abs(states[id].ballGlobal[1]) > .75 and not goalieDead then -- now check the goalie if the goalie thinks the ball is not on the same side as the safety then can't flip
							-- we disagree about the side of the field
							-- so set 
							state.safetyBasedFlip = 1
							wcm.set_horde_safetySaysFlip(1)
						else
							wcm.set_horde_safetySaysFlip(0)
						end
					end
					
					
				--wcm.set_horde_declared(1); -- somebody has declared
					break;-- break out of inner loop, run again for next role
				else
					somebodyDeclared[myRole] = 0;
					--setDebugTrue();	
					print("ID " .. tostring(id) .. " NOT  declared the role " .. tostring(myRole));
					
					print("id " .. tostring(id) .. "not declared" )
					setDebugFalse();
				end			
			end
		end
	end
	

	wcm.set_horde_declared(somebodyDeclared);
	if (wcm.get_horde_dummyTraining() == 0) then
		-- if i am safety and LTDR[2] > 5 declareSupport
		if somebodyDeclared[3] == state.id and t - lastTimeDeclaredReceived[2] > STATUS_DEAD_THRESHOLD then
			-- make sure 
			somebodyDeclared[3] = 0; -- undeclare my previous declare
			somebodyDeclared[2] = 0; -- and undeclare support so that I can take it if I am not closest
			wcm.set_horde_declared(somebodyDeclared);
	
			-- make sure he has set that he is doing it
			state.declared[3] = 0
			state.declared[2] = 0
			wcm.set_horde_doDeclare(state.declared)
		end
		-- if I am support and LTSD[1] > 5 declareKiddie
		if somebodyDeclared[2] == state.id and t - lastTimeDeclaredReceived[1] > STATUS_DEAD_THRESHOLD then
			-- make sure 
			somebodyDeclared[2] = 0; -- undeclare my previous declare
			somebodyDeclared[1] = 0; -- and undeclare kiddie so that I can take it if I am closest
			wcm.set_horde_declared(somebodyDeclared);
	
			-- make sure he has set that he is doing it
			state.declared[2] = 0
			state.declared[1] = 0
			wcm.set_horde_doDeclare(state.declared)
		end
	end

	goalieDead = false;	
	-- zero is the default so originally everyon will be zero so 
	print("Done checking declared -------------------------");
 	setDebugFalse();
 	if (wcm.get_horde_dummyTraining() == 0) then
		-- need to set the penalty location
		if playerID ~= GOALIE_ID then -- if I'm not the goalie then I need to update the penalty {x,y} location
			for index=1,5 do -- so find the goalie and set my penaltyLocation. -- might not need to loop.
				if states[index] ~= nil and states[index].id == GOALIE_ID and (states[index] and states[index].tReceive and
		  (Body.get_time() - states[index].tReceive < GOALIE_DEAD_THRESHOLD)) then
					wcm.set_teamdata_penaltyLocation(states[index].penaltyLocation); -- only the goalie has the penalty loc data.
					wcm.set_horde_goalieCertainBallOnMySide(states[index].goalieCertainBallOnMySide);
					wcm.set_horde_goalieCloseEnough(states[index].goalieCloseEnough);
					lastTimeReceivedFromGoalie = Body.get_time();
					
					break;
				end

			end
		
			if Body.get_time() - lastTimeReceivedFromGoalie > GOALIE_DEAD_THRESHOLD then
				wcm.set_horde_goalieCertainBallOnMySide(0); -- make sure this is reset so that I don't end up flipping continuously.	
				goalieDead = true;
			end
		
		end
	end


  for id = 1,5 do 
    if not states[id] or not states[id].ball.x then  -- no info from player, ignore him
      eta[id] = math.huge;
      ddefend[id] = math.huge;
      roles[id]=ROLE_RESERVE_PLAYER; 
    else    -- Estimated Time of Arrival to ball (in sec)
--[[
--Old ETA calculation:
      eta[id] = rBall/0.10 +  4*math.max(tBall-1.0,0)+
      math.abs(states[id].attackBearing)/3.0; --1 sec to turn 180 deg
--]]

      --New ETA calculation considering turning, ball uncertainty
      --walkSpeed: seconds needed to walk 1m
      --turnSpeed: seconds needed to turn 360 degrees
      --TODO: Consider sidekick

      rBall = math.sqrt(states[id].ballRelative[1]^2 + states[id].ballRelative[2]^2);
      tBall = states[id].time - states[id].ball.t;
      eta[id] = rBall/walkSpeed + --Walking time
        --math.abs(states[id].attackBearing)/(2*math.pi)*turnSpeed+ --Turning 
        ballLostPenalty * math.max(tBall-1.0,0);  --Ball uncertainty

      roles[id]=states[id].role;
      dgoalPosition = vector.new(wcm.get_goal_defend());-- distance to our goal

      ddefend[id] = 	math.sqrt((states[id].pose.x - dgoalPosition[1])^2 +
		 (states[id].pose.y - dgoalPosition[2])^2);

  --[[    if (states[id].role ~= ROLE_ATTACKER ) then       -- Non attacker penalty:
        eta[id] = eta[id] + nonAttackerPenalty/walkSpeed;
      end

      -- Non defender penalty:
      if (states[id].role ~= ROLE_DEFENDER and states[id].role~=ROLE_DEFENDER2) then 
        ddefend[id] = ddefend[id] + 0.3;
      end

      if (states[id].fall==1) then  --Fallen robot penalty
        eta[id] = eta[id] + fallDownPenalty;
      end--]]

		if states[id].distToGoalOffend < shortestAttackGoalDist then
			shortestAttackGoalDist = states[id].distToGoalOffend
			shortestAttackID = id
		end

		if states[id].distToGoalDefend < shortestDefendGoalDist then
			shortestDefendGoalDist = states[id].distToGoalDefend;
			shortestDefendID = id;
		end


      --Store this
      if id==playerID then
        wcm.set_team_my_eta(eta[id]);
      end
      print("ETA for id " .. id .. " is " .. eta[id]);
      if eta[id] < smallest then
	smallest_id = id
	smallest = eta[id];
      end


      --Ignore goalie, reserver, penalized player, confused player
      --[[if (states[id].penalty > 0) or 
        (t - states[id].tReceive > msgTimeout) or
        (states[id].role >=ROLE_CONFUSED) or 
        (states[id].role ==0) then
        eta[id] = math.huge;
        ddefend[id] = math.huge;
      end]]--

    end
  end


	if shortestAttackID == state.id then
		wcm.set_team_isClosestToGoalOffend(1);
	else
		wcm.set_team_isClosestToGoalOffend(0);
	end

 if wcm.get_horde_dummyTraining() == 0 then
	if shortestDefendID == state.id then
        wcm.set_team_isClosestToGoalDefend(1);
    else
        wcm.set_team_isClosestToGoalDefend(0);
    end
  end
  -- set the ball pose of the bot that is closest
  -- convert the relative ball loc to global loc
  if smallest_id ~= 0 then
    
    if (wcm.get_horde_dummyTraining() == 0) then
	--	print("DNW ballRelative a = " .. states[smallest_id].ballRelative[3] .. " x = " .. states[smallest_id].ballRelative[1] .. " y = " .. states[smallest_id].ballRelative[2]);
		closestToBallLoc = util.pose_global(states[smallest_id].ballRelative, {states[smallest_id].pose.x, states[smallest_id].pose.y, states[smallest_id].pose.a})
    	wcm.set_team_closestToBallLoc(closestToBallLoc)
	end

   -- get the midpoint
  themid = getMidpoint();
  wcm.set_horde_midpointBallGoal({themid.x, themid.y});
end

if wcm.get_horde_dummyTraining() == 0 then
  if smallest_id == playerID then
	wcm.set_team_is_smallest_eta(1);
  else
        wcm.set_team_is_smallest_eta(0);
  end
end
  
  update_shm() 
  if (wcm.get_horde_dummyTraining() == 0) then
  	update_status();
  end
  
  update_teamdata();
  update_goalieCloseEnough();
  update_obstacle();
  check_confused();
  check_flip2();
end
-- 0 = i am closest or we are without comm then we are all closest
-- 1 = i am second closest and within N
-- 2 = i am second closest
-- 3 = i am third closest and within N
-- 4 = i am third closest
lastTimeStatusRec = {Body.get_time(), Body.get_time(), Body.get_time(), Body.get_time(), Body.get_time()}
lastStatus = {} -- init it
function update_status()

	
	local ballDist = state.ballRelative; -- the position of the ball relative to me based off the global pos
	local myDist = get_distanceBetween(ballDist, {0, 0});
	local distIDPairs = {}
	
	if(wcm.get_horde_yelledKick() == 1) then
		lastTimeKicked = Body.get_time();
	end
	
	--setDebugTrue();
	for id = 1,5 do	
	
		
	
		--local condition1 =  states[id]~=nil and states[id].role ~= ROLE_GOALIE and states[id].pose and states[id].ballRelative 

 
		--local condition2 = (states[id]~=nil or lastStatus == nil or states[id].id == nil or states[id].count == nil or lastStatus[states[id].id] == nil) 
		
			
		if(states[id]~=nil and states[id].role ~= ROLE_GOALIE and states[id].pose and states[id].ballRelative and 
			(states[id] and states[id].tReceive and (Body.get_time() - states[id].tReceive < STATUS_DEAD_THRESHOLD))) then -- stil allive
			
			
			lastTimeStatusRec[states[id].id] = Body.get_time();
			--print("DNW index = " .. tostring(id) .. " I am role = " .. tostring(states[id].role) .. " and the ballLost feature is = " .. tostring(states[id].ballLost));
			local data = {}
			data.id = states[id].id
			
			if states[id].ballLost == 0 then
				if(Body.get_time() - lastTimeKicked < 2) then 
					data.dist = wcm.get_horde_distN() + 0.27;
				else
					data.dist = get_distanceBetween(states[id].ballRelative, {0, 0});
				end
				--print("DNW index = " .. tostring(id) .. " SEE BALL so dist is " .. data.dist);
			else
				data.dist = math.huge;
				--print("DNW index = " .. tostring(id) .. " BALL LOST so dist is " .. data.dist);
			end
			--print("DNW HEY I ADDED A DIST PAIR AT " .. id );
			data.status = states[id].status
			
			
			data.dead = 0
			
			lastStatus[data.id] = data
			distIDPairs[id] = data;
			
			
			
		else
			local placeHolderData = {}
			placeHolderData.dist = math.huge;
			placeHolderData.id = id
			placeHolderData.dead = 1 -- ? going to check down later to be sure
			
			distIDPairs[id] = placeHolderData;
			if Body.get_time() - lastTimeStatusRec[distIDPairs[id].id] < STATUS_DEAD_THRESHOLD and lastStatus[distIDPairs[id].id] ~= nil then
				--setDebugTrue();
				print("id " .. distIDPairs[id].id .. "dead = " .. tostring(distIDPairs[id].dead));
				print("last status at id " .. tostring((not lastStatus[distIDPairs[id].id])))
				distIDPairs[id] = lastStatus[distIDPairs[id].id]
				print(" the table itself is " .. tostring(distIDPairs[id]))
				print("id now based off of lastStatus = " .. tostring(distIDPairs[id].id))
				print( " and dead is = " .. tostring(distIDPairs[id].dead))
				distIDPairs[id].dead = 0 -- then I will wait and keep you in
			--	setDebugFalse();
			end
			
			
		end	
		
		--setDebugTrue();
		print("id = " .. tostring(id) .. " distID = " .. tostring(distIDPairs[id].id) .. " dead? = " .. tostring(distIDPairs[id].dead))
	--	setDebugFalse();
	end -- end the for loop
	
	setDebugFalse();


	
	
	local prevDis = 0;
	for i=1,#distIDPairs do
		--print("no sort DNW list: " .. distIDPairs[i].dist) 
		if distIDPairs[i].dist >= prevDis then
			prevDis = distIDPairs[i].dist
--		else
--			print(nil .. "hi")
--		end

		end	
	end
	


	-- sort everyone

	table.sort(distIDPairs, function (a, b) 
		if a.dist == b.dist then
			return a.id < b.id
		end
		return a.dist < b.dist end)
		--setDebugTrue();
	prevDis = 0	
	for i=1,#distIDPairs do
		--print("DNW list: " .. distIDPairs[i].dist .. " id = " .. tostring(distIDPairs[i].id)) 
		if distIDPairs[i].dist >= prevDis then
			prevDis = distIDPairs[i].dist
		else
			print(nil .. "hi")
		end
	end	
	setDebugFalse();
	
	-- loop
	
	
	
	
	local secondClosestWithin = 0

	--setDebugTrue();
	print("DNW number of distIDPairs is " .. tostring(#distIDPairs))
	countI  = 1
	for i=1, #distIDPairs do
		print(" i " .. i .. " count  " .. countI .. " distIDPairs.dead ~= nil = " .. tostring(distIDPairs[i].dead ~= nil) .. " distIDPairs[i].dead = " .. tostring(distIDPairs[i].dead));
		if distIDPairs[i].dead and distIDPairs[i].dead == 0 then
			print("DNW i = " .. tostring(i) .. " ID = " .. tostring(distIDPairs[i].id) .. " dist = " .. tostring(distIDPairs[i].dist) .. " distN = " .. tostring(wcm.get_horde_distN()));
	--		if(somebodyYelledKick() == 1 or Body.get_time() - lastTimeKicked < 2) then 
	--			distIDPairs[i].status = 2;	
	--		else
				distIDPairs[i].status = (countI-1)*2
	--		end
			if (distIDPairs[i].dist <= wcm.get_horde_distN() and i~=1) then
				distIDPairs[i].status = distIDPairs[i].status-1;
				print("DNW i = " .. tostring(i) .. " dist was less than N status = " ..  tostring(distIDPairs[i].status));
			end
		
			print("status DNW i = " .. tostring(i) .. " id = " .. tostring(distIDPairs[i].id) .. " status = " ..  tostring(distIDPairs[i].status) .. " dist = " .. tostring(distIDPairs[i].dist))
			print("DNW comparing " .. tostring(distIDPairs[i].id)  .. " and " .. tostring(state.id));	
			if distIDPairs[i].id == state.id then
				wcm.set_horde_status(distIDPairs[i].status);
				print("DNW i = " .. tostring(i) .. " My Status = " .. tostring(wcm.get_horde_status()));
			end
		
			print("DNW i = " .. tostring(i) .. " ID = " .. tostring(distIDPairs[i].id) .. " status = " .. tostring(wcm.get_horde_status()))
			countI = countI + 1
		end
	end
	
	setDebugFalse();
	

end


function somebodyYelledKick()
        avoidRaceCondition = wcm.get_team_yelledKick()
        for i=1,4 do
                if(avoidRaceCondition[i] == 1) then
                        return true
                end

        end
        return false;
end
function update_goalieCloseEnough()

	-- If i am the goalie then i check otherwise i just get the value that the
	-- was given to me by the goalie telling me it is close enough or not
	--setDebugTrue();
	if Config.game.role ~= 0 and Body.get_time() - lastTimeReceivedFromGoalie > GOALIE_DEAD_THRESHOLD then
		print("goalie dead, please don't persist GOALIE");
		wcm.set_horde_goalieCloseEnough(0); -- If I didn't get anything from the goalie then I can't assume he is close enought
		
		if wcm.get_horde_fallTime() > lastTimeReceivedFromGoalie and wcm.get_team_connected() == 1 then
			-- only if it has been a while since i received a message from the goalie and I'm still connected
			-- while I start to kick out of bounds.  
			wcm.set_horde_kickOutOfBounds(0);
		else
			-- otherwise I won't because I still want to at least play kiddie soccer when wifi dies
			wcm.set_horde_kickOutOfBounds(0);
		end
	else
		wcm.set_horde_kickOutOfBounds(0);
	end
	setDebugFalse();

end

function update_teamdata()
  attacker_eta = math.huge;
  defender_eta = math.huge;
  defender2_eta = math.huge;
  supporter_eta = math.huge;
  goalie_alive = 0; 

  attacker_pose = {0,0,0};
  defender_pose = {0,0,0};
  defender2_pose = {0,0,0};
  supporter_pose = {0,0,0};
  goalie_pose = {0,0,0};

  best_scoreBall = 0;
  best_ball = {0,0,0};
  for id = 1,5 do
    --Update teammates pose information
    if states[id] and states[id].tReceive and
      (t - states[id].tReceive < msgTimeout) then

      --Team ball calculation here
      --Score everyone's ball position info and pick the best one
      if id~=playerID and states[id].role<4 then
        rBall = math.sqrt(states[id].ball.x^2 + states[id].ball.y^2);
        tBall = states[id].time - states[id].ball.t;
        pBall = states[id].ball.p;
        scoreBall = pBall * 
        math.exp(-rBall^2 / 12.0)*
        math.max(0,1.0-tBall);
        --print(string.format("r%.1f t%.1f p%.1f s%.1f",rBall,tBall,pBall,scoreBall))
        if scoreBall > best_scoreBall then
          best_scoreBall = scoreBall;
          posexya=vector.new( 
            {states[id].pose.x, states[id].pose.y, states[id].pose.a} );
          best_ball=util.pose_global(
            {states[id].ball.x,states[id].ball.y,0}, posexya);
        end
      end

      if states[id].role==ROLE_GOALIE then
        goalie_alive =1;
        goalie_pose = {
          states[id].pose.x,states[id].pose.y,states[id].pose.a};
        goalie_ball = util.pose_global(
          {states[id].ball.x,states[id].ball.y,0},	  goalie_pose);
        goalie_ball[3] = states[id].time - states[id].ball.t ;



      elseif states[id].role==ROLE_ATTACKER then
          attacker_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
          attacker_eta = eta[id];
      elseif states[id].role==ROLE_DEFENDER then
          defender_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
          defender_eta = eta[id];
      elseif states[id].role==ROLE_SUPPORTER then
          supporter_eta = eta[id];
          supporter_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
      end
    end
  end

  local teamPoseX = {}
  local teamPoseY = {}
  local teamPoseA = {}
  local teamYellReady = {}
  local teamYellKick = {}

  for id = 1, 5 do
     teamYellReady[id] = 0;
     teamYellKick[id] = 0; 
	-- not here so just put them at the center
     teamPoseX[id] = 0;
     teamPoseY[id] = 0;
     teamPoseA[id] = 0;
    if(states[id]) then
	--setDebugTrue()
	print("Id = ".. id .. " yelledReady = " .. tostring(states[id].yelledKick))
	setDebugFalse()

    end 
    if states[id] and states[id].yelledReady then
      	 --print("Id = ".. id .. " yelledReady = " .. tostring(states[id].yelledReady))
	teamYellReady[id] = states[id].yelledReady
	teamPoseX[id] = states[id].pose.x;
	teamPoseY[id] =  states[id].pose.y;
	teamPoseA[id] =  states[id].pose.a;
    end
    if states[id] and states[id].yelledKick then
      		teamYellKick[id] = states[id].yelledKick
	teamPoseX[id] = states[id].pose.x;
	teamPoseY[id] =  states[id].pose.y;
	teamPoseA[id] =  states[id].pose.a;
   
    end
  end
  -- all the yelled ready people
  wcm.set_team_yelledReady(teamYellReady)
  --setDebugTrue()
	print("team Yell kick is .. " .. tostring(teamYellKick));
  setDebugFalse() 
  wcm.set_team_yelledKick(teamYellKick);

  wcm.set_team_teamPoseX(teamPoseX);
  wcm.set_team_teamPoseY(teamPoseY);
  wcm.set_team_teamPoseA(teamPoseA);


  wcm.set_robot_team_ball(best_ball);
  wcm.set_robot_team_ball_score(best_scoreBall);

  wcm.set_team_attacker_eta(attacker_eta);
  wcm.set_team_defender_eta(defender_eta);
  wcm.set_team_supporter_eta(supporter_eta);
  wcm.set_team_defender2_eta(defender2_eta);
  wcm.set_team_goalie_alive(goalie_alive);

  wcm.set_team_attacker_pose(attacker_pose);
  wcm.set_team_defender_pose(defender_pose);
  wcm.set_team_goalie_pose(goalie_pose);
  wcm.set_team_supporter_pose(supporter_pose);
  wcm.set_team_defender2_pose(defender2_pose);

end

function get_distance(curA, targetB)
	return math.sqrt(math.pow(curA.x - targetB.x, 2) + math.pow(curA.y - targetB.y, 2))
end

function get_distanceBetween(A, B)
	return math.sqrt(math.pow(A[1] - B[1], 2) + math.pow(A[2] - B[2], 2))
end

function getMidpoint()
 if gcm.get_team_color() == 1 then

                -- red attacks cyan goali
                print("  yellow ")
                postDefend = PoseFilter.postYellow;
        else
                --print("not yellow")
                -- blue attack yellow goal
                postDefend = PoseFilter.postCyan;
        end

        -- global 
        LPost = postDefend[1];
        RPost = postDefend[2];

        ballGlobal= {};
        ballGlobal.x = wcm.get_team_closestToBallLoc()[1]
        ballGlobal.y = wcm.get_team_closestToBallLoc()[2]


        -- my pose global
        pose=wcm.get_pose();

        LPost.x = LPost[1]
        LPost.y = LPost[2]
        RPost.x = RPost[1]
        RPost.y = RPost[2]
    farPost = {}
        if get_distance(ballGlobal, LPost) > get_distance(ballGlobal, RPost) then
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







function exit() end
function get_role()   return role; end
function get_player_id()    return playerID; end
function update_shm() 
   gcm.set_team_role(Config.game.role);
end

function set_role(r)
   Body.set_indicator_role(Config.game.role);  
--[[if role ~= r then 
    role = r;
    Body.set_indicator_role(role);
    if role == ROLE_ATTACKER then  Speak.talk('Attack');
    elseif role == ROLE_DEFENDER then  Speak.talk('Defend');
    elseif role == ROLE_SUPPORTER then Speak.talk('Support');
    elseif role == ROLE_GOALIE then Speak.talk('Goalie');
    elseif role == ROLE_DEFENDER2 then Speak.talk('Defender Two')
    elseif role == ROLE_CONFUSED then Speak.talk('Confused')
    elseif role == ROLE_RESERVE_PLAYER then Speak.talk('Player waiting')
    elseif role == ROLE_RESERVE_GOALIE then Speak.talk('Goalie waiting')
    else Speak.talk('ERROR: Unknown Role');
    end
  end]]--
  update_shm();
end

function pack_labelB()
  labelB = vcm.get_image_labelB();
  width = vcm.get_image_width()/8; 
  height = vcm.get_image_height()/8;
  count = vcm.get_image_count();
  array = serialization.serialize_label_rle(
    labelB, width, height, 'uint8', 'labelB',count);
  state.labelB = array;
end

function pack_vision_info()
  --Added Vision Info 
  state.goal=0;
  state.goalv1={0,0};
  state.goalv2={0,0};
  if vcm.get_goal_detect()>0 then
    state.goal = 1 + vcm.get_goal_type();
    local v1=vcm.get_goal_v1();
    local v2=vcm.get_goal_v2();
    state.goalv1[1],state.goalv1[2]=v1[1],v1[2];
    state.goalv2[1],state.goalv2[2]=0,0;
    centroid1 = vcm.get_goal_postCentroid1();
    orientation1 = vcm.get_goal_postOrientation1();
    axis1 = vcm.get_goal_postAxis1();
    state.goalB1 = {centroid1[1],centroid1[2],
    orientation1,axis1[1],axis1[2]};
    if vcm.get_goal_type()==3 then --two goalposts 
      state.goalv2[1],state.goalv2[2]=v2[1],v2[2];
      centroid2 = vcm.get_goal_postCentroid2();
      orientation2 = vcm.get_goal_postOrientation2();
      axis2 = vcm.get_goal_postAxis2();
      state.goalB2 = {centroid2[1],centroid2[2],
      orientation2,axis2[1],axis2[2]};
    end
  end
  state.landmark=0;
  state.landmarkv={0,0};
  state.corner=0;
  state.cornerv={0,0};
  if vcm.get_corner_detect()>0 then
    state.corner = vcm.get_corner_type();
    local v = vcm.get_corner_v();
    state.cornerv[1],state.cornerv[2]=v[1],v[2];
  end
end

function check_flip2()
  local is_confused = wcm.get_robot_is_confused();
  
  if is_confused==0 then return; end
  print("cofused is true, now i gotta wait some time");
  local pose = wcm.get_pose();
  local ball = wcm.get_ball();
  local ball_global = util.pose_global({ball.x,ball.y,0},{pose.x,pose.y,pose.a});
  local t = Body.get_time();
  local t_confused = wcm.get_robot_t_confused();

  --Wait a bit before trying correction
  if t-t_confused < flip_check_t then return; end
  print("okay that amount of time has passed");

  print(string.format("Goalie ball :%.1f %.1f %.1f",
		goalie_ball[1],goalie_ball[2],goalie_ball[3] ));
  print(string.format("Player ball: %.1f %.1f %.1f", 
		ball_global[1],ball_global[2],t-ball.t));



  if t-ball.t<flip_threshold_t	and goalie_ball[3]<flip_threshold_t then
     --Check X position
     if ((math.abs(ball_global[1])>flip_threshold_x) and
        (math.abs(goalie_ball[1])>flip_threshold_x)) --or
--	(math.abs(goalie_ball[1]-ball_global[1])>.75) then
       then
	if ball_global[1]*goalie_ball[1]<0 then
         wcm.set_robot_flipped(1);
       end
       --Now we are sure about our position
       wcm.set_robot_is_confused(0);
       if confusion_handling == 1 then
         set_role(ROLE_ATTACKER);
       end

     --Check Y position
     elseif ((math.abs(ball_global[2])>flip_threshold_y) and
            (math.abs(goalie_ball[2])>flip_threshold_y))-- or
	    --(math.abs(goalie_ball[2]-ball_global[2])>.75) then
	then
       if ball_global[2]*goalie_ball[2]<0 then
         wcm.set_robot_flipped(1);
       end

       --Now we are sure about our position
       wcm.set_robot_is_confused(0);
       if confusion_handling == 1 then
         set_role(ROLE_ATTACKER);
       end
     end
  end

  if wcm.get_robot_is_confused()==0 then
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
    print("CONFUSION FIXED")
  end
end

function check_confused()

  if flip_correction==0 then 
    wcm.set_robot_is_confused(0);
	  return; 
  end
  goalie_alive =  wcm.get_team_goalie_alive();
  if goalie_alive==0 then 
    wcm.set_robot_is_confused(0);
	  return; 
  end --Goalie's dead, we cannot correct flip

  pose = wcm.get_pose();
  t = Body.get_time();

  --Goalie or reserve players never get confused
  if role==ROLE_GOALIE or role >= ROLE_RESERVE_PLAYER then 
    wcm.set_robot_is_confused(0);
		return; 
	end
  is_confused = wcm.get_robot_is_confused();

  if is_confused>0 then
    --Currently confused
    if gcm.get_game_state() ~= 3 --If game state is not gamePlaying
       or gcm.in_penalty() --Or the robot is penalized
       then 
      --Robot gets out of confused state!
      wcm.set_robot_is_confused(0);
      if role==ROLE_CONFUSED then
        set_role(ROLE_ATTACKER); 
      end
    end
  else

    print(".........................................................................");
    print("Is Fall Down = " .. wcm.get_robot_is_fall_down());
    print("Pose x == " .. math.abs(pose.x))
    print("Pose y = " .. math.abs(pose.y))
    print("Game state = " .. gcm.get_game_state());
    print("confused_threshold_x " .. confused_threshold_x)
    print("confused_threshold_y " .. confused_threshold_y)
    --Should we turn confused?
    if wcm.get_robot_is_fall_down()>0 
       and math.abs(pose.x)<confused_threshold_x 
       and math.abs(pose.y)<confused_threshold_y 
       and gcm.get_game_state() == 3 --Only get confused during playing
			  then
      wcm.set_robot_is_confused(1);
      wcm.set_robot_t_confused(t);
      print("CONFUSED")
      print("CONFUSED")
      print("CONFUSED")
      print("CONFUSED")
      print("CONFUSED")

      if confusion_handling == 1 then
        set_role(ROLE_CONFUSED); --Robot gets confused!
      elseif confusion_handling == 2 then
        --Robot maintains current role
      end
    end
  end
end

--NSL role can be set arbitarily, so use config value
set_role(Config.game.role or 1);
