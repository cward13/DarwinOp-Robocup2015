module(..., package.seeall);

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

--Added for webots fast simulation
use_gps_only = Config.use_gps_only or 0;

if use_gps_only==0 then
  require('ColorLUT'); --This will turn on camera and slow things down!
  require('Camera');
  require('Detection');
  
  if (Config.camera.width ~= Camera.get_width()
      or Config.camera.height ~= Camera.get_height()) then
    print('Camera width/height mismatch');
    print('Config width/height = ('..Config.camera.width..', '..Config.camera.height..')');
    print('Camera width/height = ('..Camera.get_width()..', '..Camera.get_height()..')');
    error('Config file is not set correctly for this camera. Ensure the camera width and height are correct.');
  end
  vcm.set_image_width(Config.camera.width);
  vcm.set_image_height(Config.camera.height);
  
  camera = {};
  
  camera.width = Camera.get_width();
  camera.height = Camera.get_height();
  camera.npixel = camera.width*camera.height;
  camera.image = Camera.get_image();
  camera.status = Camera.get_camera_status();
  camera.switchFreq = Config.camera.switchFreq;
  camera.ncamera = Config.camera.ncamera;
  -- Initialize the Labeling
  labelA = {};
  labelA.m = camera.width / Config.vision.scaleA
  labelA.n = camera.height / Config.vision.scaleA
  labelA.npixel = labelA.m*labelA.n;
  vcm.set_image_scaleA(Config.vision.scaleA);
  scaleB = Config.vision.scaleB;
  labelB = {};
  labelB.m = labelA.m/scaleB;
  labelB.n = labelA.n/scaleB;
  labelB.npixel = labelB.m*labelB.n;
  vcm.set_image_scaleB(Config.vision.scaleB);
  print('Vision LabelA size: ('..labelA.m..', '..labelA.n..')');
  print('Vision LabelB size: ('..labelB.m..', '..labelB.n..')');
end

colorOrange = Config.color.orange;
colorYellow = Config.color.yellow;
colorCyan = Config.color.cyan;
colorField = Config.color.field;
colorWhite = Config.color.white;

yellowGoalCountThres = Config.vision.yellow_goal_count_thres;

saveCount = 0;

use_point_goal = Config.vision.use_point_goal or 0;
subsampling = Config.vision.subsampling or 0;
subsampling2 = Config.vision.subsampling2 or 0;

-- debugging settings
vcm.set_debug_enable_shm_copy(Config.vision.copy_image_to_shm);
vcm.set_debug_store_goal_detections(Config.vision.store_goal_detections);
vcm.set_debug_store_ball_detections(Config.vision.store_ball_detections);
vcm.set_debug_store_all_images(Config.vision.store_all_images);

-- Timing
count = 0;
lastImageCount = {0,0};
t0 = unix.time()

function entry()
  --Temporary value.. updated at body FSM at next frame
  vcm.set_camera_bodyHeight(Config.walk.bodyHeight);
  vcm.set_camera_bodyTilt(0);
  vcm.set_camera_height(Config.walk.bodyHeight+Config.head.neckZ);
	vcm.set_camera_ncamera(Config.camera.ncamera);
  vcm.set_camera_reload_LUT(0);
  vcm.set_camera_lut_filename(Config.camera.lut_file);

  --turn on camera switching at beginning
  vcm.set_camera_command(-1);
  -- Start the HeadTransform machine
  HeadTransform.entry();

  --If we are only using gps info, skip camera init 	
  if use_gps_only>0 then
    return;
  end

  -- Initiate Detection
  Detection.entry();
  
  -- Load the lookup table
  ColorLUT.load_LUT();

  if Config.platform.name=="NaoV4" then
    camera_init_naov4();
  else
    camera_init();
  end 

end

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

function camera_init_naov4()
  for c=1,Config.camera.ncamera do
    Camera.select_camera(c-1);   
    Camera.set_param('Brightness', Config.camera.brightness);     
    Camera.set_param('White Balance, Automatic', 0);
    Camera.set_param('Auto Exposure',0);
    Camera.set_param('Auto Exposure Algorithm', 3)
    Camera.set_param('Fade to Black', 0)
    for i,param in ipairs(Config.camera.param) do
        Camera.set_param(param.key, param.val[c]);
        unix.usleep (100);
    end
    local expo = Camera.get_param('Exposure');
    local gain = Camera.get_param('Gain');
    Camera.set_param('Auto Exposure',1);   
    Camera.set_param('Auto Exposure',0);
    Camera.set_param('Exposure', expo)
    Camera.set_param('Gain', gain);
    print('Camera #'..c..' set');
  end
