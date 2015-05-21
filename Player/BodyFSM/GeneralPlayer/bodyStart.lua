module(..., package.seeall);

require('Body')
require('walk')
require('gcm')
require('vcm')
require('wcm')
require('Speak')
require('util')

t0=0;
tLastCount=0;

tKickOff=10.0; --5 sec max wait before moving
--If ball moves more than this amount, start moving
--If the ball comes any closer than this, start moving
ballClose = 0.50; 

if Config.fsm.playMode ==1 then
  --Turn off kickoff waiting for demo
  wait_kickoff = 0; 
else
  wait_kickoff = Config.fsm.wait_kickoff or 0;
end

function entry()
  print(_NAME..' entry');
  kickoff_wait=0;

  --Kickoff handling (only for attacker)
  --TODO: This flag is set when player returns from penalization too

  if wait_kickoff>0 then 
    if gcm.get_game_kickoff()==1 then
      --Our kickoff, go ahead and kick the ball
      --Kickoff kick should be different 
      wcm.set_kick_kickOff(1);
      wcm.set_kick_tKickOff(Body.get_time());
    else
      --Their kickoff, wait for ball moving
      Speak.talk("Waiting for opponent's kickoff");
      kickoff_wait=1;
      t0=Body.get_time();
      tLastCount=t0;
      --the ball distance from vcm is more reliable
      ballR0 = vcm.get_ball_r();
      if ballR0 > 0 then
        dist = ballR0;
      else
        pos = wcm.get_pose();
        dist = math.sqrt(pos.x^2 + pos.y^2);
      end
      print ("dist: "..dist)
      dist = math.min(dist, 4);
      tKickOff = 2+2*(4-dist);
      print ("tKickOff"..tKickOff);
      walk.stop();
    end
  else
      kickoff_wait=0; --Defenders may move
  end
end

function update()

  role = gcm.get_team_role();
  if role==0 then 
    return 'goalie'
  end

  t=Body.get_time();
  if kickoff_wait>0 then
    walk.stop();
    ballR = vcm.get_ball_r();
    if ballR and ballR0 then
      ballDiff = ballR - ballR0;
      if math.abs(ballDiff) > 0.5*ballR0 then
        print ("ballDiff"..ballDiff)
        return 'done'
      else
        tRemaining = tKickOff-(t-t0);
        if tRemaining<0 then 
          return 'done';
        elseif t>tLastCount then
          tLastCount=tLastCount+1;
          countdown=string.format("%d",tRemaining)
          print("Count: ",countdown)
--        Speak.talk(countdown);
        end
      end
    end
  else
    return 'done';
  end
end


function exit()
  walk.start();
end
