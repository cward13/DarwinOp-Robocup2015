module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('gcm')
--require('PoseFilter')
t0 = 0;

maxStep = Config.fsm.bodyGotoCenter.maxStep;
rClose = Config.fsm.bodyGotoCenter.rClose;
timeout = Config.fsm.bodyGotoCenter.timeout;
--TODO: Goalie handling, velocity limit 
alreadyDone = false;
distanceTolerance = .2;
angleTolerance = .3;
setHeadTrack = false;
function entry()
  print(_NAME.." entry");
 setHeadTrack = false; --HeadFSM.sm:set_state('headLookGoalGMU');
  HeadFSM.sm:set_state('headLookBehindAndBall')
  t0 = Body.get_time();
  alreadyDone = false;
  print("yellin ready"); 
  wcm.set_horde_yelledReady(0);-- added this need to check.
  print("yelllED ready");
  
end

function update()
  pose = wcm.get_pose();
  endPosition = wcm.get_horde_gotoPose();-- goto an arbitrary pose
  endFacing = wcm.get_horde_facing(); 
  print("I'm in update!!\n");
   print(endPosition);
   -- centerPosition = {x,y,a} in global coordinates
   -- pose_relative will convert centerPosition to coordinates relative to the robot.
 
  endPoseRelative  = util.pose_relative(endPosition, {pose.x, pose.y, pose.a});
  endPoseX = endPoseRelative[1];
  endPoseY = endPoseRelative[2];
  --[[if(math.abs(pose.x - endPoseX) > 3) then
--	PoseFilter.flip_particle_angle();
  	file = io.open("didIFlip.txt", "w")
        file:write("yup i flipped " .. Body.get_time() .. "\n")
        file:close()
	wcm.set_horde_confused(1);	
  end --]]
  endFacingRelative = util.pose_relative(endFacing,{pose.x,pose.y,pose.a})
  endFacingX = endFacingRelative[1];
  endFacingY = endFacingRelative[2];
  
  endFacingRelative[3] = math.atan2(endFacingY, endFacingX);
  scaleFactor = 15*(math.abs(endPoseX)+math.abs(endPoseY));
	
  print("im currently at " .. pose.x .. ", " .. pose.y );
  print("im trying to face " .. endFacing[1] .. ", " .. endFacing[2])
  print("also, trying to move to " .. endPosition[1] .. ", " .. endPosition[2]);
  print("relative to the ball, i am facing " .. endFacingRelative[3])
  print("PURELY BALL RELATIVE " .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y())
  if(alreadyDone) then --checking if we've already gotten there to our best tolerance
     setDebugTrue()
   --    HeadFSM.sm:set_state("headTrackGMU");
       setDebugFalse()
      print("nitpick adjustments");
      if(endPoseRelative[3]<0) then
           rotateVel = -1;
      else
           rotateVel = 1;
      end
      print("velocity is set to: " .. (endPoseX/scaleFactor/5 + -.005) ); 
        walk.set_velocity(endPoseX/scaleFactor/5 + -.005, endPoseY/scaleFactor/5,rotateVel/10*math.abs(endPoseRelative[3]));
	return;
  end
  local t = Body.get_time();
  print("about to grab gootPose");
  print("I converted\n");
  if((pose.x-endFacing[1]<0) == ((endFacing[1] - endPosition[1])<0)) then -- far away, just run at the point
      print("final point far away, must run toward" .. (math.abs(endPoseX)+math.abs(endPoseY)));
     print("angle trying to face " .. endFacingRelative[3]); 
     if(endFacingRelative[3]>0) then
           rotateVel = .5;
      else
           rotateVel = -.5;
      end
	  if(math.abs(endPoseRelative[3]) <.5) then
			rotateVel = rotateVel*math.abs(endPoseRelative[3]);
	  end
      walk.set_velocity(endPoseX/scaleFactor*1.1, endPoseY/scaleFactor*1.1,rotateVel);
  	  return;
  end -- check for completion
  if((math.abs(endPoseX)+math.abs(endPoseY))<distanceTolerance and math.abs(endFacingRelative[3]) < angleTolerance) then
 	print("i am most certainly ready");
	--Speak.talk("banana.");
	walk.set_velocity(0,0,0);
--	Motion.sm:set_state('standstill');
	walk.stop();
	 setDebugTrue()
        print("head track") 
	if(setHeadTrack~=true) then
         HeadFSM.sm:set_state("headTrackGMU");
         setHeadTrack = true;
	end 
	setDebugFalse()

        --alreadyDone = true;
	wcm.set_horde_yelledReady(1);
     	--wcm.set_horde_passKick(1);
	--wcm.set_horde_timeMark(Body.get_time());
	return;
  end
  print("X " .. endPoseX .. " Y: " .. endPoseY);
  rotateVel = 0;
  --if we are not close enough to our goal position
  --moving back and forth while moving need to fix TODO
  if(math.abs(endFacingRelative[3]) > angleTolerance) then -- now that our distance is fine, let's look at the angle we need to go to
      print("adjusting final angle " .. endFacingRelative[3]); 
      if(endFacingRelative[3]<0) then
           rotateVel = -1;
      else
           rotateVel = 1;
      end
      walk.set_velocity(0, 0,rotateVel*math.abs(endFacingRelative[3]));
  elseif (math.abs(endPoseX)+math.abs(endPoseY)>distanceTolerance) then
	print("just adjusting distance now, angle must be good, take a look: " .. tostring(endFacingRelative[3]));
--[[  print("walking toward final point " .. (math.abs(endPoseX)+math.abs(endPoseY)));
      if(endPoseY>0) then
           rotateVel = .5;
      else
           rotateVel = -.5;
      end]]--
      walk.set_velocity(endPoseX/scaleFactor, endPoseY/scaleFactor,endFacingRelative[3]);
  end
end

function exit()
  wcm.set_horde_yelledReady(0);
  -- wcm.set_horde_passKick(1);
  --wcm.set_horde_timeMark(Body.get_time());
  Motion.sm:add_event('walk');
  walk.set_velocity(0,0,0);
  walk.start();
  HeadFSM.sm:set_state('headLookGoalGMU');
end

