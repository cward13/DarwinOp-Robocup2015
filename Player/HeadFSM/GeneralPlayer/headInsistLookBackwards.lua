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
function update()
  if(Body.get_time()-t0 > 3) then
	if(wcm.get_pose().a < 0) then
        	yawMax = -1*math.abs(yawMax);
	else
		yawMax = math.abs(yawMax);
	end
  	t0 = Body.get_time();
  end
  local pitch = -27*math.pi/180;-- 22 is MAX DONOT GO HIGH (thank you chau)
  Body.set_head_command({yawMax, pitch});
end

function exit()
end