end


function update()

  --If we are only using gps info, skip whole vision update 	
  if use_gps_only>0 then
    update_gps_only();
    return true;
  end

  -- reload color lut
  if (vcm.get_camera_reload_LUT() == 1) then
    print('reload color LUT')
    camera = ColorLUT.load_LUT(camera);
    vcm.set_camera_reload_LUT(0);
  end

  tstart = unix.time();

  -- get image from camera
  camera.image = Camera.get_image();

  local status = Camera.get_camera_status();
  if status.count ~= lastImageCount[status.select+1] then
    lastImageCount[status.select+1] = status.count;
  else
    return false; 
  end

--SJ: Camera image keeps changing
--So copy it here to shm, and use it for all vision process
  vcm.set_image_yuyv(camera.image);

  -- Add timer measurements
  count = count + 1;

  headAngles = Body.get_head_position();
  HeadTransform.update(status.select, headAngles);

  if camera.image == -2 then
    print "Re-enqueuing of a buffer error...";
    exit()
  end
  
  -- perform the initial labeling
  labelA.data  = ImageProc.yuyv_to_label(vcm.get_image_yuyv(),
                                        vcm.get_image_lut(),
                                        camera.width,
                                        camera.height,
                                        Config.vision.scaleA);

  -- determine total number of pixels of each color/label
  colorCount = ImageProc.color_count(labelA.data, labelA.npixel);

  -- bit-or the segmented image
  labelB.data = ImageProc.block_bitor(labelA.data, labelA.m, labelA.n, scaleB, scaleB);

  update_shm(status, headAngles)

  vcm.refresh_debug_message();

  Detection.update();
  vcm.refresh_debug_message();

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

function update_shm_fov()
  --This function projects the boundary of current labeled image

  local fovC={Config.camera.width/2,Config.camera.height/2};
  local fovBL={0,Config.camera.height};
  local fovBR={Config.camera.width,Config.camera.height};
  local fovTL={0,0};
  local fovTR={Config.camera.width,0};

  vcm.set_image_fovC(vector.slice(HeadTransform.projectGround(
 	  HeadTransform.coordinatesA(fovC,0.1)),1,2));
  vcm.set_image_fovTL(vector.slice(HeadTransform.projectGround(
 	  HeadTransform.coordinatesA(fovTL,0.1)),1,2));
  vcm.set_image_fovTR(vector.slice(HeadTransform.projectGround(
 	  HeadTransform.coordinatesA(fovTR,0.1)),1,2));
  vcm.set_image_fovBL(vector.slice(HeadTransform.projectGround(
 	  HeadTransform.coordinatesA(fovBL,0.1)),1,2));
  vcm.set_image_fovBR(vector.slice(HeadTransform.projectGround(
 	  HeadTransform.coordinatesA(fovBR,0.1)),1,2));
end

function update_shm(status, headAngles)
  -- Update the shared memory
  -- Shared memory size argument is in number of bytes

  if vcm.get_debug_enable_shm_copy() == 1 then
    if ((vcm.get_debug_store_all_images() == 1)
        or (ball.detect == 1 and vcm.get_debug_store_ball_detections() == 1)
        or ((goalCyan.detect == 1 or goalYellow.detect == 1) 
            and vcm.get_debug_store_goal_detections() == 1)) then
      if webots == 1  then
        vcm.set_camera_yuyvType(1);
        vcm.set_image_labelA(labelA.data);
        vcm.set_image_labelB(labelB.data);
	    end
      if vcm.get_camera_broadcast() > 0 then --Wired monitor broadcasting
	      if vcm.get_camera_broadcast() == 1 then
	        --Level 1: 1/4 yuyv, labelB
          vcm.set_image_yuyv3(ImageProc.subsample_yuyv2yuyv(vcm.get_image_yuyv(),
	                                              camera.width/2, camera.height,4));
          vcm.set_image_labelB(labelB.data);
	      elseif vcm.get_camera_broadcast() == 2 then
	        --Level 2: 1/2 yuyv, labelA, labelB
          vcm.set_image_yuyv2(ImageProc.subsample_yuyv2yuyv(vcm.get_image_yuyv(),
  	                                            camera.width/2, camera.height,2));
          vcm.set_image_labelA(labelA.data);
          vcm.set_image_labelB(labelB.data);
	      else
	        --Level 3: 1/2 yuyv
          vcm.set_image_yuyv2(ImageProc.subsample_yuyv2yuyv(
  	      vcm.get_image_yuyv(),
  	      camera.width/2, camera.height,2));
	      end
	    elseif vcm.get_camera_teambroadcast() > 0 then --Wireless Team broadcasting
        --Only copy labelB
        vcm.set_image_labelB(labelB.data);
      end
    end
  end

  vcm.set_image_select(status.select);
  vcm.set_image_count(status.count);
  vcm.set_image_time(status.time);
  vcm.set_image_headAngles(headAngles);
  vcm.set_image_horizonA(HeadTransform.get_horizonA());
  vcm.set_image_horizonB(HeadTransform.get_horizonB());
  vcm.set_image_horizonDir(HeadTransform.get_horizonDir())

  update_shm_fov();
