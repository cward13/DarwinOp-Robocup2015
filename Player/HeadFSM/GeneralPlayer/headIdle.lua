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
  local yaw = 0;
  local pitch =-30*math.pi/180;-- 22 is MAX DONOT GO HIGH (thank you chau)
  Body.set_head_command({yaw, pitch});

  -- continuously switch cameras
  vcm.set_camera_command(-1);
end

function update()
local pitch = -30*math.pi/180;-- 22 is MAX DONOT GO HIGH (thank you chau)
  Body.set_head_command({yaw, pitch});
end

function exit()
end
