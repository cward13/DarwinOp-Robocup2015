darwin = require('hfaDriver')

-- Used for localizing the robot
startupRobot = {}
-- Used to locate the ball relative to the robot
findBall = {}
--Used to make sure this is actually a ball
verifyBall = {}
-- If we can see the ball relative to us, we want to move to it.
moveToBall = {}
-- Face ball after we have moved to it
faceBall = {}
-- Move in a semicircle around the ball
moveAroundBall = {}
-- Kick the ball...swag
kickBall = {}
-- Localize for a time
timeLocalize = {}
--Stop
stopRobot = {}

behaviors = {startupRobot, findBall, moveToBall, stopRobot, verifyBall, faceBall, moveAroundBall, kickBall, timeLocalize}

states = {"start", "go", "stop"}

for k,v in ipairs(behaviors) do
	for i,t in ipairs(states) do
		if v[t] == nil then
			v[t] = function(hfa) end
		end
	end
end

GlobalRobotVars = {currRobotX, currRobotY, currRobotHeading,
			 						 currBallX, currBallY, XTarget, YTarget, localizeStartTime}

GlobalRobotVars.XTarget = 0;
GlobalRobotVars.YTarget = 0;

startupRobot["start"] = function(hfa)
  print("Starting robot");
	-- first startup called...I just want to move forward and look at the goal.
	darwin.lookGoal();
	darwin.setVelocity(0.02, 0, 0);
	local v = wcm.get_pose();
	GlobalRobotVars.currRobotX = v.x
	GlobalRobotVars.currRobotY = v.y
	GlobalRobotVars.currRobotHeading = v.a
end

startupRobot["go"] = function(hfa) 
	local v = wcm.get_pose();
	GlobalRobotVars.currRobotX = v.x
	GlobalRobotVars.currRobotY = v.y
	GlobalRobotVars.currRobotHeading = v.a
end

findBall["start"] = function(hfa)
	-- Just want to look around until we see something ball like
	print("Looking for the ball");

	darwin.setVelocity(0, 0, -0.2); --turn clockwise since the ball is most likely
	--somewhere to his right
	darwin.scan();
end

verifyBall["start"] = function(hfa)
	-- I think we found a ball. Lets stop
	darwin.track();
end

moveToBall["start"] = function(hfa)
  print("Moving to ball");
	darwin.track();
	GlobalRobotVars.currBallX = wcm.get_ball_x();
	GlobalRobotVars.currBallY = wcm.get_ball_y();
	local v = wcm.get_pose();
	GlobalRobotVars.currRobotX = v.x;
	GlobalRobotVars.currRobotY = v.y;
	GlobalRobotVars.currRobotHeading = v.a;
--	distanceFromBall = math.sqrt(math.pow(GlobalRobotVars.currBallY, 2) + math.pow(GlobalRobotVars.currBallX, 2));
  if GlobalRobotVars.currBallY > -0.2 and GlobalRobotVars.currBallY < 0.2 then
		darwin.setVelocity(0.03, 0, 0);
	elseif GlobalRobotVars.currBallY > 0.2  then
		darwin.setVelocity(0.03, 0, 0.08)
	elseif GlobalRobotVars.currBallY < -0.2 then
		darwin.setVelocity(0.03, 0, -0.08);
	end
end

moveToBall["go"] = function(hfa)
  darwin.track();
	GlobalRobotVars.currBallX = wcm.get_ball_x();
	GlobalRobotVars.currBallY = wcm.get_ball_y();
	local v = wcm.get_pose();
	GlobalRobotVars.currRobotX = v.x
	GlobalRobotVars.currRobotY = v.y
	GlobalRobotVars.currRobotHeading = v.a
--	distanceFromBall = math.sqrt(math.pow(GlobalRobotVars.currBallY, 2) + math.pow(GlobalRobotVars.currBallX, 2));
  if GlobalRobotVars.currBallY > -0.2 and GlobalRobotVars.currBallY < 0.2 then
		darwin.setVelocity(0.03, 0, 0);
	elseif GlobalRobotVars.currBallY > 0.2  then
		darwin.setVelocity(0.03, 0, 0.08)
	elseif GlobalRobotVars.currBallY < -0.2 then
		darwin.setVelocity(0.03, 0, -0.08);
	end
end

faceBall["start"] = function(hfa)
	GlobalRobotVars.currBallX = wcm.get_ball_x();
	GlobalRobotVars.currBallY = wcm.get_ball_y();

	if GlobalRobotVars.currBallY > 0.05 then
		darwin.setVelocity(0,0, 0.2);
	elseif GlobalRobotVars.currBallY < -0.05 then
		darwin.setVelocity(0,0, -0.2);
	else
		darwin.stop();
	end
end

faceBall["go"] = function(hfa)
	GlobalRobotVars.currBallX = wcm.get_ball_x();
	GlobalRobotVars.currBallY = wcm.get_ball_y();

	if GlobalRobotVars.currBallY > 0.05 then
		darwin.setVelocity(0,0, 0.2);
	elseif GlobalRobotVars.currBallY < -0.05 then
		darwin.setVelocity(0,0, -0.2);
	else
		darwin.stop();
	end
end

