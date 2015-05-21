darwin = require('hfaDriver')

walkForwardStart = function(hfa)                   
	print("walk forward");
	print("ball lost value is" .. darwin.isBallLost());
--	print("ball lost value is :" ..wcm.get_horde_ballLost());
        --Let's walk forward
	darwin.setVelocity(0, -0.05,0.15);
	--since the ball is lost, let's do a head scan			
	darwin.scan();
end	

walkForwardGo = function(hfa) -- dont change what we're doing until we go to another state
--print("hello");
end
walkForwardStop = function (hfa)
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
-- here's where we make the states, a state consiss of a name and 3 functions, start, stop, and go
walkForward = makeBehavior("walkForward", walkForwardStart, walkForwardStop, walkForwardGo);
stop = makeBehavior("stop", stopStart, stopStop, stopGo);
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

--start "main"
darwin.executeMachine(myMachine);

