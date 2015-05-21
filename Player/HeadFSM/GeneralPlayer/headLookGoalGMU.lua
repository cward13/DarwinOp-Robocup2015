module(..., package.seeall);
--SJ: IK based lookGoal to take account of bodytilt


require('Body')
require('Config')
require('vcm')
require('wcm')

t00 = 0;
yawSweep = Config.fsm.headLookGoal.yawSweep;
yawMax = Config.head.yawMax;
dist = Config.fsm.headReady.dist;
tScan = Config.fsm.headLookGoal.tScan;
minDist = Config.fsm.headLookGoal.minDist;
min_eta_look = Config.min_eta_look or 2.0;

yawMax = Config.head.yawMax or 90*math.pi/180;
fovMargin = 30*math.pi/180;
myTLost = 3; -- 3s timeout until lost

MAX_BALL_DIST = 0.5; -- half a meter and I will 


function entry()
  print(_NAME.." entry");
  t00 = Body.get_time();


  --SJ: Check which goal to look at
  --Now we look at the NEARER goal
  pose = wcm.get_pose();
  defendGoal = wcm.get_goal_defend();
  attackGoal = wcm.get_goal_attack();

  dDefendGoal= math.sqrt((pose.x-defendGoal[1])^2 + (pose.y-defendGoal[2])^2);
  dAttackGoal= math.sqrt((pose.x-attackGoal[1])^2 + (pose.y-attackGoal[2])^2);
  attackAngle = wcm.get_attack_angle();
  defendAngle = wcm.get_defend_angle();

  --Can we see both goals?
  if math.abs(attackAngle)<yawMax + fovMargin and 
     math.abs(defendAngle)<yawMax + fovMargin  then
    --Choose the closer one
    if dAttackGoal < dDefendGoal then
      yaw0 = attackAngle;
    else
      yaw0 = defendAngle;
    end
  elseif math.abs(attackAngle)<yawMax + fovMargin then
    yaw0 = attackAngle;
  elseif math.abs(defendAngle)<yawMax + fovMargin then
    yaw0 = defendAngle;
  else --We cannot see any goals from this position
    --We can still try to see the goals?
    if  math.abs(attackAngle) < math.abs(defendAngle) then
      yaw0 = attackAngle;
    else
      yaw0 = defendAngle;
    end
  end
  vcm.set_camera_command(0); --top camera
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
function update()


	local t = Body.get_time();

	ball = wcm.get_ball();
  	ballR = math.sqrt (ball.x^2 + ball.y^2);
	if(somebodyYelledKick()) then
 		if(wcm.get_horde_ballLost()) then return "LostAndTime" end

		return "timeout"
	end
	if ballR < MAX_BALL_DIST then
		
		if (t - ball.t > myTLost) then
			return 'LostAndTime'
		end	
		return "timeout";
	end
	

  --setDebugTrue()
  --print("hey im in HEAD update");
  local t = Body.get_time();
  tScan = 2
  local tpassed=t-t00;
  local ph= tpassed/tScan;
  local yawbias = (ph-0.5)* yawSweep;
  --print("guess im not dead yet HEAD");
  height=vcm.get_camera_height();

  yaw1 = math.min(math.max(yaw0+yawbias, -yawMax), yawMax);
  local yaw, pitch =HeadTransform.ikineCam(
	dist*math.cos(yaw1),dist*math.sin(yaw1), height);
  Body.set_head_command({yaw, pitch});
	setDebugTrue();
  if (t - t00 > tScan or Config.game.role==0) then
    tGoal = wcm.get_goal_t();
    print("HEAD transitioning, " .. tostring(wcm.get_horde_ballLost()))
    if(wcm.get_horde_ballLost() == 1 ) then 
		return 'LostAndTime'
    end
	return 'timeout'; 
  end
	setDebugFalse();
end

function exit()
  vcm.set_camera_command(-1); --switch camera
end