moveAroundBall["start"] = function(hfa)
	--move in a semicircle around the ball
	--change this to walk around the circumferance of a circle based on distance from ball (x^2 + y^2 = r^2)
	GlobalRobotVars.currBallX = wcm.get_ball_x();
	GlobalRobotVars.currBallY = wcm.get_ball_y();
	local v = wcm.get_pose();
	GlobalRobotVars.currRobotX = v.x;
	GlobalRobotVars.currRobotY = v.y;
	GlobalRobotVars.currRobotHeading = v.a;

	local darwinA = -0.3;
	local darwinX = 0;
	local darwinY = 0.038;
	darwin.setVelocity(darwinX, darwinY, darwinA);
end

moveAroundBall["go"] = function(hfa)
	GlobalRobotVars.currBallX = wcm.get_ball_x();
	GlobalRobotVars.currBallY = wcm.get_ball_y();
	local v = wcm.get_pose();
	GlobalRobotVars.currRobotX = v.x;
	GlobalRobotVars.currRobotY = v.y;
	GlobalRobotVars.currRobotHeading = v.a;

	local darwinA = -0.3;
	local darwinX = 0;
	local darwinY = 0.038;
	darwin.setVelocity(darwinX, darwinY, darwinA);
end

kickBall["start"] = function(hfa)
	darwin.kickBall();
end

stopRobot["start"] = function(hfa) 
	darwin.stop();
end

startupRobotBehavior = makeBehavior("startupRobot", startupRobot["start"],
																										startupRobot["stop"],
																										startupRobot["go"]);

findBallBehavior = makeBehavior("findBall", findBall["start"],
																						findBall["stop"],
																						findBall["go"]);

verifyBallBehavior = makeBehavior("verifyBall", verifyBall["start"],
																								verifyBall["stop"],
																								verifyBall["go"]);

moveToBallBehavior = makeBehavior("moveToBall", moveToBall["start"],
																								moveToBall["stop"],
																								moveToBall["go"]);

faceBallBehavior = makeBehavior("faceBall", faceBall["start"],
																						faceBall["stop"],
																						faceBall["go"]);

moveAroundBallBehavior = makeBehavior("moveAroundBall", moveAroundBall["start"],
																					      moveAroundBall["stop"],
      																					moveAroundBall["go"]);

kickBallBehavior = makeBehavior("kickBall", kickBall["start"],
																						kickBall["stop"],
																						kickBall["go"]);

timeLocalizeBehavior = makeBehavior("timeLocalizeBehavior", timeLocalize["start"],
																														timeLocalize["stop"],
																														timeLocalize["go"])

stopRobotBehavior = makeBehavior("stopRobot", stopRobot["start"],
																							stopRobot["stop"],
																							stopRobot["go"]);
robotStartupTime = os.time();
robotBallTime = 0;
machine =  makeHFA("machine", makeTransition({
	[start] = startupRobotBehavior;	
	[startupRobotBehavior] = function()
		if(os.difftime(os.time(), robotStartupTime)) > 20 then
			return findBallBehavior
		else
			return startupRobotBehavior
		end	
	end,

	[findBallBehavior] = function()
		if vcm.get_ball_detect() == 1 then
			robotBallTime = os.time();
			return verifyBallBehavior
		else
			return findBallBehavior;
		end	
	end,

	[verifyBallBehavior] = function()
		if os.difftime(os.time(), robotBallTime) > 1 and vcm.get_ball_detect() == 1 then			
			darwin.track();
			-- I have seen a ball like thing for a second
			return moveToBallBehavior
		elseif os.difftime(os.time(), robotBallTime) > 1 and vcm.get_ball_detect() == 0 then
			return findBallBehavior
		else
			return verifyBallBehavior
		end	
	end,

	[moveToBallBehavior] = function() 
		print("DISTANCE TO BALL: "..GlobalRobotVars.currBallX);
		if GlobalRobotVars.currBallX < 0.1 then 
			return faceBallBehavior
		else
			return moveToBallBehavior
		end
	end,

	[faceBallBehavior] = function()
		print("Arrived at ball turning to it now.  CurrBallY: " .. GlobalRobotVars.currBallY);
		if math.abs(GlobalRobotVars.currBallY) < 0.02 then --generally facing it
			darwin.lookGoal();
			GlobalRobotVars.localizeStartTime = os.time();
			return timeLocalizeBehavior;
		else
			return faceBallBehavior;
		end
	end,

	[moveAroundBallBehavior] = function()
		-- Find the normal X and Y
		local normalX =  GlobalRobotVars.XTarget - GlobalRobotVars.currRobotX;
		local normalY =  GlobalRobotVars.YTarget - GlobalRobotVars.currRobotY;

		--Find normal a normal heading
		local normalHeading = math.atan2(normalY, normalX);

		print("Current Heading: "..(GlobalRobotVars.currRobotHeading*180)/math.pi.." \tAngle to point: "..(normalHeading*180)/math.pi.."\tRobot (x,y): "..GlobalRobotVars.currRobotX..", "..GlobalRobotVars.currRobotY);

		if math.abs(GlobalRobotVars.currRobotHeading - normalHeading) < 0.01 then
			return kickBallBehavior;
		else
			return moveAroundBallBehavior;
		end
	end,

	[kickBallBehavior] = function()
		print("kicking the mofo ball");
		return stopRobotBehavior;
	end,

	[timeLocalizeBehavior] = function()
		if os.difftime(os.time(), GlobalRobotVars.localizeStartTime) > 5 then
			return moveAroundBallBehavior
		else
			return timeLocalizeBehavior
		end
	end,

	[stopRobotBehavior] = function()
		darwin.stop();
		return stopRobotBehavior
	end
}))

darwin.executeMachine(machine);
