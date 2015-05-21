module(..., package.seeall);

require('shm');
require('util');
require('vector');
require('Config');

-- shared properties
shared = {};
shsize = {};

shared.robot = {};
shared.robot.pose = vector.zeros(3);
shared.robot.uTorso = vector.zeros(3);
shared.robot.battery_level = vector.zeros(1);
shared.robot.is_fall_down = vector.zeros(1);
shared.robot.time = vector.zeros(1);
shared.robot.penalty = vector.zeros(1);
shared.robot.gpspose = vector.zeros(3);
shared.robot.gps_attackbearing = vector.zeros(1);
shared.robot.gps_ball = vector.zeros(3);
shared.robot.odomScale = vector.zeros(3);

shared.robot.team_ball = vector.zeros(3);
shared.robot.team_ball_score = vector.zeros(1);

shared.robot.flipped = vector.zeros(1);
shared.robot.is_confused = vector.zeros(1);
shared.robot.t_confused = vector.zeros(1);

shared.ball = {};
shared.ball.x = vector.zeros(1);
shared.ball.y = vector.zeros(1);
shared.ball.t = vector.zeros(1);
shared.ball.velx = vector.zeros(1);
shared.ball.vely = vector.zeros(1);
shared.ball.dodge = vector.zeros(1);
shared.ball.locked_on = vector.zeros(1);
shared.ball.p = vector.zeros(1);

shared.ballGlobal = {};
shared.ballGlobal.x = vector.zeros(1);
shared.ballGlobal.y = vector.zeros(1);

shared.ball.v_inf = vector.zeros(2);
shared.ball.t_locked_on = vector.zeros(1);

--connection 
shared.horde = {};
shared.horde.walkVelocity = vector.zeros(3);
shared.horde.startGoalLine = vector.zeros(1); -- 1 (my particles on ready should start on goal line) 0 - start on the side as usual
shared.horde.safetySaysFlip = vector.zeros(1);
shared.horde.kickOutOfBounds = vector.zeros(1);
shared.horde.fallTime = vector.zeros(1);
shared.horde.visionPenalty = vector.zeros(1);
shared.horde.goalieCertainBallOnMySide = vector.zeros(1) -- 1 if the goalie has seen the ball on his side for >= 5s else 0
shared.horde.timeOut = vector.zeros(1);
shared.horde.toggle = vector.zeros(1);
shared.horde.playerID = vector.zeros(1);
shared.horde.pose = vector.zeros(3)
shared.horde.role = vector.zeros(1);
shared.horde.dummyTraining = vector.zeros(1);
shared.horde.moveParticlesToCenter = vector.zeros(1);
shared.horde.goalSign = vector.zeros(1); -- this is the sign of the defending goal posts
shared.horde.penaltyBoundsX = vector.zeros(1); -- defending goal side
shared.horde.penaltyBoundsY = vector.zeros(1); -- defending goal side
shared.horde.seeTwoPosts = vector.zeros(1);
shared.horde.canSeePost = vector.zeros(1);
shared.horde.client = "nil";
shared.horde.state = "nil";
shared.horde.sendStatus = "nil"
shared.horde.doneApproach = vector.zeros(1); ---
shared.horde.gotoPose = vector.zeros(3); -- the x,y,a that horde told it to go to on the field in the world frame
shared.horde.ballLost = vector.zeros(1);
shared.horde.sentBehavior = vector.zeros(1)
shared.horde.ackNumber = vector.zeros(1);
shared.horde.facing = vector.zeros(3);
shared.horde.kickToPose = vector.zeros(3);
shared.horde.doneKick = vector.zeros(1);
--horizontally passed+connection
shared.horde.yelledReady = vector.zeros(1);
shared.horde.yelledKick = vector.zeros(1);
shared.horde.yelledFail = vector.zeros(1);
shared.horde.timeMark = vector.zeros(1);
shared.horde.kickToPose = vector.zeros(3);
-- x,y location between ball (as seen by bot closest to the ball) and the goal post furthest from the ball.
shared.horde.midpointBallGoal = vector.zeros(2);
-- 0 = i am closest
-- 1 = i am second closest and within N
-- 2 = i am second closest
-- 3 = i am third closest and within N
-- 4 = i am third closest
shared.horde.status = vector.zeros(1) -- 0 - 5  
shared.horde.goalieCloseEnough = vector.zeros(1); -- 0 if not close enough 1 if close enough

--[1] declare kiddie, [2] declare support, [3] declare safety
shared.horde.doDeclare = vector.zeros(3); -- whether I am declaring

