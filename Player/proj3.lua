darwin = require('hfaDriver')

-- GLOBAL VARIABLES USED IN THE PROJECT

x_delta = 0;
x_goal = 1;  -- where we want to move
y_goal = 0;	 -- where we want to move
x_turn_goal = 2.7;  -- where we want to turn (goal is at 2.7)
y_turn_goal = 0;  -- where we want to turn (goal is at 0)
angle_goal = 0;
goal_found = 0;
alpha = 0;  -- angle to desired position
angle_theta = 0;  -- angle needed to turn to face desired position
phi = 0;
i = 0;
ballKicked = 0;
y_prime = 0; -- distance to goal_y
x_prime = 0; -- distance to goal_x
kick_to_x =  2.7; -- wehre we want to kick to
kick_to_y = 0;	-- where we want to kick to 
radius = 0.10;  -- used to maintain radius around ball
angle_error = 1; 
in_position = 0; -- reached goal position on the field

walkForwardStart = function(hfa)                   
	print("walk forward");
	print("ball lost value is :" .. wcm.get_horde_ballLost());
        --Let's walk forward
	darwin.setVelocity(.1, 0,0);
	--since the ball is lost, let's do a head scan			
	darwin.scan();
end	

walkForwardGo = function(hfa) -- dont change what we're doing until we go to another state
end
walkForwardStop = function (hfa)
end

stopStart = function(hfa)
	--print("stoping");
	--print("ball lost value is :" .. wcm.get_horde_ballLost());	
	--print("i stopped at location " .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ", " .. wcm.get_pose().x);
	--print(" the ball is at location " .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y());
	--print("stoping");
	darwin.stop();	
	-- since we've found the ball, let's stare at it
	darwin.track(); -- stares at the last location we saw the ball
end

stopGo = function(hfa)
end
stopStop = function(hfa)
end


---[[ Start My Code: walkToPostion
walkToPositionStart = function(hfa)
	
	-- localizes the darwin and saves its position
	darwin.lookGoal();
	x_current = wcm.get_pose().x;
	y_current = wcm.get_pose().y;	
 	
	-- gets the distances to the goal points from the darwin
	x_delta = x_goal - x_current;
	local y_delta = y_goal - y_current;


	-- figure out angle to desired position on field	
	alpha = math.atan2(y_delta, x_delta);
--	print("Alpha: " ..  alpha);


end

walkToPositionGo = function(hfa)

	-- getting current position and calculating distance to goal
	x_current = wcm.get_pose().x;
	x_delta = x_goal - x_current;

	-- getting the robots angle in the global frame
	angle_beta = wcm.get_pose().a;
	--print("Beta: " .. angle_beta);

	-- figuring out how much we need to turn to face the desired position
	angle_theta = angle_beta - alpha;

	-- P-Controllers to get us to the desired position
	--print("Theta: " .. angle_theta);
	local angle_force = -.15 * angle_theta;
	local x_error = x_current - x_goal;
	local x_force = -.03 * x_error;

	-- writing constant x velocity
	darwin.setVelocity(0.03, 0, angle_force);

end
walkToPositionStop = function(hfa)
end

turnToPositionStart = function(hfa)
	-- At the desired position and now want to turn to face another point


	-- look at the goal and re orient
	darwin.lookGoal();
	x_current = wcm.get_pose().x;
	y_current = wcm.get_pose().y;

	print("(".. x_current ..", " .. y_current.. ")" );

	x_delta = x_turn_goal - x_current;
	local y_delta = y_turn_goal - y_current;

	phi = math.atan2(y_delta, x_delta);
	print("phi: " ..  phi);
end

turnToPositionGo = function(hfa)

	x_current = wcm.get_pose().x;

	-- getting our current angle in the global frame
	angle_beta = wcm.get_pose().a;
	--print("Beta: " .. angle_beta);


	-- figuring out how much we need to turn to face the desired position
	local angle_theta = angle_beta - phi;

--	print("Theta: " .. angle_theta);

	-- P controller to get us to turn to desired position
	local angle_force = -.15 * angle_theta; -- changed

	darwin.setVelocity(0, 0, angle_force);

end

turntoPositionStop = function(hfa)
end

--]]

