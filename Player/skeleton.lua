darwin = require('hfaDriver')

walkForwardStart = function(hfa)                   
    --default behavior for robot.
	print("walk forward");
	print("ball lost value is :" ..wcm.get_horde_ballLost());
        --Let's walk forward
	--darwin.setVelocity(.1, 0,0);
	--since the ball is lost, let's do a head scan			
	--darwin.scan();
    --um well, let's try to walk to (1,1)
    gotoPositionFaceGoal(hfa)
    --[[
    dest = {}
    dest.x = 0
    dest.y = 0
    darwin.setVelocity(0.0001, 0.0001, 0.0001)
    unix.usleep(1E6)
    darwin.stop()
    while true do
        unix.usleep(1E6)
        if angleTo(dest) < -0.2 then
            Speak.talk("right")
        elseif  angleTo(dest) > 0.2 then
            Speak.talk("left")
        else
            Speak.talk("center")
        end

        end
        --]]
end	

sayHeading = function(dest)
    if angleTo(dest) < -0.5 then
        Speak.talk("right")
    elseif  angleTo(dest) > 0.5 then
        Speak.talk("left")
    else
        Speak.talk("center")
    end
end

gotoPositionFaceGoal = function(hfa)
    print("Starting Team Losers Code")
    --what position should we go to?
    destination = {}
    destination.x = 0
    destination.y = 0
    --orient ourselves (do we need to do something?)
    --move to the destination: 
    --  turn towards the destination
    darwin.setVelocity(0,0, normal(angleTo(destination)))
    while math.abs(angleTo(destination)) > 0.04 do
        --os.execute("sleep 0.01")
        unix.usleep(1E3)
        -- the gait gets messed up if you change the velocity in the middle of a movement too often.
        -- how do I tell if I've overshot?
    end
    print("I'm facing the destination now!")
    darwin.stop()

    i = 0
    j = 0
    while distanceTo(destination) > 0.3 do
    --  keep facing the destination while walking forward until we loose track of it or get very close
        i = i + 1
        if i == 100 then
            i = 0
            j = j + 1
            vel = relDirection(destination)
            darwin.setVelocity( vel.x, vel.y, 0)
            print(string.format("%d: going to charge in (%f, %f), dir= %f  theta = %f",j, vel.x, vel.y,angleTo(destination), wcm.get_pose().a ))
            
            --[[
            if vel.x > 0 then
                Speak.talk("Foreward")
            end
            if vel.x < 0 then
                Speak.talk("Back")
            end
            --]]
            --Speak.talk(tostring(j))
            sayHeading(destination)
        end
        --os.execute("sleep 0.001")
        unix.usleep(1E3)
    end
    print("I'm there! now to face the goal.")
    darwin.stop()
    -- face (0, -2.7)
    theirGoal = {}
    theirGoal.x = 0
    theirGoal.y = 2.7
    darwin.setVelocity(0,0, -1*normal(angleTo(theirGoal)))
    print(tostring(angleTo(theirGoal)))
    while math.abs(angleTo(theirGoal)) > 0.05 do
        i = i + 1
        --os.execute("sleep 0.001")
        unix.usleep(1E3)
        if i == 100 then
            i = 0
            print(tostring(angleTo(theirGoal)))
        end
        -- the gait gets messed up if you change the velocity in the middle of a movement too often.
    end
    print("I think I'm facing the goal.  I'm going to stop now.")
    print(tostring(i))
    darwin.stop()

end
normal = function(num)
    return 0.2*num/math.abs(num)
end

relDirection = function(dest)
    vel = {}
    --ang = angleTo(dest)
    loc = wcm.get_pose();
    vel.y = math.tan(math.atan((dest.y - loc.y)/ (dest.x - loc.x)) - loc.a)
    vel.x = 1
    vel = normvec(vel)
    if distanceTo(dest) < 1 then
        dist = distanceTo(dest)
        vel.x = dist * vel.x
        vel.y = dist * vel.y
    end
    return vel
end
--[[
normvec = function(vel)
	norm = {};
	norm.theta = math.atan(vel.y/vel.x);
	norm.r = .05;
	norm.x = .05 * math.cos(norm.theta);
	norm.y = .05 * math.sin(norm.theta);
    --Rrr-awk?
	return norm
end
--]]	

normvec = function(vel)
    norm = {}
    magnitude = math.sqrt(vel.x*vel.x+vel.y*vel.y)
    norm.x = 0.05*vel.x/magnitude
    norm.y = 0.05*vel.y/magnitude
    return norm
end


distanceTo = function(dest)
    curLoc = wcm.get_pose();
    return math.sqrt((dest.y-curLoc.y)*(dest.y-curLoc.y)+(dest.x-curLoc.x)*(dest.x-curLoc.x))
end

angleTo = function(dest)
    -- get current location
    -- determine the angle at which we'd be facing the input
    curLoc = wcm.get_pose();
    return math.atan((dest.y - curLoc.y) /(dest.x - curLoc.x)) - curLoc.a - math.pi/2
end
--[[
walkForwardGo = function(hfa) -- dont change what we're doing until we go to another state
end
walkForwardStop = function (hfa)
end
--]]
stopStart = function(hfa)
	print("stoping");
	print("ball lost value is :" .. wcm.get_horde_ballLost());	
	print("i stopped at location " .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ", " .. wcm.get_pose().x);
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
