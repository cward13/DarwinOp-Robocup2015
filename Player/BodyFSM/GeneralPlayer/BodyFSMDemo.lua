module(..., package.seeall);

require('Body')
require('fsm')
require('gcm')
require('Config')

require('bodyIdle')
require('bodyStart')
require('bodyStop')
require('bodyReady')
require('bodySearch')
require('bodyApproach')
require('bodyKick')
require('bodyWalkKick')
require('bodyOrbit')
require('bodyGotoCenter')
require('bodyPosition')
require('bodyObstacle')
require('bodyObstacleAvoid')
require('bodyDribble')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);
sm:add_state(bodySearch);
sm:add_state(bodyApproach);
sm:add_state(bodyKick);
sm:add_state(bodyWalkKick);
sm:add_state(bodyOrbit);
sm:add_state(bodyGotoCenter);
sm:add_state(bodyPosition);
sm:add_state(bodyObstacle);
sm:add_state(bodyObstacleAvoid);
sm:add_state(bodyDribble);

------------------------------------------------------
-- Demo FSM (No orbit)
------------------------------------------------------

sm:set_transition(bodyReady, 'done', bodyReady);

sm:set_transition(bodyStart, 'done', bodyPosition);

sm:set_transition(bodyPosition, 'timeout', bodyPosition);
sm:set_transition(bodyPosition, 'ballLost', bodySearch);
sm:set_transition(bodyPosition, 'ballClose', bodyApproach);
sm:set_transition(bodyPosition, 'obstacle', bodyObstacle);
sm:set_transition(bodyPosition, 'done', bodyApproach);
sm:set_transition(bodyPosition, 'dribble', bodyDribble);

sm:set_transition(bodyObstacle, 'clear', bodyPosition);
sm:set_transition(bodyObstacle, 'timeout', bodyObstacleAvoid);

sm:set_transition(bodyObstacleAvoid, 'clear', bodyPosition);
sm:set_transition(bodyObstacleAvoid, 'timeout', bodyPosition);

sm:set_transition(bodySearch, 'ball', bodyPosition);
sm:set_transition(bodySearch, 'timeout', bodyGotoCenter);

sm:set_transition(bodyGotoCenter, 'ballFound', bodyPosition);
sm:set_transition(bodyGotoCenter, 'done', bodySearch);
sm:set_transition(bodyGotoCenter, 'timeout', bodySearch);

sm:set_transition(bodyApproach, 'ballFar', bodyPosition);
sm:set_transition(bodyApproach, 'ballLost', bodySearch);
sm:set_transition(bodyApproach, 'timeout', bodyPosition);
sm:set_transition(bodyApproach, 'kick', bodyKick);
sm:set_transition(bodyApproach, 'walkkick', bodyWalkKick);

sm:set_transition(bodyKick, 'done', bodyPosition);
sm:set_transition(bodyKick, 'timeout', bodyPosition);
sm:set_transition(bodyKick, 'reposition', bodyApproach);
sm:set_transition(bodyWalkKick, 'done', bodyPosition);

sm:set_transition(bodyPosition, 'fall', bodyPosition);
sm:set_transition(bodyApproach, 'fall', bodyPosition);
sm:set_transition(bodyKick, 'fall', bodyPosition);


-- set state debug handle to shared memory settor
sm:set_state_debug_handle(gcm.set_fsm_body_state);


function entry()
  sm:entry()
  wcm.set_kick_dir(1);
  wcm.set_kick_type(2);
  wcm.set_kick_angle(0);
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