---[[ Start My Code: walkToBall
findBallStart = function(hfa)
--	print("finding ball")
--	print("ball lost value is: " .. wcm.get_horde_ballLost());

	-- look for the ball
	darwin.setVelocity(0, 0, 0.2);
	darwin.scan();
end

findBallGo = function(hfa)
end

findBallStop = function(hfa)
	-- ball is found
	-- stare at ball
	darwin.track();
--	print("The ball is at location: (" .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y());
end

moveToBallStart = function(hfa)
	darwin.lookGoal();
--	print("centering ball")
	darwin.track();
--	print("The ball is at location: (" .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y());
end

moveToBallGo = function(hfa)
	--test
	darwin.track();
	local angle_goal = 0;
	local x_velocity = 0.05;
	local y_velocity = 0;
	local current_y = wcm.get_ball_y();
	local current_x = wcm.get_ball_x();

	-- p controller for angular velocity
	local ball_error = current_y - angle_goal;
	local angle_force = 0.35 * ball_error; -- was 0.2

	darwin.setVelocity(x_velocity, y_velocity, angle_force);
end

moveToBallStop = function(hfa)
end

localizeStart = function(hfa)
	-- looking at the goal to localize
	darwin.lookGoal();
	goal_found = 1;
--	print("I am at location:(" .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ")");
end

localizeGo = function(hfa)
end

localizeStop = function(hfa)
end

--]]

alignStart = function(hfa)
	darwin.stop();
end

alignGo = function(hfa)

	-- finding the position of the ball
	local y = wcm.get_ball_y()*10;
--	print("y: " .. y);
	local y_delta = 0.5 - y;
	local y_force = -0.05 * y_delta;

	-- p controller aligning the darwins left foot with the ball to kick
	-- needed to handle the special case for when the value was 0
	if(wcm.get_ball_y() == 0) then
		darwin.setVelocity(0, 0.05, 0);
	else
		darwin.setVelocity(0, y_force, 0);
	end

end

alignStop = function(hfa)
end


kickStart = function(hfa)
	-- halts the darwin to kick
	darwin.setVelocity(0, 0, 0);
	darwin.kickBall();
end

kickGo = function(hfa)
end

kickStop = function(hfa)
end

arcStart = function(hfa)
	-- stops the darwin and localizes
	darwin.setVelocity(0,0,0);
	darwin.lookGoal();
	darwin.track();

	-- saves darwins angle in the global frame
	local angle_beta = wcm.get_pose().a;
	--print("Beta: " ..  angle_beta);

	-- calculates the angle from the darwin to the goal position
	x_prime = kick_to_x - wcm.get_pose().x;
	y_prime = kick_to_y - wcm.get_pose().y;
	alpha = math.atan2(y_prime,x_prime);
	--print("alpha: " .. alpha)
end

arcGo = function(hfa)

	darwin.track();

	-- gets the difference between the darwins angle and the angle it needs to face
	angle_error = wcm.get_pose().a - alpha;
	print("angle error: " .. angle_error);
	print("x dist: " .. wcm.get_pose().x);

	local y_force = -0.10 * angle_error;
	local radius_error = radius - wcm.get_ball_x();
	local radius_force = -0.05 * radius_error;

	darwin.setVelocity(0, 0.025, -0.20);
end

arcStop = function(hfa)
end


scanStart = function(hfa)
	-- scans for the ball and stares at it once found
	darwin.scan()
end

scanGo = function(hfa)
	darwin.track()
end

scanStop = function(hfa)
end

-- here's where we make the states, a state consiss of a name and 3 functions, start, stop, and go
walkForward = makeBehavior("walkForward", walkForwardStart, walkForwardStop, walkForwardGo);
stop = makeBehavior("stop", stopStart, stopStop, stopGo);

---[[ STATES WE MADE FOR THE PROJECT

findBall = makeBehavior("findBall", findBallStart , findBallStop, findBallGo );
moveToBall = makeBehavior("moveToBall", moveToBallStart,  moveToBallStop, moveToBallGo );
localize = makeBehavior("localize", localizeStart, localizeStop, localizeGo);
walkToPosition = makeBehavior("walkToPosition", walkToPositionStart, walkToPositionStop, walkToPositionGo);
turnToPosition = makeBehavior("turnToPosition", turnToPositionStart, turnToPositionStop, turnToPositionGo);
align = makeBehavior("align", alignStart, alignStop, alignGo);
kick = makeBehavior("kick", kickStart, kickStop, kickGo);
arc = makeBehavior("arc", arcStart, arcStop, arcGo);
scan = makeBehavior("scan", scanStart, scanStop, scanGo);
--]]

-- here's the transition table, it's essentually a dictionary indexed by state, and returns a state
--the state you return will be the next state you pulse
myMachine = makeHFA("myMachine", makeTransition({
	[start] = walkForward, --first thing we do: walk forward
	[walkForward] = function()-- if we're in the walk forward state.... 
				if wcm.get_horde_ballLost()==0 then -- and if the ball is found, we should stop
					return stop 
				else 
					return walkForward -- else keep walking forward
				end 
			end,
	[stop] = function()  -- if we're in the stop state....
			if wcm.get_horde_ballLost()==1 then -- and if the ball is lost we should keep going forward
				return walkForward 
			else 
				return stop  -- else, stop, we found the ball!
			end 
		end,
	}),false);

