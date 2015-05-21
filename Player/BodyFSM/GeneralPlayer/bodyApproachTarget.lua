module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')
require('walk')
require('position')
require('Config')


t0 = 0;
timeout = Config.fsm.bodyApproach.timeout;
maxStep = Config.fsm.bodyApproach.maxStep; -- maximum walk velocity
rFar = Config.fsm.bodyApproach.rFar;-- maximum ball distance threshold
tLost = Config.fsm.bodyApproach.tLost; --ball lost timeout

-- default kick threshold
xTarget = Config.fsm.bodyApproach.xTarget11;
yTarget = Config.fsm.bodyApproach.yTarget11;

dapost_check = Config.fsm.daPost_check or 0;
daPostMargin = Config.fsm.daPostMargin or 15*math.pi/180;

fast_approach = Config.fsm.fast_approach or 0;
enable_evade = Config.fsm.enable_evade or 0;
evade_count=0;

last_ph = 0;

function check_approach_type()
  is_evading = 0;
  check_angle=1;
  ball = wcm.get_ball();
  kick_dir=wcm.get_kick_dir();
  kick_type=wcm.get_kick_type();
  kick_angle=wcm.get_kick_angle();

  role = gcm.get_team_role();

  --Evading kick check
  do_evade_kick=false;
  if enable_evade==1 and role>0 then
    evade_count = evade_count+1;
    if evade_count % 2 ==0 then
      do_evade_kick=true;
    end
  elseif enable_evade==2 then

-- Hack : use localization info to detect obstacle
-- We should use vision
    obstacle_num = wcm.get_obstacle_num();
    obstacle_x = wcm.get_obstacle_x();
    obstacle_y = wcm.get_obstacle_y();
    obstacle_dist = wcm.get_obstacle_dist();

    for i=1,obstacle_num do
      if obstacle_dist[i]<0.60 then
        obsAngle = math.atan2(obstacle_y[i],obstacle_x[i]);
        if math.abs(obsAngle) < 40*math.pi/180 then
  	  do_evade_kick = true;
        end
      end
    end
  end


  if do_evade_kick then
    print("EVADE KICK!!!")
    pose=wcm.get_pose();
    goalDefend = wcm.get_goal_defend();
    --Always sidekick to center side
    if (pose.y>0 and goalDefend[1]>0) or
       (pose.y<0 and goalDefend[1]<0) then
      kick_type = 2;
      kick_dir = 2; --kick to the right
      wcm.set_kick_dir(kick_dir);
      wcm.set_kick_type(kick_type);
    else
      kick_type = 2;
      kick_dir = 3; --kick to the left
      wcm.set_kick_dir(kick_dir);
      wcm.set_kick_type(kick_type);
    end
    check_angle = 0; --Don't check angle if we're doing evade kick
  end

  print(string.format("Approach: kick dir:%d type:%d angle:%d",
	kick_dir,kick_type,kick_angle*180/math.pi ))
  print(string.format("Initial ball pos: %.2f %.2f",ball.x,ball.y));


  y_inv=0;
   kick_type=2;
   kick_dir=1;  
  if kick_type==1 then --Stationary 
    if kick_dir==1 then --Front kick
      xTarget = Config.fsm.bodyApproach.xTarget11;
      yTarget0 = Config.fsm.bodyApproach.yTarget11;
      if sign(ball.y)<0 then y_inv=1;end
    elseif kick_dir==2 then --Kick to the left
      xTarget = Config.fsm.bodyApproach.xTarget12;
      yTarget0 = Config.fsm.bodyApproach.yTarget12;
    else --Kick to the right
      xTarget = Config.fsm.bodyApproach.xTarget12;
      yTarget0 = Config.fsm.bodyApproach.yTarget12;
      y_inv=1;
    end
  elseif kick_type==2 then --walkkick
    if kick_dir==1 then --Front kick
      xTarget = Config.fsm.bodyApproach.xTarget21;
      yTarget0 = Config.fsm.bodyApproach.yTarget21;
      if sign(ball.y)<0 then y_inv=1; end
    elseif kick_dir==2 then --Kick to the left
      xTarget = Config.fsm.bodyApproach.xTarget22;
      yTarget0 = Config.fsm.bodyApproach.yTarget22;
    else --Kick to the right
      xTarget = Config.fsm.bodyApproach.xTarget22;
      yTarget0 = Config.fsm.bodyApproach.yTarget22;
      y_inv=1;
    end
  else --stepkick



  end

  if y_inv>0 then
    yTarget[1],yTarget[2],yTarget[3]=
      -yTarget0[3],-yTarget0[2],-yTarget0[1];
  else
     yTarget[1],yTarget[2],yTarget[3]=
       yTarget0[1],yTarget0[2],yTarget0[3];
  end
  print("Approach, target: ",xTarget[2],yTarget[2]);

