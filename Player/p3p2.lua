--This file is built around the code that was provided
darwin = require('hfaDriver')

targetY = 0
targetX = 0
targetLimit = 0.7
ballLimit = 0.2
angleLimit = 10
turnSpeed = 0.10
walkSpeed = 0.05
locTime = 8 -- time to localize, in seconds
radToDeg = 180/math.pi
distToBall = 0
distCountMax = 4  -- how many times to recalibrate on ball location
distCount = distCountMax  -- recalibration count

--functions
function getTurnAngleToTarget(tx, ty) 	
	local angle = 0
	local rx = wcm.get_pose().x
	local ry = wcm.get_pose().y
	local ra = wcm.get_pose().a*radToDeg
	local dx = tx - rx
	local dy = ty - ry
	
	if dx == 0 then --if angle is +/- 90
		angle = 0
	else
		angle = math.atan(dy/dx)*radToDeg
	end
	
	if dx <= 0 and dy <= 0 then -- if in 4th quadrant, adjust tan
		angle = angle - 180
	elseif dx < 0 and dy > 0 then
		angle = angle + 180
	end
	
	angle = angle - ra
	--print ("Rx: "..rx.." Ry: "..ry.." Ra: "..ra.." Ta: "..angle)
	return angle
end

function getTurnAngleToBall() 	
	local angle = 0
	local dx = wcm.get_ball_x()
	local dy = wcm.get_ball_y()
	
	if dx == 0 then --if angle is +/- 90
		angle = 0
	else
		angle = math.atan(dy/dx)*radToDeg
	end
	
	if dx <= 0 and dy <= 0 then -- if in 4th quadrant, adjust tan
		angle = angle - 180
	elseif dx < 0 and dy > 0 then
		angle = angle + 180
	end
	--angle = angle*math.pi/180.0
	local distance = math.sqrt(dx*dx+dy*dy)

	
	return {angle, distance}
end

--Behaviors
localizeStart = function(hfa)    
	oldtime = os.clock()
	print("localize behavior");
	darwin.lookGoal()
	darwin.setVelocity(walkSpeed, 0,0);
end	
localizeGo = function(hfa) 
end
localizeStop = function (hfa)
end

turnToAngleStart = function(hfa)   
	darwin.track()
	local a = getTurnAngleToTarget(targetX, targetY);
	if a > 0 then
		print("turning left");
		darwin.setVelocity(0, 0,turnSpeed);
	elseif a < 0 then
		darwin.setVelocity(0, 0,-1*turnSpeed);
		print("turning right");
	else
		print("stopping");
		darwin.stop();
	end	
end	
turnToAngleGo = function(hfa) 
end
turnToAngleStop = function (hfa)
	darwin.stop();	
end

-- --------------------------------------------------------turn to relative ball. 
turnToRelativeBallStart = function(hfa)   
	darwin.track()
	if (darwin.isBallLost()) then
		darwin.setVelocity(0, 0,turnSpeed);
	else 
		local a = getTurnAngleToBall()[1];
		print ("I am actually angle: "..getTurnAngleToBall()[1].." distance: "..getTurnAngleToBall()[2])
		if a > 0 then
			print("turning left to ball");
			darwin.setVelocity(0, 0,turnSpeed);
		elseif a < 0 then
			darwin.setVelocity(0, 0,-1*turnSpeed);
			print("turning right to ball");
		else
			print("stopping");
			darwin.stop();
		end
	end



end	
turnToRelativeBallGo = function(hfa) 
end
turnToRelativeBallStop = function (hfa)
	darwin.stop();	
end

spinStart = function(hfa) 
	print("i'm spinning!");
  darwin.setVelocity(0, 0,turnSpeed);
  darwin.scan()
end	
spinGo = function(hfa) 
end
spinStop = function (hfa)
  --get the ball's coordinates in global coordinates. 
  local angle = wcm.get_pose().a
  if (angle < 0) then
    angle = angle +2*math.pi
  end
  targetX = (wcm.get_ball_x()*math.cos(angle)-wcm.get_ball_y()*math.sin(angle))+wcm.get_pose().x
  targetY = (wcm.get_ball_x()*math.sin(angle)+wcm.get_ball_y()*math.cos(angle))+wcm.get_pose().y
  if distToBall == 0 then --if first time then calc distToBall
  	distToBall = math.sqrt(math.pow((targetX -wcm.get_pose().x),2)+math.pow((targetY - wcm.get_pose().y),2))
	end

  targetX = 0 --update to default position that we want the robot to search for a ball
  targetY = 0 --update to default position that we want the robot to search for a ball
  darwin.stop()
  darwin.lookGoal()
  print ("Rx: "..wcm.get_pose().x.." Ry: "..wcm.get_pose().y.." Ra: "..wcm.get_pose().a.." Tx: "..targetX.." Ty: "..targetY)

end
walkForwardStart = function(hfa)                   
	print("walk forward");
	darwin.setVelocity(walkSpeed, 0,0);
