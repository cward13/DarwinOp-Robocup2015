module(..., package.seeall);

require('Body')
require('wcm')
require('walk')
require('vector')
require('walk')
require('position')

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


  print(string.format("Gotoball: kick dir:%d type:%d angle:%d",
	kick_dir,kick_type,kick_angle*180/math.pi ))
  print(string.format("Initial ball pos: %.2f %.2f",ball.x,ball.y));


  y_inv=0;
  kick_dir=1; --forcing always front kick, this is GMU addition
  kick_type=1; -- force stationation, gmu
  print("Approach, target: ",xTarget[2],yTarget[2]);

end



function entry()
  print("Body FSM:".._NAME.." entry");
  t0 = Body.get_time();
  ball = wcm.get_ball();
  HeadFSM.sm:set_state('headTrackGMU');
end

function update()
	ballx = wcm.get_ball_x();
	bally = wcm.get_ball_y();
	scaleFactor = 13*(math.abs(ballx)+math.abs(bally));
	rotateVel = 0;
	--util.poseRelative(
	angleToBall = math.atan2(bally,ballx);
	if(math.abs(bally)/math.abs(ballx)>.25) then
		if(bally>0) then
			rotateVel = 1;
		else
			rotateVel = -1;
		end
		if(math.abs(angleToBall)< .3) then
			rotateVel = rotateVel*math.abs(angleToBall);
		end
			
	end
	dist = math.abs(ballx)+math.abs(bally);
	if(dist>.5) then
		walk.set_velocity(ballx/scaleFactor, bally/scaleFactor,rotateVel);
	else
		walk.set_velocity(ballx/scaleFactor*(dist-.1), ballx/scaleFactor*(dist-.1), rotateVel)
	end
	
end

function exit()
  HeadFSM.sm:set_state('headLookGoalGMU');
end

function sign(x)
  if (x > 0) then return 1;
  elseif (x < 0) then return -1;
  else return 0;
  end
end
