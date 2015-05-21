module(..., package.seeall);

require('Body')
require('keyframe')
require('unix')
require('Config');
require('walk');
require('wcm')
require('vcm')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion/keyframes"

keyframe.load_motion_file(cwd.."/".. "chau_test.lua",
                          "chau_test");

batt_max = Config.batt_max or 10;

function entry()
  print(_NAME.." entry");

  keyframe.entry();
  Body.set_body_hardness(1);
  
  print("chau_test");
  keyframe.do_motion("chau_test");

end

function update()
  keyframe.update();
 
  if (keyframe.get_queue_len() == 0) then
    local imuAngle = Body.get_sensor_imuAngle();
    local maxImuAngle = math.max(math.abs(imuAngle[1]),
                        math.abs(imuAngle[2]));
    if (maxImuAngle > 40*math.pi/180) then
      return "fail";
    else
        --Set velocity to 0 to prevent falling--
    --    walk.still=true;
--        walk.set_velocity(0, 0, 0); 
--        walk.keep_holding_high();

      Config.walk.qLArm = math.pi/180*vector.new({-85,-15,-20});
      Config.walk.qRArm = math.pi/180*vector.new({-85,15,-20});
      Config.walk.bodyTilt = 10*math.pi/180;
      return "done";
    end
  end
end

function exit()
  keyframe.exit();
end
