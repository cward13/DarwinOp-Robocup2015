module(... or "", package.seeall);

package.path = './Lib/?.lua;' .. package.path
package.cpath = './Vision/?.so;' .. package.cpath
package.path = './Vision/?.lua;' .. package.path
package.path = './Util/?.lua;' .. package.path
package.cpath = './Lib/?.so;' .. package.cpath
package.path = './Config/Camera/?.lua;' .. package.path
package.path = './Config/?.lua;' .. package.path
package.path = './Dev/?.lua;' .. package.path
-- start stupid
cwd = '.'
package.path = cwd .. '/Util/?.lua;' .. package.path;
package.path = cwd .. '/Config/?.lua;' .. package.path;
package.path = cwd .. '/Lib/?.lua;' .. package.path;
package.path = cwd .. '/Dev/?.lua;' .. package.path;
package.path = cwd .. '/Motion/?.lua;' .. package.path;
package.path = cwd .. '/Motion/keyframes/?.lua;' .. package.path;
package.path = cwd .. '/Motion/Walk/?.lua;' .. package.path;
package.path = cwd .. '/Vision/?.lua;' .. package.path;
package.path = cwd .. '/World/?.lua;' .. package.path;

require('unix')
require('Config')
require('shm')
require('vector')
require('vcm')
require('gcm')
require('wcm')
require('mcm')
require('Speak')
require('getch')
require('Body')
require('Motion')
-- end stupid

require('unix')
require('carray');
require('vector');
require('Config');
-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = 1;
end

require('ImageProc');
require('HeadTransform');

require('vcm');
require('mcm');
require('Body')

se_gps_only = Config.use_gps_only or 0;

 require('ColorLUT'); --This will turn on camera and slow things down!
 require('Camera');
 require('Detection');
 function camera_init()
  for c=1,Config.camera.ncamera do 
    Camera.select_camera(c-1);
    for i,auto_param in ipairs(Config.camera.auto_param) do
      print('Camera '..c..': setting '..auto_param.key..': '..auto_param.val[c]);
      Camera.set_param(auto_param.key, auto_param.val[c]);
      unix.usleep(100000);
      print('Camera '..c..': set to '..auto_param.key..': '..Camera.get_param(auto_param.key));
    end   
    for i,param in ipairs(Config.camera.param) do
      print('Camera '..c..': setting '..param.key..': '..param.val[c]);
      Camera.set_param(param.key, param.val[c]);
      unix.usleep(10000);
      print('Camera '..c..': set to '..param.key..': '..Camera.get_param(param.key));
    end
  end
 end


 --UPENN checks
  if (Config.camera.width ~= Camera.get_width()
      or Config.camera.height ~= Camera.get_height()) then
    print('Camera width/height mismatch');
    print('Config width/height = ('..Config.camera.width..', '..Config.camera.height..')');
    print('Camera width/height = ('..Camera.get_width()..', '..Camera.get_height()..')');
    error('Config file is not set correctly for this camera. Ensure the camera width and height are correct.');
  end
  vcm.set_image_width(Config.camera.width);
  vcm.set_image_height(Config.camera.height);
--[[  --Grab some images (GMU)
  camera_init();
  myImageArray = {}
  for count = 1,3 do	
	print("image #" .. count);
	myImageArray[count] = Camera.get_image();
  	unix.usleep(1.0 * 1E6);
  end
  print("saving")
  for count = 1,3 do
	print("saving file " .. count .. "image.yuyv");  
	Camera.save_image(myImageArray[count]);	
	--file = io.open(count .. "image.yuyv","wb")
  	--file:write(myImageArray[count] ) 
	--file:close();
  end
  print("done saving");
-- Initialize the Labeling--]] --old grabbing, can delete section if we can already save images

--new gmu section, c file saving
camera_init();
--[[Camera.stop();
Camera.small_init();
Camera.stream_on();
--]]
Camera.take_save_images();

-- Timing
count = 0;
lastImageCount = {0,0};
t0 = unix.time()

function entry()
  --Temporary value.. updated at body FSM at next frame
end



function update()

  --If we are only using gps info, skip whole vision update 	
  -- reload color lut
  -- get image from camera
  camera.image = Camera.get_image();

  local status = Camera.get_camera_status();
  if status.count ~= lastImageCount[status.select+1] then
    lastImageCount[status.select+1] = status.count;
  else
    return false; 
  end

  -- switch camera
  local cmd = vcm.get_camera_command();
  if (cmd == -1) then
    if (count % camera.switchFreq == 0) then
       Camera.select_camera(1-Camera.get_select()); 
    end
  else
    if (cmd >= 0 and cmd < camera.ncamera) then
      Camera.select_camera(cmd);
    else
--      print('WARNING: attempting to switch to unkown camera select = '..cmd);
    end
  end

  return true;
end




