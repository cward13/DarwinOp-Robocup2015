module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('gcm')

t0 = 0;

maxStep = Config.fsm.bodyGotoCenter.maxStep;
rClose = Config.fsm.bodyGotoCenter.rClose;
timeout = Config.fsm.bodyGotoCenter.timeout;
--TODO: Goalie handling, velocity limit 
alreadyDone = false;
distanceTolerance = .4;
angleTolerance = .3;
function entry()
  print(_NAME.." entry");
  HeadFSM.sm:set_state('headLookGoalGMU');
  t0 = Body.get_time();
  alreadyDone = false;
  print("yellin ready"); 
 wcm.set_horde_yelledReady(0);-- added this need to check.
 print("yelllED ready");
end

function update()
  pose = wcm.get_pose();
  --endPosition = wcm.get_horde_gotoPose();-- goto an arbitrary pose
   goalAngle = 0;
   if(wcm.get_horde_goalSign() == -1) then
   	goalAngle = 3.14;
   end
   endPosition = {0,pose.y,goalAngle} -- look straight back, maximize chance of seeing two goal poses
   print("I'm in update!!\n");
   print(endPosition);
   -- centerPosition = {x,y,a} in global coordinates
   -- pose_relative will convert centerPosition to coordinates relative to the robot.
 
  endPoseRelative  = util.pose_relative(endPosition, {pose.x, pose.y, pose.a});
  endPoseX = endPoseRelative[1];
  endPoseY = endPoseRelative[2];
  scaleFactor = 15*(math.abs(endPoseX)+math.abs(endPoseY));
  
  if(alreadyDone) then --checking if we've already gotten there to our best tolerance
      print("nitpick adjustments");
      if(endPoseRelative[3]<0) then
           rotateVel = -1;
      else
           rotateVel = 1;
      end
      print("velocity is set to: " .. (endPoseX/scaleFactor/5 + -.005) ); 
      wcm.set_horde_yelledReady(1);
      walk.stop();
	 -- walk.set_velocity(endPoseX/scaleFactor/5 + -.005, endPoseY/scaleFactor/5,rotateVel/10);
	return;
  end
  local t = Body.get_time();
  print("about to grab gootPose");
  print("I converted\n");
  if(math.abs(endPoseX)+math.abs(endPoseY)<distanceTolerance and math.abs(endPoseRelative[3]) < angleTolerance) then
	--walk.set_velocity(0,0,0);
--	Motion.sm:set_state('standstill');
	alreadyDone = true;
	wcm.set_horde_yelledReady(1);
     --	wcm.set_horde_passKick(1);
--	wcm.set_horde_timeMark(Body.get_time());
	return;
  end
  print("X " .. endPoseX .. " Y: " .. endPoseY);
  rotateVel = 0;
  --if we are not close enough to our goal position
  --moving back and forth while moving need to fix TODO
  if(math.abs(endPoseX)+math.abs(endPoseY)>distanceTolerance) then
      print("walking toward final point " .. (math.abs(endPoseX)+math.abs(endPoseY)));
      if(endPoseY>0) then
           rotateVel = .5;
      else
           rotateVel = -.5;
      end
   walk.set_velocity(endPoseX/scaleFactor, endPoseY/scaleFactor,rotateVel);
  elseif(math.abs(endPoseRelative[3]) > angleTolerance) then -- now that our distance is fine, let's look at the angle we need to go to
      print("adjusting final angle " .. endPoseRelative[3]); 
      if(endPoseRelative[3]<0) then
           rotateVel = -1;
      else
           rotateVel = 1;
      end
     walk.set_velocity(0, 0,rotateVel);
  end
end

function exit()
  wcm.set_horde_yelledReady(0);
  -- wcm.set_horde_passKick(1);
  --wcm.set_horde_timeMark(Body.get_time());
  walk.start();
  walk.set_velocity(0,0,0);
  Motion.sm:add_event('walk');
  HeadFSM.sm:set_state('headLookGoalGMU');
end