shared.horde.declared = vector.zeros(3); -- if somebody has declared 0 if not declared 1 if declared


shared.horde.goalCloseDist = vector.ones(1) -- should change this is a place holder.
shared.horde.distN = vector.ones(1) -- within a meter?
shared.horde.confused = vector.zeros(1);

shsize.horde = 2^16;

--shared.horde.robot1 = "10.0.0.51"
--shared.horde.poseRobot1 = vector.zeros(3);--purely horizontally passed
-- wcm.get_horde_doneFrontApproach();
shared.team = {};
shared.team.connected = vector.zeros(1)
shared.team.teamPoseX = vector.zeros(4)
shared.team.teamPoseY = vector.zeros(4)
shared.team.teamPoseA = vector.zeros(4)
shared.team.is_smallest_eta = vector.zeros(1);-- 1 if I have the smallest eta 0 otherwise
shared.team.my_eta = vector.zeros(1);
shared.team.attacker_eta = vector.zeros(1);
shared.team.defender_eta = vector.zeros(1);
shared.team.defender2_eta = vector.zeros(1);
shared.team.supporter_eta = vector.zeros(1);
shared.team.goalie_alive = vector.zeros(1);

shared.team.attacker_pose = vector.zeros(3);
shared.team.defender_pose = vector.zeros(3);
shared.team.defender2_pose = vector.zeros(3);
shared.team.supporter_pose = vector.zeros(3);
shared.team.goalie_pose = vector.zeros(3);

shared.team.yelledReady = vector.zeros(4);-- for each
shared.team.yelledKick = vector.zeros(4);
shared.team.closestToBallLoc = vector.zeros(3); -- global location of the ball as seen by the closest robot
shared.team.isClosestToGoalDefend = vector.zeros(1); -- are you the closest to the defending goal 
shared.team.isClosestToGoalOffend = vector.zeros(1); -- are you the closest to the goal you are attacking


shared.goal = {};
shared.goal.t = vector.zeros(1);
shared.goal.attack = vector.zeros(3);
shared.goal.defend = vector.zeros(3);
shared.goal.attack_bearing = vector.zeros(1);
shared.goal.attack_angle = vector.zeros(1);
shared.goal.defend_angle = vector.zeros(1);
shared.goal.attack_post1 = vector.zeros(2);
shared.goal.attack_post2 = vector.zeros(2);


shared.goal.attack_angle2 = vector.zeros(1);
shared.goal.daPost2 = vector.zeros(1);


--Added for side approach/sidekick/kickoff handling
shared.kick = {};
shared.kick.dir=vector.zeros(1);
shared.kick.angle=vector.zeros(1);
shared.kick.type=vector.zeros(1);
shared.kick.kickOff = vector.zeros(1);
shared.kick.tKickOff = vector.zeros(1);

--Added for obstacle avoidance for webots
shared.obstacle = {};
shared.obstacle.num = vector.zeros(1);
shared.obstacle.x = vector.zeros(10);
shared.obstacle.y = vector.zeros(10);
shared.obstacle.dist = vector.zeros(10);
shared.obstacle.role = vector.zeros(10);

--Localization monitoring
shared.particle = {};
shared.particle.x=vector.zeros(Config.world.n);
shared.particle.y=vector.zeros(Config.world.n);
shared.particle.a=vector.zeros(Config.world.n);
shared.particle.w=vector.zeros(Config.world.n);

-- Sound localization
shared.sound = {};
shared.sound.odomPose = vector.zeros(3);
-- TODO: sound histogram filter size should be set in the config
--shared.sound.histogram = vector.zeros(Config.sound.??);
radPerBin = 30*math.pi/180;
shared.sound.detFilter = vector.zeros(math.floor(2*math.pi/radPerBin));
shared.sound.detCount = vector.zeros(1);
shared.sound.detTime = vector.zeros(1);
shared.sound.detLIndex = vector.zeros(1);
shared.sound.detRIndex = vector.zeros(1);

-----------------------------------------------
-- This shm is used for wireless team monitoring only
-- Indexed by player ID + teamOffset 
-----------------------------------------------
listen_monitor = Config.listen_monitor or 0;

