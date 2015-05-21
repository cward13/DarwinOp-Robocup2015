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
--sidekick to left
  walk.doSideKickLeft();
  HeadFSM.sm:set_state('headTrack');
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
