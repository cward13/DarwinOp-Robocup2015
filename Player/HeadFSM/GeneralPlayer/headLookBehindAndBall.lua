module(..., package.seeall);

require('Body')
require('vcm')
require('mcm')

t0 = 0;
timeout = 1.0;

function entry()
  pitchBias =  mcm.get_headPitchBias();--robot specific head bias

  print(_NAME.." entry");

  t0 = Body.get_time();

  -- set head to default position
  local yaw = Config.head.yawMax;
  local pitch =  27*math.pi/180;-- 22 is MAX DONOT GO HIGH (thank you chau)
  Body.set_head_command({yaw, pitch});

  -- continuously switch cameras
  vcm.set_camera_command(-1);
end
yawMax = Config.head.yawMax;
lookBall = false
function update()
  if(Body.get_time()-t0 > 3) then
	if lookBall then -- only switch which shoulder we look over after we've looked at a ball
	        if(wcm.get_pose().a < 0) then
        	        yawMax = -1*math.abs(yawMax);
	        else
               		yawMax = math.abs(yawMax);
        	end
	
  	end
	lookBall = (not lookBall)
	if(lookBall) then
		print("HEAD: look at ball");
	else
		print("HEAD: look over shoulder");
	end
	t0 = Body.get_time();
  end
  pitch = -27*math.pi/180;-- 22 is MAX DONOT GO HIGH (thank you chau)
  yaw = yawMax;
  if lookBall then
	ballGlobal= {};
        ballGlobal.x = wcm.get_ballGlobal_x();
        ballGlobal.y = wcm.get_ballGlobal_y();
	pose = wcm.get_pose();
	ballRelative  = util.pose_relative({ballGlobal.x, ballGlobal.y, 0}, {pose.x, pose.y, pose.a});
	ballx = ballRelative[1];
  	bally = ballRelative[2];

	yaw, pitch =
        HeadTransform.ikineCam(ballx, bally, .1, 0);
  end
  Body.set_head_command({yaw, pitch});
end

function exit()
end
