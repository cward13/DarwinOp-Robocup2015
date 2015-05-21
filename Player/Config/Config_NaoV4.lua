module(..., package.seeall);
local unix = require 'unix'
require('vector')
require('parse_hostname')

--Robot CFG should be loaded first to set PID values
local robotName=unix.gethostname();

platform = {};
platform.name = 'NaoV4'

listen_monitor=1
-- Game Parameters
-- init game table first since fsm need it
game = {};

-- Parameters Files
params = {}
params.name = {"Walk", "World", "Kick", "Vision", "FSM", "Camera","Robot"};

---Location Specific Camera Parameters--
params.Camera = "Demo"

params.Walk = "Demo"

params.World = "Demo"

util.LoadConfig(params, platform)

game.teamNumber = 22;
game.robotName = robotName;
--game.playerID = parse_hostname.get_player_id();
game.playerID = 1;
--zero means this is not a robot
--------Setting Player ID's----------
if (robotName=='tink') then
  game.playerID = 1;
elseif (robotName=='ruffio') then
  game.playerID = 2;
elseif (robotName=='ticktock') then
  game.playerID = 3;
elseif (robotName=='hook') then
  game.playerID = 4;
elseif (robotName=='pockets') then
  game.playerID = 5;
end
--------------------------------------

game.robotID = game.playerID;
game.teamColor = parse_hostname.get_team_color();
game.role = game.playerID-1; -- 0 for goalie
game.nPlayers = 5;

-- Devive Interface Libraries
dev = {};
dev.body = 'NaoBody'; 
dev.camera = 'NaoCam';
dev.kinematics = 'NaoKinematics';
dev.ip_wired = '192.168.123.255';
dev.ip_wired_port = 111111;
dev.ip_wireless = '10.0.22.255';
dev.ip_wireless_port = 10220
dev.game_control = 'NaoGameControl';
dev.team='TeamGeneral';
dev.walk = 'CleanWalk';

dev.kick = 'Walk/BasicKick';

--Speak enable
speakenable = 1;


-- FSM Parameters
fsm.body = {'GeneralPlayer'};
fsm.head = {'GeneralPlayer'};

-- Team Parameters
--[[
team = {};
team.msgTimeout = 5.0;
team.nonAttackerPenalty = 6.0; -- eta sec
team.nonDefenderPenalty = 0.5; -- dist from goal
team.twoDefenders = 0;
--]]

--NEW Team parameters for TeamGeneral
team = {};
team.msgTimeout = 5.0;
team.tKickOffWear =7.0;
team.walkSpeed = 0.25; --Average walking speed 
team.turnSpeed = 2.0; --Average turning time for 360 deg
team.ballLostPenalty = 4.0; --ETA penalty per ball loss time
team.fallDownPenalty = 4.0; --ETA penalty per ball loss time
team.nonAttackerPenalty = 0.8; -- distance penalty from ball
team.nonDefenderPenalty = 0.5; -- distance penalty from goal
team.force_defender = 0;--Enable this to force defender mode
team.test_teamplay = 0; --Enable this to immobilize attacker to test team beha$

--if ball is away than this from our goal, go support
team.support_dist = 3.0; 
team.supportPenalty = 0.5; --dist from goal
team.use_team_ball = 1;
team.team_ball_timeout = 3.0;  --use team ball info after this delay
team.team_ball_threshold = 0.5;
team.avoid_own_team = 0;
team.avoid_other_team = 0;

team.flip_correction = 0;

-- keyframe files
km = {};
km.standup_front = 'km_NaoV4_StandupFromFront.lua';
km.standup_back = 'km_NaoV4_StandupFromBack.lua';
km.time_to_stand = 30; -- average time it takes to stand up in seconds

--vision.ball.max_distance = 2.5; --temporary fix for GRASP lab
vision.ball.fieldsize_factor = 1.2; --check whether the ball is inside the field
vision.ball.max_distance = 2; --if ball is this close, just pass the test

--Should we use ultrasound?
team.avoid_ultrasound = 1;


use_kalman_velocity = 0;

team.flip_threshold_x = 2.5;
team.flip_threshold_y =2.5;

team.vision_send_interval = 10