if listen_monitor>0 then
  shared.teamdata={};
  shared.teamdata.teamnum=vector.zeros(1);
  shared.teamdata.teamColor=vector.zeros(10);
  shared.teamdata.robotId=vector.zeros(10);
  shared.teamdata.role=vector.zeros(10);
  shared.teamdata.time=vector.zeros(10);
  --Latency information
  shared.teamdata.gclatency=vector.zeros(10);
  shared.teamdata.tmlatency=vector.zeros(10);


  shared.teamdata.posex=vector.zeros(10);
  shared.teamdata.posey=vector.zeros(10);
  shared.teamdata.posea=vector.zeros(10);

  shared.teamdata.ballx=vector.zeros(10);
  shared.teamdata.bally=vector.zeros(10);
  shared.teamdata.ballt=vector.zeros(10);
  shared.teamdata.ballvx=vector.zeros(10);
  shared.teamdata.ballvy=vector.zeros(10);

  shared.teamdata.attackBearing=vector.zeros(10);
  shared.teamdata.fall=vector.zeros(10);
  shared.teamdata.penalty=vector.zeros(10);
  shared.teamdata.battery_level=vector.zeros(10);

  shared.teamdata.goal=vector.zeros(10);
  shared.teamdata.goalv11=vector.zeros(10);
  shared.teamdata.goalv12=vector.zeros(10);
  shared.teamdata.goalv21=vector.zeros(10);
  shared.teamdata.goalv22=vector.zeros(10);

  shared.teamdata.goalB11=vector.zeros(10);
  shared.teamdata.goalB12=vector.zeros(10);
  shared.teamdata.goalB13=vector.zeros(10);
  shared.teamdata.goalB14=vector.zeros(10);
  shared.teamdata.goalB15=vector.zeros(10);

  shared.teamdata.goalB21=vector.zeros(10);
  shared.teamdata.goalB22=vector.zeros(10);
  shared.teamdata.goalB23=vector.zeros(10);
  shared.teamdata.goalB24=vector.zeros(10);
  shared.teamdata.goalB25=vector.zeros(10);

  shared.teamdata.landmark=vector.zeros(10);
  shared.teamdata.landmarkv1=vector.zeros(10);
  shared.teamdata.landmarkv2=vector.zeros(10);
  
  
  shared.teamdata.penaltyLocation = vector.zeros(1); -- y location

--Team LabelB monitoring

  processed_img_width = Config.camera.width;
  processed_img_height = Config.camera.height;
  processed_img_width = processed_img_width / 2;
  processed_img_height = processed_img_height / 2;
 
  labelB_size =  ((processed_img_width/Config.vision.scaleB)*
     (processed_img_height/Config.vision.scaleB));

  shared.labelB = {};
  shared.labelB.p1 = labelB_size;
  shared.labelB.p2 = labelB_size;
  shared.labelB.p3 = labelB_size;
  shared.labelB.p4 = labelB_size;
  shared.labelB.p5 = labelB_size;
  shared.labelB.p6 = labelB_size;
  shared.labelB.p7 = labelB_size;
  shared.labelB.p8 = labelB_size;
  shared.labelB.p9 = labelB_size;
  shared.labelB.p10 = labelB_size;
  shsize.labelB = 10*labelB_size + 2^16;

  shared.robotNames = {};
  shared.robotNames.n1 = '';
  shared.robotNames.n2 = '';
  shared.robotNames.n3 = '';
  shared.robotNames.n4 = '';
  shared.robotNames.n5 = '';
  shared.robotNames.n6 = '';
  shared.robotNames.n7 = '';
  shared.robotNames.n8 = '';
  shared.robotNames.n9 = '';
  shared.robotNames.n10 = '';

  shared.bodyStates = {};
  shared.bodyStates.n1 = '';
  shared.bodyStates.n2 = '';
  shared.bodyStates.n3 = '';
  shared.bodyStates.n4 = '';
  shared.bodyStates.n5 = '';
  shared.bodyStates.n6 = '';
  shared.bodyStates.n7 = '';
  shared.bodyStates.n8 = '';
  shared.bodyStates.n9 = '';
  shared.bodyStates.n10 = '';

end

util.init_shm_segment(getfenv(), _NAME, shared, shsize);


-- helper functions for access the data in the same manner as World

function get_ball()
  return {x=get_ball_x(), y=get_ball_y(), 
	vx=get_ball_velx(), vy=get_ball_vely(), 
	t=get_ball_t(),	p=get_ball_p()};
end

function get_pose()
  pose = get_robot_pose();
  return {x=pose[1], y=pose[2], a=pose[3]};
end

function get_tGoal()
  return get_goal_t();
end

function get_attack_bearing()
  return get_goal_attack_bearing();
end

function get_attack_angle()
  return get_goal_attack_angle();
end

function get_defend_angle()
  return get_goal_defend_angle();
end

function get_sound_detection()
   return {count = get_sound_detCount(),
           time = get_sound_detTime(),
           lIndex = get_sound_detLIndex(),
           rIndex = get_sound_detRIndex()};
end
