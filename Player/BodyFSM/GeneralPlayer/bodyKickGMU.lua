-- Test SM for walk kick
-- Not for distribute


module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')
require('unix');
require('walk');

t0 = 0;
timeout = Config.fsm.bodyWalkKick.timeout;

walkkick_th = 0.14; --Threshold for step-back walkkick for OP
ball = "nil";

function entry()
  print(_NAME.." entry");
--  wcm.set_horde_doneKick(0);
  wcm.set_horde_yelledKick(1);
 
  t0 = Body.get_time();
  follow=false;
  kick_dir=wcm.get_kick_dir();


  print("KICK DIR:",kick_dir)
  ball = wcm.get_ball();
 
  HeadFSM.sm:set_state('headTrackGMU');
--  file = io.open("kickOutput.txt", "w")
--  file:write("KICK START\n");
--  pose = wcm.get_pose();
--  file:write("pose x,y,a: " ..pose.x .. ", " .. pose.y .. ", " .. ", ".. pose.a.. " \n");
--  file:write(" time is : " .. Body.get_time() .. "\n");
--  file:close()
--  HeadFSM.sm:set_state('headIdle');
end

function update()
      local t = Body.get_time();
      print("am updating kick")
      if(ball.y>0) then
	walk.doWalkKickLeft();
	--walk.doSideKickLeft();       
      else
        walk.doWalkKickRight();
	  --walk.doSideKickRight();
      
      end
      --[[kick.set_kick("kickSideLeft");
      Motion.event("kick");
      kick.set_kick("kickSideRight");
      Motion.event("kick"); ]]--
  --SJ: should be done in better way?
  if walk.walkKickRequest==0 and follow ==false then
    follow=true;
    HeadFSM.sm:set_state('headKickFollow');
  end

end

function exit()
    wcm.set_horde_doneKick(1)
    wcm.set_horde_yelledKick(0);
    wcm.set_horde_timeMark(Body.get_time()) 
 -- HeadFSM.sm:set_state('headTrack');
end
