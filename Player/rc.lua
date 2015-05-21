	darwin = require('hfaDriver')
	
	targetY = 1.5
	targetX = 1.5
	targetLimit = 0.05
	
	--functions
	function getTurnAngleToTarget(tx, ty) 	
		local angle = 0
		local rx = wcm.get_pose().x
		local ry = wcm.get_pose().y
		local ra = wcm.get_pose().a*180/math.pi
		local dx = tx - rx
		local dy = ty - ry
		
		print ("Rx: "..rx.." Ry: "..ry.." Ra: "..ra)
		
		if dx == 0 then --if angle is +/- 90
			angle = 0
		else
			angle = math.atan(dy/dx)*180/math.pi
		end
		
		if dx <= 0 and dy <= 0 then -- if in 4th quadrant, adjust tan
			angle = angle - 180
		elseif dx < 0 and dy > 0 then
			angle = angle + 180
		end
		
		angle = angle - ra
		return angle
	end
	
	function getTurnAngleToTarget(tx, ty) 	
		local angle = 0
		local rx = wcm.get_pose().x
		local ry = wcm.get_pose().y
		local ra = wcm.get_pose().a*180/math.pi
		local dx = tx - rx
		local dy = ty - ry
		
		print ("Rx: "..rx.." Ry: "..ry.." Ra: "..ra)
		
		if dx == 0 then --if angle is +/- 90
			angle = 0
		else
			angle = math.atan(dy/dx)*180/math.pi
		end
		
		if dx <= 0 and dy <= 0 then -- if in 4th quadrant, adjust tan
			angle = angle - 180
		elseif dx < 0 and dy > 0 then
			angle = angle + 180
		end
		
		angle = angle - ra
		return angle
	end
		
	
	turnToAngleStart = function(hfa)   
		
		
		a = getTurnAngleToTarget(targetX, targetY);
		if a > 0 then
			print("turning left");
			darwin.setVelocity(0, 0,0.1);
		elseif a < 0 then
			darwin.setVelocity(0, 0,-0.1);
			print("turning right");
		else
			print("stopping");
			darwin.stop();
		end			
	end	
	
	turnToAngleGo = function(hfa) -- dont change what we're doing until we go to another state
	end
	turnToAngleStop = function (hfa)
		darwin.stop();	
	end
	
	
	walkForwardStart = function(hfa)                   
		print("walk forward");
		print("ball lost value is :" ..wcm.get_horde_ballLost());
					--Let's walk forward
		darwin.setVelocity(.05, 0,0);
		--since the ball is lost, let's do a head scan			
		darwin.scan();
	end	
	
	walkForwardGo = function(hfa) -- dont change what we're doing until we go to another state
	end
	walkForwardStop = function (hfa)
	end
	
	turnCStart = function(hfa)                   
		print("Turn Clockwise")
		print("enter forward velocity")
		xvel = io.read()
		print("enter side velocity")
		yvel = io.read()
		print("enter angular velocity")
		avel = io.read()
		darwin.setVelocity(xvel, yvel,avel);
		--since the ball is lost, let's do a head scan			
		darwin.scan();
	end	
	
	turnCGo = function(hfa) -- dont change what we're doing until we go to another state
	end
	turnCStop = function (hfa)
	end
	
	
	
	stopStart = function(hfa)
		print("stoping");
		print("ball lost value is :" .. wcm.get_horde_ballLost());	
		print("i stopped at location " .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ", " .. wcm.get_pose().a);
		print(" the ball is at location " .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y());
		darwin.stop();	
		-- since we've found the ball, let's stare at it
		darwin.track(); -- stares at the last location we saw the ball
	end
	
	stopGo = function(hfa)
	end
	stopStop = function(hfa)
	end
	
	-- here's where we make the states, a state consists of a name and 3 functions, start, stop, and go
	turnC = makeBehavior("turnC", turnCStart, turnCStop, turnCGo);
	turnToAngle = makeBehavior("turnToAngle", turnToAngleStart, turnToAngleStop, turnToAngleGo);
	walkForward = makeBehavior("walkForward", walkForwardStart, walkForwardStop, walkForwardGo);
	stop = makeBehavior("stop", stopStart, stopStop, stopGo);
	-- here's the transition table, it's essentually a dictionary indexed by state, and returns a state
	--the state you return will be the next state you pulse
	myMachine = makeHFA("myMachine", makeTransition(
		{
			[start] = turnToAngle, --first thing we do: walk forward
			[turnToAngle] = function()-- if we're in the walk forward state.... 
				if math.abs(getTurnAngleToTarget(targetX, targetY))>5 then
					return turnToAngle 
				else 
					return walkForward 
				end 
			end,
			[walkForward] = function()  -- if we're in the walkForward state....
				if (wcm.get_pose().x - targetX) > targetLimit and (wcm.get_pose().y - targetY) > targetLimit then
					return walkForward 
				else 
					return stop  -- else, stop, we found the ball!
				end 
			end,			
			[stop] = function()  -- if we're in the stop state....
				if math.abs(getTurnAngleToTarget(targetX, targetY))>5 then -- and if the ball is lost we should keep going forward
					return turnToAngle 
				else 
					return stop  -- else, stop, we found the ball!
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
