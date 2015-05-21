--Include Luke's HFA Driver
darwin = require('hfaDriver')


--task 2, find ball and stop near it
--[[
-- BEHAVIORS
-- localize		--wander if the ball is not seen
-- faceBall  		--X, Y are wcm.get_ball_x/y()
-- moveToBall		--used to move to a distance near the ball
-- Stop			--Stop the robot
--]]

func = function (hfa) end

initRobot = {}
localize = {}
findBall = {}
faceBall = {}
moveToBall = {}
stopRobot = {}

relativeX = 0;
relativeY = 0;
ballAngle =0;
ballX = 0;
ballY = 0;
robotAngle = 0;
robotX = 0;
robotY = 0;

behaviors = {initRobot, findBall, localize, faceBall, moveToBall, stopRobot}
states = {"start", "go", "stop"}

for k,v in ipairs(behaviors) do
  for i,t in ipairs(states) do
    if v[t] == nil
    then
      v[t] = function(hfa) end;
    end
  end
end

initRobot["start"] = function(hfa)
	darwin.lookGoal();
	darwin.setVelocity(0.02,0,0); --Move forward
end

--localize

localize["start"] = function(hfa)
	print("Starting localize\n");
	darwin.lookGoal();
	darwin.scan();
end

--Init start. Literally just move forward for a bit, get the darwin going
findBall["start"] = function(hfa) 
	print("Starting find ball\n");
	darwin.scan(); --look for ball
	--if you can't find it start to rotate
	if darwin.isBallLost() == 1 then
		darwin.stop();
		darwin.setVelocity(0,0, 0.2);
		end
end

-- Find the ball and track it
faceBall["start"] = function (hfa)
	print("Starting face ball\n");
  darwin.stop();  
	-- Normalize the ball Angle. If we are at 90 deg...subtract 90 to normalize to zero. 
	-- Then subtract 90 from ball angle to get a normalized angle
	local normalAngle = ((ballAngle - robotAngle)*180) / math.pi
	if(normalAngle < 0) then
		normalAngle =  360 + normalAngle
	end

	if(normalAngle >= 0 and normalAngle <= 180) then
		darwin.setVelocity(0, 0, 0.1)
	else
		darwin.setVelocity(0, 0, -0.1);
	end
	--[[
 		if (ballAngle > robotAngle and (ballAngle - math.pi) < robotAngle) or (RobotAngle > ballAngle and (robotAngle -  math.pi) > ballAngle)  then
	 		darwin.setVelocity(0,0, 0.1);
 		else
			darwin.setVelocity(0,0, -0.1);
	 end 
  --rotate to face ball direction
	--]]
end

-- Move to near the ball
moveToBall["start"] = function (hfa)
	print("Starting to move to ball\n");
  print("ball x location:  " .. ballX .. " and ball y location: " .. ballY .. " and ball angle: " .. ballAngle);
	print("darwin x location: " .. robotX .. " and robot y location: " .. robotY .. " and robot angle: " .. robotAngle);
	darwin.stop();
  darwin.setVelocity(0.05,0, 0);  --move forward at 0.05 meters per second
end

-- Stop darwin
stopRobot["start"] = function (hfa)
  darwin.stop();
end

-- Make the behaviors
initRobot_b 	= makeBehavior("initRobot", initRobot["start"], initRobot["go"], initRobot["stop"]);
localize_b = makeBehavior("localize", localize["start"], localize["go"], localize["stop"]);
findBall_b 	= makeBehavior("findBall", findBall["start"], findBall["go"], findBall["stop"]);
faceBall_b 	= makeBehavior("faceBall", faceBall["start"], faceBall["go"], faceBall["stop"]);
moveToBall_b  	= makeBehavior("moveToBall", moveToBall["start"], moveToBall["go"], moveToBall["stop"]);
stopRobot_b 	= makeBehavior("stopRobot", stopRobot["start"], stopRobot["go"], stopRobot["stop"]);


oldX = 0;
oldY = 0;
robotStartTime = os.time();
robotTransitionDelay = 0;

-- Make the HFA 
machine = makeHFA("machine", makeTransition({
  [start] = initRobot_b;

	[initRobot_b] = function()
		if(os.difftime(os.time(), robotStartTime) > 20 ) then 
			return localize_b;
		else
			return initRobot_b;
		end
	end,

	[localize_b] = function()
		v=wcm.get_pose();
		
		xDiff = math.abs((oldX - v.x) / ((oldX + v.x)/2));
		yDiff = math.abs((oldY - v.y) / ((oldY + v.y)/2));

		avgDiff = (xDiff + yDiff) /2;

		if(avgDiff < 5) then
			robotX = v.x;
			robotY = v.y;
			robotAngle = v.a;
			print("Looking for ball now.\n");
			return findBall_b;
		else
			return localize_b;
		end
	end,

	[findBall_b] = function()
		if darwin.isBallLost() == 1 then   --cannot see ball, keep searching
			return findBall_b;
		else   --can see ball, face it
			print("I can see the ball");
			if vcm.get_ball_detect() == 1 then
				darwin.stop();
				darwin.track();
				ballX = wcm.get_ball_x();
				ballY = wcm.get_ball_y();
				v = wcm.get_pose();
				robotX = v.x;
				robotY = v.y;
				robotAngle = v.a;

				relativeX = ballX - robotX;
				relativeY = ballY - robotY;
				ballAngle = math.atan2(relativeY, relativeX);

				print("Found ball. Rotating to ball\n");
				print("BALL ANGLE: "..ballAngle);
				return faceBall_b;
			else 
				return findBall_b;
			end
		end
	end,

	[faceBall_b] = function()  --if we're in faceXY
		-- Assume we rotated to the correct angle
		v=wcm.get_pose();
		robotX= v.x;
		robotY= v.y;
		robotAngle = v.a;
		--[[
		ballX = wcm.get_ball_x();
		ballY = wcm.get_ball_y();

		relativeX = ballX - robotX;
		relativeY = ballY - robotY;
		
		ballAngle = math.atan2(relativeX, relativeY);
		print("THE BALL ANGLE IS: "..ballAngle);
		--]]
		print("I AM ".. math.abs(robotAngle - ballAngle) .. " RADS AWAY");
		if math.abs(robotAngle - ballAngle ) < 0.05 then --turned at an angle close to the ball
			darwin.stop();
			darwin.setVelocity(0,0,0);
			print("I am at the ball?\n");
			if vcm.get_ball_detect() == 1 then
				-- I rotated and can see the ball.
				print("I can see the ball");
				darwin.stop();
				return moveToBall_b;
			else
				print("I cannot see the ball");
				darwin.stop();
				return stopRobot_b;
			end
		else  --found ball, face it
		  return faceBall_b;
		end
	end,
	      
	[moveToBall_b] = function()
	  v=wcm.get_pose();
		x=v.x;
		y=v.y;
		a=v.a;
		ballX = wcm.get_ball_x();
		ballY = wcm.get_ball_y();
		distance = math.sqrt((math.pow((ballX - x), 2)+ math.pow((ballY - y), 2)));
		-- get close enough to kick
		if(distance < 0.5) then
			print("Made it to the ball\n");
			return stopRobot_b;
		else
			return moveToBall_b;
		end	

	end,
	
	[stopRobot_b] = function()
			darwin.stop();
			darwin.setVelocity(0,0,0);
			return stopRobot_b;
	end
	}),false);
	
--start main  
darwin.executeMachine(machine);