end	
walkForwardGo = function(hfa)
end
walkForwardStop = function (hfa)
end

walkForwardBallStart = function(hfa)                   
	print("walk forward");
	darwin.setVelocity(walkSpeed/2, 0,0);
end	
walkForwardBallGo = function(hfa)
end
walkForwardBallStop = function (hfa)
end

stopStart = function(hfa)
	print("i stopped at location " .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ", " .. wcm.get_pose().a);
	--print(" the ball is at location " .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y());
	darwin.stop();	
	darwin.track(); -- stares at the last location we saw the ball
end

stopGo = function(hfa)
end
stopStop = function(hfa)
end

-- MAKE STATES
turnToAngle = makeBehavior("turnToAngle", turnToAngleStart, turnToAngleStop, turnToAngleGo);
walkForward = makeBehavior("walkForward", walkForwardStart, walkForwardStop, walkForwardGo);
walkForwardBall = makeBehavior("walkForwardBall", walkForwardBallStart, walkForwardBallStop, walkForwardBallGo);
localize = makeBehavior("localize", localizeStart, localizeStop, localizeGo);
spin = makeBehavior("spin", spinStart, spinStop, spinGo);
turnToRelativeBall = makeBehavior("turnToRelativeBall", turnToRelativeBallStart, turnToRelativeBallStop, turnToRelativeBallGo);
stop = makeBehavior("stop", stopStart, stopStop, stopGo);

-- STATE TRANSITIONS
myMachine = makeHFA("myMachine", makeTransition(
	{
		[start] = localize, --first thing we do: walk forward
		[localize] = function()
			if vcm.get_ball_detect()==1 then
				return turnToRelativeBall
			elseif (os.clock() - oldtime)<locTime then
				return localize 
			else 
				return turnToAngle 
			end 
		end,
				
		[turnToAngle] = function() 
			if vcm.get_ball_detect()==1 then
				return turnToRelativeBall
			elseif math.abs(getTurnAngleToTarget(targetX, targetY))>angleLimit then
				return turnToAngle 
			else 
				return walkForward 
			end 
		end,
		
		[walkForward] = function() 
			local distance = math.sqrt(math.pow((targetX -wcm.get_pose().x),2)+math.pow((targetY - wcm.get_pose().y),2))
			if vcm.get_ball_detect()==1 then
				return turnToRelativeBall
			elseif math.abs(getTurnAngleToTarget(targetX, targetY)) > angleLimit*3 then
				return turnToAngle
			elseif distance > targetLimit then
				return walkForward 
			else 
				return spin   --relative localization of the ball.
			end 
		end,	

		[spin] = function()
			if vcm.get_ball_detect()==0 then --if dont know where the ball is
				return spin 
			else 
				return turnToRelativeBall  --was turnToAngle before when it was calculating global coordinates.  
			end 
		end,	
		[turnToRelativeBall] = function() 
			if getTurnAngleToBall()[1]>angleLimit then
				return turnToRelativeBall 
			else 
				return walkForwardBall 
			end 
		end,
		[walkForwardBall] = function() 
			if getTurnAngleToBall()[1] > angleLimit*3 then
				return turnToRelativeBall
			elseif getTurnAngleToBall()[2] > ballLimit then
				return walkForwardBall 
			else 
				return stop   --relative localization of the ball.
			end 
		end,
		[stop] = function()  
			if math.abs(getTurnAngleToTarget(targetX, targetY))>angleLimit * 2 then 
				return stop 
			else 
				return stop  
			end 
		end,
}),false);	
	
--start "main"
darwin.executeMachine(myMachine);



--Walk to position, face target. Your darwin should be able to walk to a point (x,y) on the field, and face some other point (x’,y’) .
--	while 1
--		wcm.get_pose(): gets x and y angular position. 
--		new speed x, y = update final speed using a bang bang routione so either 0.05 speed or 0
--		new angular = update final angular speed based on our position
--		darwin.setVelocity(new speed x, y, new angular);
--		keep doing this until we get close to the point. 

--Walk towards a ball. Get the darwin close to a ball, and stop.
-- Keep in mind, you may not be able to see the ball initially, you must find the ball then walk toward it.
--	while 1
--		randomly move around the field and the go to ball position?
--		darwin.scan() then wcm.get_ball_x() and wcm.get_ball_y(): 
--		onceball location is found use method 1 to go there.

--Approach Ball and kick. This is not the same as walking towards a ball and kicking! you must align yourself 
--		so that you can kick the ball straight forward with one of your feet.
--		I recommend making your robot either left-footed or right-footed.
--	Use method 2 and get near the ball. Keep updating so that you can get very close. 

--Walk to a ball , approach and kick to target.
--		use method 3 but approach the point in a certain angle so that you can kick it at the end. 

--Walk to a position, wait until ball is close, then approach and kick into the goal.
--		Self explanatory method 1 and 4 combined but use kick to goal look goal?

--Wow me 