end


sillyTempFoo = 0;
function entry()
   sillyTempFoo = 0
  print("Body FSM:".._NAME.." entry");
  t0 = Body.get_time();
  ball = wcm.get_ball();
  check_approach_type(); --walkkick if available

  if t0-ball.t<0.2 then
    ball_tracking=true;
    print("Ball Tracking")
    --HeadFSM.sm:set_state('headKick');
  else
    ball_tracking=false;
  end

  role = gcm.get_team_role();
  if role==0 then
    aThresholdTurn = Config.fsm.bodyApproach.aThresholdTurnGoalie;
  else
    aThresholdTurn = Config.fsm.bodyApproach.aThresholdTurn;
  end

  approach_count = 0;
end

function update()
  sillyTempFoo = sillyTempFoo +1;
  if(sillyTempFoo%10 == 0) then
	setDebugTrue();
	print("hey i am in approach ball update");
	setDebugFalse();
  end
  local t = Body.get_time();
 
  -- get ball position 
  ball = wcm.get_ball();
  ballR = math.sqrt(ball.x^2 + ball.y^2);

  if t-ball.t<0.2 and ball_tracking==false then
    ball_tracking=true;
    HeadFSM.sm:set_state('headKick');
  end
   setDebugTrue();
   print("well i got the head done and ...");
  --Current cordinate origin: midpoint of uLeft and uRight
  --Calculate ball position from future origin
  --Assuming we stop at next step
  if fast_approach == 1 then
    print("well fast approach is true");
    uLeft = walk.uLeft;
    uRight = walk.uRight;
    uFoot = util.se2_interpolate(0.5,uLeft,uRight); --Current origin 
    if walk.supportLeg ==0 then --left support 
      uRight2 = walk.uRight2;
      uLeft2 = util.pose_global({0,2*walk.footY,0},uRight2);
    else --Right support
      uLeft2 = walk.uLeft2;
      uRight2 = util.pose_global({0,-2*walk.footY,0},uLeft2);
    end
    uFoot2 = util.se2_interpolate(0.5,uLeft2,uRight2); --Projected origin 
    uMovement = util.pose_relative(uFoot2,uFoot);
    uBall2 = util.pose_relative({ball.x,ball.y,0},uMovement);
    ball.x=uBall2[1];
    ball.y=uBall2[2];
    factor_x = 0.8;
  else
    factor_x = 0.6;
  end
print("well, that condition is over");
  
  -- calculate walk velocity based on ball position
  vStep = vector.new({0,0,0});
  vStep[1] = factor_x*(ball.x - xTarget[2]);
  vStep[2] = .75*(ball.y - yTarget[2]);
  scale = math.min(maxStep/math.sqrt(vStep[1]^2+vStep[2]^2), 1);
  vStep = scale*vStep;

  is_confused = wcm.get_robot_is_confused();
print("this might be killin me?");
  if false then --Config.fsm.playMode==1 or is_confused>0 then 
    --Demo FSM, just turn towards the ball
    print("p sure this code is killing me");
    ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05),
            ball.x+0.10);
    vStep[3] = 0.5*ballA;
    targetangle = 0;
    angleErrL = 0;
    angleErrR = 0;

  else
    --Player FSM, turn towards the goal
