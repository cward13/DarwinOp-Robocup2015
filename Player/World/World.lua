module(..., package.seeall);

require('PoseFilter');
require('Filter2D');
require('Body');
require('vector');
require('util');
require('wcm')
require('vcm');
require('gcm');
require('mcm');
require('Config');

-- intialize sound localization if needed
useSoundLocalization = Config.world.enable_sound_localization or 0;
if (useSoundLocalization > 0) then
  require('SoundFilter');
end

--SJ: Velocity filter is always on
--We can toggle whether to use velocity to update ball position estimate
--In Filter2D.lua

mod_angle = util.mod_angle;

use_kalman_velocity = Config.use_kalman_velocity or 0;

if use_kalman_velocity>0 then
  Velocity = require('kVelocity');	
else
  require('Velocity');	
end

xMax = Config.world.xMax;
yMax = Config.world.yMax;

--Use ground truth pose and ball information for webots?
use_gps_only = Config.use_gps_only or 0;
gps_enable = Body.gps_enable or 0;

--Use team vision information when we cannot find the ball ourselves
tVisionBall = 1;
use_team_ball = Config.team.use_team_ball or 0;
team_ball_timeout = Config.team.team_ball_timeout or 0;
team_ball_threshold = Config.team.team_ball_threshold or 0;


--For NSL, eye LED is not allowed during match
led_on = Config.game.led_on; --Default is ON

ballFilter = Filter2D.new();
ball = {};
ball.t = 0;  --Detection time
ball.x = 1.0;
ball.y = 0;
ball.vx = 0;
ball.vy = 0;
ball.p = 0; 

pose = {};
pose.x = 0;
pose.y = 0;
pose.a = 0;
pose.tGoal = 0; --Goal detection time

uOdometry0 = vector.new({0, 0, 0});
count = 0;
cResample = Config.world.cResample; 

playerID = Config.game.playerID;

odomScale = Config.walk.odomScale or Config.world.odomScale;
wcm.set_robot_odomScale(odomScale);

--SJ: they are for IMU based navigation
imuYaw = Config.world.imuYaw or 0;
yaw0 =0;

--Track gcm state
gameState = 0;
function getGoalSign()
	setDebugFalse();
        if gcm.get_team_color() == 1 then
                -- red attacks cyan goali
                --print(" yellow ")
                postDefend = PoseFilter.postYellow;
        else
                --print("not yellow")
                -- blue attack yellow goal
                postDefend = PoseFilter.postCyan;
        end

        -- global
        LPost = postDefend[1];

        sign = LPost[1] / math.abs(LPost[1])
        wcm.set_horde_goalSign(sign);
        return sign