end

function exit()
  HeadTransform.exit();
end

function bboxStats(color, bboxB, rollAngle, scale)
  scale = scale or scaleB;
  bboxA = {};
  bboxA[1] = scale*bboxB[1];
  bboxA[2] = scale*bboxB[2] + scale - 1;
  bboxA[3] = scale*bboxB[3];
  bboxA[4] = scale*bboxB[4] + scale - 1;
  if rollAngle then
 --hack: shift boundingbox 1 pix helps goal detection
 --not sure why this thing is happening...

--    bboxA[1]=bboxA[1]+1;
      bboxA[2]=bboxA[2]+1;

    return ImageProc.tilted_color_stats(
	labelA.data, labelA.m, labelA.n, color, bboxA,rollAngle);
  else
    return ImageProc.color_stats(labelA.data, labelA.m, labelA.n, color, bboxA);
  end
end

function bboxB2A(bboxB)
  bboxA = {};
  bboxA[1] = scaleB*bboxB[1];
  bboxA[2] = scaleB*bboxB[2] + scaleB - 1;
  bboxA[3] = scaleB*bboxB[3];
  bboxA[4] = scaleB*bboxB[4] + scaleB - 1;
  return bboxA;
end

function bboxArea(bbox)
  return (bbox[2] - bbox[1] + 1) * (bbox[4] - bbox[3] + 1);
end




--Update relative ball position based on absolute position

function update_gps_only()
  --We are now using ground truth robot and ball pose data
  headAngles = Body.get_head_position();
  --TODO: camera select
--  HeadTransform.update(status.select, headAngles);
  HeadTransform.update(0, headAngles);
  
  --update FOV
  update_shm_fov()

  --Get GPS coordinate of robot and ball
  gps_pose = wcm.get_robot_gpspose();
  ballGlobal=wcm.get_robot_gps_ball();  
  


  --Check whether ball is inside FOV
  ballLocal = util.pose_relative(ballGlobal,gps_pose);
 
  --Get the coordinates of FOV boundary
  local v_TL = vcm.get_image_fovTL();
  local v_TR = vcm.get_image_fovTR();
  local v_BL = vcm.get_image_fovBL();
  local v_BR = vcm.get_image_fovBR();

--[[
print("BallLocal:",unpack(ballLocal))
print("V_TL:",unpack(v_TL))
print("V_TR:",unpack(v_TR))
print("V_BL:",unpack(v_BL))
print("V_BR:",unpack(v_BR))
print("Top check:",
   check_side(v_TL, ballLocal, v_TR));
print("Left check:",
     check_side(v_TL, v_BL, ballLocal) );
print("Right check:",
     check_side(v_BR, v_TR, ballLocal) );
print("Bottom check:",
     check_side(v_BL, v_BR, ballLocal) );
--]]

 --Check whether ball is within FOV boundary 
  if check_side(v_TR, v_TL, ballLocal) < 0 and
     check_side(v_TL, v_BL, ballLocal) < 0 and
     check_side(v_BR, v_TR, ballLocal) < 0 and
     check_side(v_BL, v_BR, ballLocal) < 0 then
    vcm.set_ball_detect(1);
  else
    vcm.set_ball_detect(0);
  end

  --SJ: This check doesnt't work with nao any more (assumes top camera)
  --Just let it know the ball position all the time for now
  if Config.platform.name == 'WebotsNao' then
    vcm.set_ball_detect(1);
  end


end

function check_side(v,v1,v2)
  --find the angle from the vector v-v1 to vector v-v2
  local vel1 = {v1[1]-v[1],v1[2]-v[2]};
  local vel2 = {v2[1]-v[1],v2[2]-v[2]};
  angle1 = math.atan2(vel1[2],vel1[1]);
  angle2 = math.atan2(vel2[2],vel2[1]);
  return util.mod_angle(angle1-angle2);
end

