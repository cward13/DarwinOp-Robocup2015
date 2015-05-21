module(..., package.seeall);

require('Body')
require('HeadTransform')
require('Config')
require('wcm')

t0 = 0;

minDist = Config.fsm.headTrack.minDist;
fixTh = Config.fsm.headTrack.fixTh;
trackZ = Config.vision.ball_diameter; 
timeout = Config.fsm.headTrack.timeout;
tLost = Config.fsm.headTrack.tLost;

min_eta_look = Config.min_eta_look or 2.0;


goalie_dive = Config.goalie_dive or 0;
goalie_type = Config.fsm.goalie_type;


function entry()
  print("Head SM:".._NAME.." entry");

  t0 = Body.get_time();
  vcm.set_camera_command(-1); --switch camera
  alreadyPrinted = false;
end
alreadyPrinted = false;
function update()

  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();
  ballR = math.sqrt (ball.x^2 + ball.y^2);

  local yaw,pitch;
  --top:0 bottom: 1
  
  --OP: look at the ball
  yaw, pitch =
	HeadTransform.ikineCam(ball.x, ball.y, trackZ, 0);

  

  -- Fix head yaw while approaching (to reduce position error)
  if ball.x<fixTh[1] and math.abs(ball.y) < fixTh[2] then
     yaw=0.0; 
  end
  Body.set_head_command({yaw, pitch});

   if (t - ball.t > .5) then
    print('Ball lost!');
    return "ballLost";
    --alreadyPrinted = true;
  end
   --if(Config.game.role == 0) then
--	return "timeout"
 --  end
  if (t - t0 > timeout) then
       		--return "timeout";  --Player, look up to see goalpost
  end
end

function exit()
end