--    attackBearing, daPost = wcm.get_attack_bearing();
    position.posCalc();

    kickAngle = wcm.get_kick_angle();
    attackAngle = wcm.get_goal_attack_angle2()-kickAngle;
    daPost = wcm.get_goal_daPost2();

    if dapost_check == 0 then
      daPost1 = 2*aThresholdTurn;
    else
      daPost1 = math.max(2*aThresholdTurn,daPost - daPostMargin);
    end

    --Wider margin for sidekicks and goalies
    if kick_dir~=1 or role==0 then 
      daPost1 = math.max(25*math.pi/180,daPost1);
    end

    pose=wcm.get_pose();

    angleErrL = util.mod_angle(pose.a - (attackAngle + daPost1 * 0.5));
    angleErrR = util.mod_angle((attackAngle - daPost1 * 0.5)-pose.a);

    --If we have room for turn, turn to the ball
    angleTurnMargin = -10*math.pi/180;
    ballA = math.atan2(ball.y - math.max(math.min(ball.y, 0.05), -0.05),
            ball.x+0.10);
     --upenn override positioning
    print("well we havent crashed yet"); 
    
    print("got to pose to goal calculation");
    pose = wcm.get_pose();
    print("grabbed pose from wcm");
   --[[ 
    if wcm.get_horde_kickOutOfBounds() == 1 then
    	
    	receiveRelative = util.pose_relative({pose.x, pose.y/math.abs(pose.y) * Config.world.yMax, 0} , {pose.x, pose.y, pose.a});
		setDebugTrue()
		print("kick to " .. vector.tostring(vector.new({pose.x, pose.y/math.abs(pose.y) * Config.world.yMax, 0})));
		setDebugFalse();
    else--]]
		receiveRelative = util.pose_relative(wcm.get_horde_kickToPose(), {pose.x, pose.y, pose.a});
		setDebugTrue()
		print("kick to " .. vector.tostring(wcm.get_horde_kickToPose()));
		setDebugFalse();
    --end
    
	setDebugTrue();
    receiveRelative[3] = math.atan2(receiveRelative[2], receiveRelative[1]);
    --receiveRelative = util.pose_relative(wcm.get_goal_attack(), {pose.x, pose.y, pose.a});

     
	print("calculated goal relative");
    angle_check_done = true;
    setDebugTrue()
     print("goal relative: " .. receiveRelative[3]);
   setDebugFalse();
    stepFactor = 1;
  --  if(receiveRelative[1]<0)then
--	stepFactor = -1;
 --   end
     setDebugTrue()
    if (math.abs(receiveRelative[3]) >.15) then
    	if receiveRelative[2] > 0 then
      		print("turn left");
		vStep[3]=0.2*stepFactor;
      	elseif receiveRelative[2]  < 0 then
        	print("turn right");
		vStep[3]=-0.2*stepFactor;
      	else
      	  vStep[3]=0;
      	end
      end
	setDebugFalse();
   --
    -- end override
--[[TEMP
   if check_angle>0 then
      if angleErrR > 0 then
print("would TURNLEFT")
        vStep[3]=0.2;
      elseif angleErrL > 0 then
print("would TURNRIGHT")
        vStep[3]=-0.2;
      else
        vStep[3]=0;
      end
   end 
--DELETE]]--
  --when the ball is on the side of the ROBOT, backstep a bit
  local wAngle = math.atan2 (ball.y,ball.x);
  ballYMin = Config.fsm.bodyApproach.ballYMin or 0.20;

  if math.abs(wAngle) > 45*math.pi/180 then
    vStep[1]=vStep[1] - 0.03;

    if ball.y<ballYMin and ball.y>0 then
     vStep[2] = -0.03;
    elseif ball.y<0 and ball.y>-ballYMin then
      vStep[2]=0.03;
    else
      vStep[2] = 0;
    end    
