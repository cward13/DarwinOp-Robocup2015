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


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  follow=false;
  kick_dir=wcm.get_kick_dir();


print("KICK DIR:",kick_dir)

  if kick_dir==1 then --straight walkkick
    -- set kick depending on ball position
    ball = wcm.get_ball();
print("WalkKick: Ball pos:",ball.x,ball.y);
    if (ball.y > 0) then
      if (ball.x>walkkick_th) or Config.fsm.enable_walkkick<2 then
        print("doWalkKickLeft");
	walk.doWalkKickLeft();
      else
--        walk.doWalkKickLeft2();
        print("doWalkKickLeft");
        walk.doWalkKickLeft();
      end
    else
      if (ball.x>walkkick_th) or Config.fsm.enable_walkkick<2 then
        print("doWalkKickRight");
	walk.doWalkKickRight();
      else
	print("doWalkKickRight");
--        walk.doWalkKickRight2();
        walk.doWalkKickRight();
      end
    end
  elseif kick_dir==2 then --sidekick to left
   	print("doSideKickLeft");
	walk.doSideKickLeft();
  else
	print("doSideKickRight");
	walk.doSideKickRight(); --sidekick to right
  end
  print("look above me\n\n\n\n");
  HeadFSM.sm:set_state('headTrackGMU');
--  HeadFSM.sm:set_state('headIdle');
end

function update()
  local t = Body.get_time();

  if kick_dir==1 and Config.largestep_enable==true then 
    if mcm.get_walk_isStepping()==0 then
      return "done";
    end   
  else
    if (t - t0 > timeout) then
      return "done";
    end
  end

  --SJ: should be done in better way?
  if walk.walkKickRequest==0 and follow ==false then
    follow=true;
    HeadFSM.sm:set_state('headKickFollow');
  end

end

function exit()
 -- HeadFSM.sm:set_state('headTrack');
end