walkToPositionFaceTarget = makeHFA("walkToPositionFaceTarget", makeTransition({
	[start] = localize,
	[localize] = function()
		if goal_found == 1 then
			return walkToPosition
		else 
			return localize 
		end
	end,
	
	[walkToPosition] = function()
		if x_delta <= 0.1 then 
			print("At location: (" .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ")");
			return turnToPosition
		else
			return walkToPosition
		end
	end,
	[turnToPosition] = function()
		
		if -0.15 <= (wcm.get_pose().a - phi) and (wcm.get_pose().a - phi) <= 0.15 then -- changed 
			in_position = 1;		
			return stop
		else
			return turnToPosition

		end
	end,
	[stop] = function()
		if -0.1 <= (wcm.get_pose().a - phi) and (wcm.get_pose().a - phi) <= 0.1  then
			return stop
		else	
			return walkToPosition
		end
	end,
}), false);

walkToBall = makeHFA("walkToBall", makeTransition({
	[start] = findBall,
	[findBall] = function() -- if were in the findBall state
			if wcm.get_horde_ballLost() == 0 then -- and if the ball is found
				return moveToBall
			else
				return findBall
			end
		end,
	[moveToBall] = function()
			if (wcm.get_ball_x() <= .25)  then --was 0.18
				return stop
			elseif wcm.get_horde_ballLost() == 1 then
				return findBall
			else
				return moveToBall
			end
		end,
	[stop] = function()
		if wcm.get_ball_x() >= .18 then
			return moveToBall
		elseif wcm.get_horde_ballLost() == 1 then
			return findBall
		else 
			return stop
		end
	end, 
}), false);


walkToAndKickBall = makeHFA("walkToAndKickBall", makeTransition({
	[start] = walkToBall,
	[walkToBall] = function()
			--was 0.18
        		if (wcm.get_ball_x() <= 0.18) then
				return align
			else
				return walkToBall
				
			end
		end,
	[align] = function()
		if (wcm.get_ball_y()*10 <= 1) and (wcm.get_ball_y()*10 >= 0.0) then
			return kick
		else
			return align
		end	
	end,
	
	[kick] = function()
		if (wcm.get_ball_y()*10 <= 1) and (wcm.get_ball_y()*10 >= 0.0) then
			ballKicked = 1;
			return kick
	
		elseif ballKicked == 1 then
			return stop

		else
			return align
		end
	end,
	[stop] = function()
		if ballKicked == 1 then
			return stop	
		else 
			return walkToBall
		end
	end,

}), false);

KickTo = makeHFA("KickTo", makeTransition({
	[start] = localize,
	
	[localize] = function()
		if goal_found == 1 then
			return walkToBall
		else 
			return localize 
		end
	end,		
	[walkToBall] = function()
			--was 0.18
   		if (wcm.get_ball_x() <= 0.25) then
				return arc
			else
				return walkToBall
			end
		end,	
	[arc] = function()
	
		darwin.lookGoal();
		if (angle_error < 0.2) and (angle_error > -0.2)  then
			return walkToAndKickBall
		else
			return arc
		end		
	end,
	
	[walkToAndKickBall] = function()
		if ballKicked == 1 then
			return stop
		else
			return walkToAndKickBall
		end
	
	end,
	[stop] = function()	
		if ballKicked == 1 then
	  --print("kicking");
			return stop
		else
		--print("not kicking, walking");
			return arc
		--  return align
		end
	end,
}), false);

walkToPositionWaitAndKick = makeHFA("walkToPositionWaitAndKick", makeTransition({
	[start] = walkToPositionFaceTarget,
	
	[walkToPositionFaceTarget] = function()
		if (in_position == 1) then 
			--print("in position")
			return scan
		else 
			return walkToPositionFaceTarget
		end
	end,

	[scan] = function()
		print(wcm.get_ball_x())
		if wcm.get_ball_x() < 0.5 then
			return KickTo
		else
			return scan
		end
	end,
	
	[KickTo] = function()
		if ballKicked == 1 then
			return stop
		else
			return KickTo
		end
	end,
		
	[stop] = function()
		if ballKicked == 1 then
			return stop
		else
			return KickTo
		end
	end,
}), false);

--start "main" A list of HFA's which complete the tasks of the project

--darwin.executeMachine(myMachine);
--darwin.executeMachine(walkToPositionFaceTarget);
--darwin.executeMachine(walkToBall);
--darwin.executeMachine(walkToAndKickBall);
--darwin.executeMachine(KickTo);
darwin.executeMachine(walkToPositionWaitAndKick);
