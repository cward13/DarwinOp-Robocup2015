module(..., package.seeall);

require('Body')
require('fsm')
require('gcm')
require('Config')
require('bodyMoveThetaLookGoal')
require('bodyIdle')
require('bodyStart')
require('bodyStop')
require('bodyReady')
require('bodySearch')
require('bodyApproachGMU')
require('bodyDribbleGMU')
require('bodyKick')
require('bodyWalkKick')
require('bodyOrbit')
require('bodyGotoCenter')
require('bodyPosition')
require('bodyObstacle')
require('bodyObstacleAvoid')
require('bodyDribble')
require('bodyWalkForward')
require('bodyKickGMU')
require('bodyGotoBall')
require('bodyNull')
require('bodyMoveTheta')
require('bodyMoveX')
require('bodyMoveY')
require('bodyKickLeftGMU')
require('bodyKickRightGMU')
require('bodyApproachTarget')
require('bodyYellFail')
require('bodyYellReady')
require('bodyYellKick')
require('bodyDoVelocity')
require('bodyPositionGoalie')
require('bodyAnticipate')
require('bodyChase')
require('bodyDive')
require('bodyGotoPosition')
require('bodyGotoWhileFacing')
require('bodyGotoWhileFacingGoalie')
require('bodyGotoPoseWhileLookingBackwards')
require('bodyUnpenalized')
require('bodyApproach')
require('bodyLookBackwards')

require('bodyReadyMove')



sm = fsm.new(bodyIdle);
sm:add_state(bodyDoVelocity);
sm:add_state(bodyMoveThetaLookGoal);
sm:add_state(bodyLookBackwards);
sm:add_state(bodyGotoWhileFacingGoalie);
sm:add_state(bodyGotoPoseWhileLookingBackwards);
sm:add_state(bodyApproach);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);
sm:add_state(bodySearch);
sm:add_state(bodyApproachGMU);
sm:add_state(bodyDribble);
sm:add_state(bodyKick);
sm:add_state(bodyWalkKick);
sm:add_state(bodyOrbit);
sm:add_state(bodyGotoCenter);
sm:add_state(bodyPosition);
sm:add_state(bodyObstacle);
sm:add_state(bodyObstacleAvoid);
sm:add_state(bodyDribbleGMU);
sm:add_state(bodyWalkForward);
sm:add_state(bodyKickGMU);
sm:add_state(bodyGotoBall);
sm:add_state(bodyNull);
sm:add_state(bodyMoveTheta);
sm:add_state(bodyMoveX);
sm:add_state(bodyMoveY);
sm:add_state(bodyKickLeftGMU);
sm:add_state(bodyKickRightGMU);
sm:add_state(bodyGotoPosition);
sm:add_state(bodyApproachTarget);
sm:add_state(bodyYellFail);
sm:add_state(bodyYellReady);
sm:add_state(bodyYellKick);
sm:add_state(bodyGotoWhileFacing);
sm:add_state(bodyPositionGoalie);
sm:add_state(bodyAnticipate);
sm:add_state(bodyDive);
sm:add_state(bodyChase);

sm:add_state(bodyReadyMove);
sm:add_state(bodyUnpenalized);

function entry()
  sm:entry()
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