--get_goal_attack();
  else
    --Otherwise, don't make robot backstep
    vStep[1]=math.max(-0.01,vStep[1]);
  end

  if walk.ph<last_ph then 
    print(string.format("Approach step %d, ball seen %.2fs ago"
	,approach_count, t-ball.t));
    print(string.format("BallX: %.3f  Target: (%.3f  <%.3f> %.3f)",
	ball.x,xTarget[1],xTarget[2],xTarget[3] ));
    print(string.format("BallY: %.3f  Target: (%.3f  <%.3f> %.3f)",
	ball.y,yTarget[1],yTarget[2],yTarget[3] ));
    print(string.format("Approach velocity:%.2f %.2f %.2f\n",vStep[1],vStep[2],vStep[3]));
    approach_count = approach_count + 1;
   end
  last_ph = walk.ph;
 
  walk.set_velocity(vStep[1],vStep[2],vStep[3]);

  if (t - ball.t > tLost) and role>0 then
    HeadFSM.sm:set_state('headScan');
    print("ballLost")
    return "ballLost";
  end
 --[[ if (t - t0 > timeout) then
    HeadFSM.sm:set_state('headTrack');
    print("timeout")
    return "timeout";
  end]]--
  if (ballR > rFar) then
    HeadFSM.sm:set_state('headTrack');
    print("ballfar, ",ballR,rFar)
    return "ballFar";
  end
 angle_check_done= true;
 if check_angle>0 and
     (angleErrL > 0 or
     angleErrR > 0 )then
    --angle_check_done=false;
    print("Goal stats: " .. receiveRelative[1] .. ", " .. receiveRelative[2] .. ", " .. receiveRelative[3]);
  else
    print("Goal stats ACCEPT: " .. receiveRelative[1] .. ", " .. receiveRelative[2] .. ", " .. receiveRelative[3]);
  end
  if (math.abs(receiveRelative[3]) >.15) then
     print("my kick would NOT trigger");
     angle_check_done=false;
  else
     print("my kick would trigger");
  end
    --For front kick, check for other side too
  setDebugTrue();
  print("kick_dir is " .. tostring(kick_dir));
  kick_dir = 1;
  if kick_dir==1 then --Front kick
    yTargetMin = math.min(math.abs(yTarget[1]),math.abs(yTarget[3]));
    yTargetMax = math.max(math.abs(yTarget[1]),math.abs(yTarget[3]));

    if (ball.x < xTarget[3]) and (t-ball.t < 0.5) and
       (math.abs(ball.y) > yTargetMin) and 
	(math.abs(ball.y) < yTargetMax) and
	angle_check_done then
	
      print("KICK DIR,TYPE: " .. kick_dir .. "," ..kick_type);
      print(string.format("Approach done, ball position: %.2f %.2f\n",ball.x,ball.y))
      print(string.format("Ball target: %.2f %.2f\n",xTarget[2],yTarget[2]))
      if kick_type==1 then 
	
	print("1OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("1OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("1OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("1OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("1OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	wcm.set_horde_doneApproach(1);
	--wcm.set_horde_ready(0);
	return "kick";
      else 
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	wcm.set_horde_doneApproach(1);
	--wcm.set_horde_ready(1);
	return "walkkick";
      end
    else
        print("setting front approach to zero");
        wcm.set_horde_doneApproach(0);
    end
  else
    --Side kick, only check one side
    if (ball.x < xTarget[3]) and (t-ball.t < 0.5) and
       (ball.y > yTarget[1]) and (ball.y < yTarget[3]) and
       angle_check_done then
print("KICK DIR,TYPE: " .. kick_dir .. "," ..kick_type);
      print(string.format("Approach done, ball position: %.2f %.2f\n",ball.x,ball.y))
      print(string.format("Ball target: %.2f %.2f\n",xTarget[2],yTarget[2]))
      if kick_type==1 then 
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	wcm.set_horde_doneApproach(1);
	--wcm.set_horde_ready(1);
	return "kick";
      else 
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	print("OMFGOMFGOMFOMGOMFOMFOMGOMGOMGOMG KICK");
	wcm.set_horde_doneApproach(1);
	--wcm.set_horde_ready(1);
	return "walkkick";
      end
    else
        print("setting front approach to zero");
        wcm.set_horde_doneApproach(0);
    end
    end
  end
  setDebugFalse();
end

function exit()
  print("setting front approach to zero2");
  wcm.set_horde_doneApproach(0);
  HeadFSM.sm:set_state('headTrackGMU');
end

function sign(x)
  if (x > 0) then return 1;
  elseif (x < 0) then return -1;
  else return 0;
  end
end