end
function init_particles()
  --Now we ALWAYS use the same colored goalposts
  --Init particles to our side
  setDebugTrue();
  goalDefend=get_goal_defend();
  local goalDefendSign = getGoalSign();
 --print(goalDefend[1] 
 -- print("goalDefend[1] is " .. goalDefend[1]);
 -- print("goal defend sign is " .. goalDefendSign)
 
 PoseFilter.initializeUniform(vector.new({math.abs(goalDefend[1]/2)*goalDefendSign,  goalDefendSign * Config.world.yMax,  -1* math.pi/2 *goalDefendSign}), vector.new({.15*xMax, .15*yMax, math.pi/6}))
 --[[
  if gcm.get_team_player_id() % 2 == 0 then
  	-- want a low spread so set the second arg manually
    PoseFilter.initializeUniform(vector.new({math.abs(goalDefend[1]/2)*goalDefendSign,  goalDefendSign * Config.world.yMax,  -1* math.pi/2 *goalDefendSign}), vector.new({.15*xMax, .15*yMax, math.pi/6}))
  else
  	-- want a low spread so set the second arg manually
  	PoseFilter.initializeUniform(vector.new({math.abs(goalDefend[1]/2)*goalDefendSign,  -1 * goalDefendSign * Config.world.yMax,  math.pi/2 * goalDefendSign}), vector.new({.15*xMax, .15*yMax, math.pi/6}))
  end
   --]]
  --if (useSoundLocalization > 0) then
  --  SoundFilter.reset();
  --end
  setDebugFalse();
  update_shm();
end

function init_startGoalLine()

	goalDefend=get_goal_defend();
  	local goalDefendSign = getGoalSign();
	if gcm.get_team_player_id() == 4 then -- I am the goalie
		PoseFilter.initializeUniform(vector.new({goalDefend[1],  0,  -1* math.pi/2 *goalDefendSign}), vector.new({.15*xMax, .15*yMax, math.pi/6}))
	else
		if gcm.get_team_player_id() % 2 == 0 then
			-- want a low spread so set the second arg manually
			PoseFilter.initializeUniform(vector.new({goalDefend[1],  goalDefendSign * .5,  -1* math.pi/2 *goalDefendSign}), vector.new({.15*xMax, .15*yMax, math.pi/6}))
		else
			-- want a low spread so set the second arg manually
			PoseFilter.initializeUniform(vector.new({goalDefend[1],  -1 * goalDefendSign * .5,  math.pi/2 * goalDefendSign}), vector.new({.15*xMax, .15*yMax, math.pi/6}))
		end
	end
	
end


function init_penalty_particles()

	local penaltyYLoc = wcm.get_teamdata_penaltyLocation()
	if penaltyYLoc < 0 then
		PoseFilter.initializeUniform(vector.new({0, penaltyYLoc, math.pi/2}), {.15*xMax, .15*yMax, math.pi/6});
	else
		PoseFilter.initializeUniform(vector.new({0, penaltyYLoc, -math.pi/2}), {.15*xMax, .15*yMax, math.pi/6});
	end


	update_shm();
end

function entry()
  count = 0;
  init_particles();
  Velocity.entry();
end

function init_particles_manual_placement()
  --print('re-initializing particles in world')
  if gcm.get_team_role() == 0 then
  -- goalie initialized to different place
    goalDefend=get_goal_defend();
    --util.ptable(goalDefend);
    dp = vector.new({0.04,0.04,math.pi/8});
    if goalDefend[1] > 0 then
      PoseFilter.initialize(vector.new({goalDefend[1],0,math.pi}), dp);
    else
      PoseFilter.initialize(vector.new({goalDefend[1],0,0}), dp);
    end
  else
    dp = vector.new({1.0, 1.0,math.pi/8});

    if goalDefend[1] > 0 then 
      PoseFilter.initialize({goalDefend[1]/2,0,math.pi},dp);
    else
      PoseFilter.initialize({goalDefend[1]/2,0,0},dp);
    end
    if (useSoundLocalization > 0) then
      SoundFilter.reset();
    end
  end
end

function allLessThanTenth(table)
  for k,v in pairs(table) do
    if v >= .1 then
      return false
    end
  end
  return true
end

function allZeros(table)
  for k,v in pairs(table) do
    if v~=0 then
      return false
    end
  end
  return true
end


function update_odometry()

  odomScale = wcm.get_robot_odomScale();
  count = count + 1;
  uOdometry, uOdometry0 = mcm.get_odometry(uOdometry0);

  uOdometry[1] = odomScale[1]*uOdometry[1];
  uOdometry[2] = odomScale[2]*uOdometry[2];
  uOdometry[3] = odomScale[3]*uOdometry[3];

  --Gyro integration based IMU
  if imuYaw==1 then
    yaw = Body.get_sensor_imuAngle(3);
    uOdometry[3] = yaw-yaw0;
    yaw0 = yaw;
    --print("Body yaw:",yaw*180/math.pi, " Pose yaw ",pose.a*180/math.pi)
  end

  ballFilter:odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
  PoseFilter.odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
  if (useSoundLocalization > 0) then
    SoundFilter.odometry(uOdometry[1], uOdometry[2], uOdometry[3]);
    SoundFilter.update();
  end
end


function update_pos()
  -- update localization without vision (for odometry testing)
  if count % cResample == 0 then
    PoseFilter.resample();
  end

  pose.x,pose.y,pose.a = PoseFilter.get_pose();
  update_shm();
end


function update_vision()
 --Added by david to flip angle if we find the goalie having the urge to travel more than 3 meters in the X direction
 -- if(wcm.get_horde_confused()==1) then
--	PoseFilter.flip_particle_angle();
  --	wcm.set_horde_confused(0);
  --end


  -- drew added to
  -- if I can see both the goal posts then I should move my particles to 0,0
  --[[if (wcm.get_horde_moveParticlesToCenter() == 1) then
	PoseFilter.setCloserToCenter();
	wcm.set_horde_moveParticlesToCenter(0);
  end]]--


  --added by David to re initialize particles in initial game state
  local state = gcm.get_game_state();
  if(state==0) then -- if in initial
     init_particles();
     update_pos();
     update_shm();
     return;
  end
  
  if (state == 1 or state == 2) then -- if we are in ready or set
  	if wcm.get_horde_startGoalLine() == 1 then -- if we have set it so we will start on goal line
  		-- we set the particles on the goal line
  		init_startGoalLine()
  		update_pos();
		update_shm();
		return;
  	end
  end
  
  local amPenalized = gcm.in_penalty()
  --DREW added so that the bot will know where it is at when it is penalized.
  if amPenalized == true then
  	-- I should move my particles to penalty location
  	init_penalty_particles();
  end
  
  -- only add noise while robot is moving
  if count % cResample == 0 then
    PoseFilter.resample();
    if mcm.get_walk_isMoving()>0 then
      PoseFilter.add_noise();
    end
  end

  -- Reset heading if robot is down
  if (mcm.get_walk_isFallDown() == 1) then
    PoseFilter.reset_heading(.75);--DAVID currently commented this out, trying to figure out why things are flipping, probably flipping particles 
  end
  
  -- if my ball global does not have the same sign as the goal sign then flip particles
  -- should also be pretty far from center on x axis
setDebugTrue()
  print(tostring(wcm.get_horde_goalieCertainBallOnMySide()==1) .." ".. tostring(wcm.get_ballGlobal_x() / math.abs(wcm.get_ballGlobal_x()) ~= wcm.get_horde_goalSign() ) .. " " ..tostring(math.abs(wcm.get_ballGlobal_x()) > 1));

  if(Config.game.role ~= 0) then
   if wcm.get_horde_goalieCertainBallOnMySide() == 1 and wcm.get_ballGlobal_x() / math.abs(wcm.get_ballGlobal_x()) ~= wcm.get_horde_goalSign() and math.abs(wcm.get_ballGlobal_x()) > 1 and vcm.get_ball_detect() == 1 and gcm.in_penalty() == false and gcm.get_game_state() == 3 then
  	print("HEY SOMETHING IS WRONG, FLIPPIN THOSE PARTICLES");
	PoseFilter.flip_particles(); -- then flip em
	 wcm.set_horde_safetySaysFlip(0)
 
--[[ -- we don't want upenn's flip seems to interfere with our flip
  elseif wcm.get_robot_flipped() == 1 then
    print("HEY FLIPPING PARTICLES CAUSE UPENN SAID SO");
    PoseFilter.flip_particles();
    wcm.set_robot_flipped(0);
    ]]--
    -- so if the safety thinks i should flip and the goalie doesn't think its on his side then I can flip
    elseif wcm.get_horde_safetySaysFlip() == 1 then
  	print("SAFETY SAID TO FLIP, freakingsafety");
	PoseFilter.flip_particles(); -- then flip em
  	wcm.set_horde_safetySaysFlip(0)
  end
  
  
 end
-- if goalie thinks he's on offensive side, he's wrong. no way in hell
--print("YOe ".. tostring(wcm.get_pose().x/math.abs(wcm.get_pose().x)) .. " " .. tostring(wcm.get_horde_goalSign() ))
	
if(Config.game.role == 0 and (wcm.get_pose().x/math.abs(wcm.get_pose().x))~= wcm.get_horde_goalSign()) then
	print("YO, goalie was on wrong side ".. wcm.get_pose().x .. " " .. tostring(wcm.get_horde_goalSign() ))
	--PoseFilter.flip_particles()
end
setDebugFalse()
 ---David: I commented this out because I it looks at gamestate  and re initializes the particles based on that. I dont want it to do that at all for our purposes
  --gameState = gcm.get_game_state();
  --if (gameState == 0) then
  --  init_particles();
  --end
  -- if (gameState == 2) then
  --   init_particles_manual_placement();
  --if gcm.in_penalty() then
  --  init_particles()
  --end

  -- Penalized?
  --if gcm.in_penalty() then
  --  wcm.set_robot_penalty(1);
  --else
  --  wcm.set_robot_penalty(0);
  --end

  webots = Config.webots
  --if not webots or webots==0 then
  --  fsrRight = Body.get_sensor_fsrRight()
  --  fsrLeft = Body.get_sensor_fsrLeft()

    --reset particle to face opposite goal when getting manual placement on set
 --   if gcm.get_game_state() ==2 then
  --    if (not allZeros(fsrRight)) and (not allZeros(fsrLeft)) then --Do not do this if sensor is broken
  --      if allLessThanTenth(fsrRight) and allLessThanTenth(fsrLeft) then
  --        init_particles_manual_placement()
  --      end
  --    end
  --  end

  --end
    
  -- ball
  ball_gamma = 0.3;
  t=Body.get_time();


  if (vcm.get_ball_detect() == 1) then
    tVisionBall = Body.get_time();
    ball.p = (1-ball_gamma)*ball.p+ball_gamma;
    local v = vcm.get_ball_v();
    local dr = vcm.get_ball_dr();
    local da = vcm.get_ball_da();
    ballFilter:observation_xy(v[1], v[2], dr, da);
    --Green insted of red for indicating
    --As OP tend to detect red eye as balls
    ball_led= {0,1,0} ---{1,0,0}; 

    -- Update the velocity
    -- use centroid info only
    ball_v_inf = wcm.get_ball_v_inf();
    ball.t = Body.get_time();

    t_locked = wcm.get_ball_t_locked_on();
    th_locked = 1.5;

    if (t_locked > th_locked ) and wcm.get_ball_locked_on() == 1 then
      Velocity.update(ball_v_inf[1],ball_v_inf[2],ball.t);
      ball.vx, ball.vy, dodge  = Velocity.getVelocity();
    else
      Velocity.update_noball(ball.t);--notify that ball is missing
    end
  else
    ball.p = (1-ball_gamma)*ball.p;
    Velocity.update_noball(Body.get_time());--notify that ball is missing
    ball_led={0,0,0};
  end
  -- TODO: handle goal detections more generically
  --print("@@@do i detect a goal?: " .. vcm.get_goal_detect()); 
  if vcm.get_goal_detect() == 1 then
    pose.tGoal = Body.get_time();
    local color = vcm.get_goal_color();
    local goalType = vcm.get_goal_type();
    local v1 = vcm.get_goal_v1();
    local v2 = vcm.get_goal_v2();
    local v = {v1, v2};
    --print("@@@the goal type is " .. goalType);
    if (goalType == 0) then
      PoseFilter.post_unified_unknown(v);
      goal_led = {1,1,0}
      --Body.set_indicator_goal({1,1,0});
    elseif(goalType == 1) then
      PoseFilter.post_unified_left(v);
      goal_led = {1,1,0}
      --Body.set_indicator_goal({1,1,0});
    elseif(goalType == 2) then
      PoseFilter.post_unified_right(v);
      goal_led = {1,1,0}
      --Body.set_indicator_goal({1,1,0});
    elseif(goalType == 3) then
      --print("updating based on goal position");
      PoseFilter.goal_unified(v);
      goal_led = {0,0,1}
      --Body.set_indicator_goal({0,0,1});
    end
  end

  -- line update
  if vcm.get_line_detect() == 1 then
    local v = vcm.get_line_v();
    local a = vcm.get_line_angle();
    
    PoseFilter.line(v, a);--use longest line in the view
  end

  if vcm.get_corner_detect() == 1 then
    local v=vcm.get_corner_v();
    PoseFilter.corner(v);
  end

  if vcm.get_landmark_detect() == 1 then
    local color = vcm.get_landmark_color();
    local v = vcm.get_landmark_v();
    if color == Config.color.yellow then
        PoseFilter.landmark_yellow(v);
	      goal_led={1,1,0.5};
    else
        PoseFilter.landmark_cyan(v);
	goal_led={0,1,1};
    end
  else
    if vcm.get_goal_detect() == 0 then
      goal_led={0,0,0};
    end
  end

  ball.x, ball.y = ballFilter:get_xy();
  pose.x,pose.y,pose.a = PoseFilter.get_pose();

--Use team vision information when we cannot find the ball ourselves

  team_ball = wcm.get_robot_team_ball();
  team_ball_score = wcm.get_robot_team_ball_score();

  t=Body.get_time();
  if use_team_ball>0 and
    (t-tVisionBall)>team_ball_timeout and
    team_ball_score > team_ball_threshold then

    ballLocal = util.pose_relative(
	{team_ball[1],team_ball[2],0},{pose.x,pose.y,pose.a}); 
    ball.x = ballLocal[1];
    ball.y = ballLocal[2];
    ball.t = t;
    ball_led={0,1,1}; 
--print("TEAMBALL")
  end
  
  if led_on == 1 then
  	update_led();
  end
  update_shm();
end

function update_led()
  --Turn on the eye light according to team color
  --If gamecontroller is down
  if gcm.get_game_state()~=3 and
     gcm.get_game_gc_latency() > 10.0 then

    if gcm.get_team_color() == 0 then --Blue team
      Body.set_indicator_goal({0,0,0});
      Body.set_indicator_ball({0,0,1});
    else --Red team
      Body.set_indicator_goal({0,0,0});
      Body.set_indicator_ball({0,0,1});
    end
    return;
  end

  --Only disable eye LED during playing
--  if led_on>0 and gcm.get_game_state()~=3 then
  if led_on>0 then
    Body.set_indicator_goal(goal_led);
    Body.set_indicator_ball(ball_led);
  else
    Body.set_indicator_goal({0,0,0});
    Body.set_indicator_ball({0,0,0});
  end
end

function update_shm()
  -- update shm values
   --print("@@@updating shared memory")
  --print(string.format( 
  wcm.set_robot_pose({pose.x, pose.y, pose.a});
  wcm.set_robot_time(Body.get_time());

  wcm.set_ball_x(ball.x);
  wcm.set_ball_y(ball.y);
  if vcm.get_ball_detect()==1 then
  	ball_global = util.pose_global({ball.x,ball.y,0},{pose.x,pose.y,pose.a})
    
	if(ball_global~=nil) then
		wcm.set_ballGlobal_x(ball_global[1])
    	wcm.set_ballGlobal_y(ball_global[2])
    
	end
    if(ball_global==nil and (ball_global[1] == nil or ball_global[2] ==nil)) then
		wcm.set_ballGlobal_x(0);
		wcm.set_ballGlobal_y(0);
	end
  end
  wcm.set_ball_t(ball.t);
  wcm.set_ball_velx(ball.vx);
  wcm.set_ball_vely(ball.vy);
  wcm.set_ball_p(ball.p);

  wcm.set_goal_t(pose.tGoal);
  wcm.set_goal_attack(get_goal_attack());
  wcm.set_goal_defend(get_goal_defend());
  wcm.set_goal_attack_bearing(get_attack_bearing());
  wcm.set_goal_attack_angle(get_attack_angle());
  wcm.set_goal_defend_angle(get_defend_angle());

  wcm.set_goal_attack_post1(get_attack_posts()[1]);
  wcm.set_goal_attack_post2(get_attack_posts()[2]);

  wcm.set_robot_is_fall_down(mcm.get_walk_isFallDown());
  -- set the time that the robot fell.
  if wcm.get_robot_is_fall_down() == 1 then
  	wcm.set_horde_fallTime(Body.get_time());
  end
  --Particle information
  wcm.set_particle_x(PoseFilter.xp);
  wcm.set_particle_y(PoseFilter.yp);
  wcm.set_particle_a(PoseFilter.ap);
  wcm.set_particle_w(PoseFilter.wp);

end

function exit()
end


function get_ball()
  return ball;
end

function get_pose()
  return pose;
end

function zero_pose()
  PoseFilter.zero_pose();
end

function get_attack_bearing()
  return get_attack_bearing_pose(pose);
end

--Get attack bearing from pose0
function get_attack_bearing_pose(pose0)
  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    postAttack = PoseFilter.postCyan;
  else
    -- blue attack yellow goal
    postAttack = PoseFilter.postYellow;
  end
  -- make sure not to shoot back towards defensive goal:
  local xPose = math.min(math.max(pose0.x, -0.99*PoseFilter.xLineBoundary),
                          0.99*PoseFilter.xLineBoundary);
  local yPose = pose0.y;
  local aPost = {}
  aPost[1] = math.atan2(postAttack[1][2]-yPose, postAttack[1][1]-xPose);
  aPost[2] = math.atan2(postAttack[2][2]-yPose, postAttack[2][1]-xPose);
  local daPost = math.abs(PoseFilter.mod_angle(aPost[1]-aPost[2]));
  attackHeading = aPost[2] + .5*daPost;
  attackBearing = PoseFilter.mod_angle(attackHeading - pose0.a);

  return attackBearing, daPost;
end

function get_goal_attack()
  if gcm.get_team_color() == 1 then
    -- red attacks cyan goal
    return {PoseFilter.postCyan[1][1], 0, 0};
  else
    -- blue attack yellow goal
    return {PoseFilter.postYellow[1][1], 0, 0};
  end
end

function get_goal_defend()
  if gcm.get_team_color() == 1 then
    -- red defends yellow goal
    return {PoseFilter.postYellow[1][1], 0, 0};
  else
    -- blue defends cyan goal
    return {PoseFilter.postCyan[1][1], 0, 0};
  end
end

function get_attack_posts()
  if gcm.get_team_color() == 1 then
    return Config.world.postCyan;
  else
    return Config.world.postYellow;
  end
end

function get_attack_angle()
  goalAttack = get_goal_attack();

  dx = goalAttack[1] - pose.x;
  dy = goalAttack[2] - pose.y;
  return mod_angle(math.atan2(dy, dx) - pose.a);
end

function get_defend_angle()
  goalDefend = get_goal_defend();

  dx = goalDefend[1] - pose.x;
  dy = goalDefend[2] - pose.y;
  return mod_angle(math.atan2(dy, dx) - pose.a);
end

function get_team_color()
  return gcm.get_team_color();
end

function pose_global(pRelative, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  return vector.new{pose[1] + ca*pRelative[1] - sa*pRelative[2],
                    pose[2] + sa*pRelative[1] + ca*pRelative[2],
                    pose[3] + pRelative[3]};
end

function pose_relative(pGlobal, pose)
  local ca = math.cos(pose[3]);
  local sa = math.sin(pose[3]);
  local px = pGlobal[1]-pose[1];
  local py = pGlobal[2]-pose[2];
  local pa = pGlobal[3]-pose[3];
  return vector.new{ca*px + sa*py, -sa*px + ca*py, mod_angle(pa)};
end


