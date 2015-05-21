	--This file is built around the code that was provided
	darwin = require('hfaDriver')
	
	degToRad = math.pi/180
	radToDeg = 180/math.pi
	
	targetY = 0
	targetX = 0
	targetLimit = 0.01
	angleLimit = 2 * degToRad
	turnSpeed = 0.1
	walkSpeed = 0.05
	locTime = 6 -- time to localize, in seconds
	printCount = 0 
	printLimit = 10
	
	--functions
	function getTurnAngleToTarget(tx, ty) 	
		local angle = 0
		local rx = wcm.get_pose().x
		local ry = wcm.get_pose().y
		local ra = wcm.get_pose().a
		local dx = tx - rx
		local dy = ty - ry
		
		if dx == 0 then --if angle is +/- 90
			angle = 0
		else
			angle = math.atan(dy/dx)
		end
		
		if dx <= 0 and dy <= 0 then -- if in 4th quadrant, adjust tan
			angle = angle - math.pi
		elseif dx < 0 and dy > 0 then
			angle = angle + math.pi
		end
		
		angle = angle - ra
		return angle
	end
	
	--Behaviors
	localizeStart = function(hfa)                   
		print("localize behavior");
		darwin.lookGoal()
		darwin.setVelocity(walkSpeed, 0,0);
	end	
	
	localizeGo = function(hfa) -- dont change what we're doing until we go to another state
		if(printCount > printLimit*100) then
			print ("Localizing...")
			printCount = 0
		end
	end
	localizeStop = function (hfa)
	end
	
	turnToAngleStart = function(hfa)   	
		darwin.lookGoal()
	end	
	turnToAngleGo = function(hfa) 
		local a = getTurnAngleToTarget(targetX, targetY);
		if a > 0 then
			if(printCount > printLimit) then
				print ("turningLeft: Rx: "..wcm.get_pose().x.." Ry: "..wcm.get_pose().y.." Ra: "..wcm.get_pose().a.." Tx: "..targetX.." Ty: "..targetY.." a: "..a)
				printCount = 0
			end
			
			darwin.setVelocity(0, 0,turnSpeed);
			
		else
			if(printCount > printLimit) then
				print ("turningRight: Rx: "..wcm.get_pose().x.." Ry: "..wcm.get_pose().y.." Ra: "..wcm.get_pose().a.." Tx: "..targetX.." Ty: "..targetY.." a: "..a)
				printCount = 0
			end
			darwin.setVelocity(0, 0,-1*turnSpeed);
		end
	end
	turnToAngleStop = function (hfa)		
	end
	

	walkForwardStart = function(hfa)                   
		darwin.setVelocity(walkSpeed, 0,0);
	end	
	
	walkForwardGo = function(hfa)
		if(printCount > printLimit) then
			print ("forward: Rx: "..wcm.get_pose().x.." Ry: "..wcm.get_pose().y.." Ra: "..wcm.get_pose().a.." Tx: "..targetX.." Ty: "..targetY)
			printCount = 0
		end
	end
	walkForwardStop = function (hfa)
		darwin.lookGoal()
	end
	
	stopStart = function(hfa)
		print("i stopped at location " .. wcm.get_pose().x .. ", " .. wcm.get_pose().y .. ", " .. wcm.get_pose().a);
		--print(" the ball is at location " .. wcm.get_ball_x() .. ", " .. wcm.get_ball_y());
		darwin.setVelocity(0, 0,-1*turnSpeed);
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
	localize = makeBehavior("localize", localizeStart, localizeStop, localizeGo);
	stop = makeBehavior("stop", stopStart, stopStop, stopGo);
	oldtime = os.clock()
	
	
	-- STATE TRANSITIONS
	myMachine = makeHFA("myMachine", makeTransition(
		{
			[start] = localize, --first thing we do: walk forward
			[localize] = function()
				printCount = printCount +1
				if (os.clock() - oldtime)<locTime then
					return localize 
				else 
					return turnToAngle 
				end 
			end,
			[turnToAngle] = function() 
				printCount = printCount +1
				if math.abs(getTurnAngleToTarget(targetX, targetY))>angleLimit then
					return turnToAngle 
				else
					return walkForward 
				end 
			end,
			[walkForward] = function() 
				printCount = printCount +1;
				local distance = math.sqrt(math.pow((targetX -wcm.get_pose().x),2)+math.pow((targetY - wcm.get_pose().y),2))
				
				if math.abs(getTurnAngleToTarget(targetX, targetY)) > angleLimit*3 then
					if(printCount > printLimit) then
						print ("To Turn State")
						printCount = 0
					end
					return turnToAngle
				elseif distance > targetLimit then
					if(printCount > printLimit) then
						print ("In walk State")
						printCount = 0
					end
					return walkForward 
				else 
					return stop 
				end 
			end,			
			[stop] = function() 
				return stop  
				
			end,
	}),false);	
		
	--start "main"
	darwin.executeMachine(myMachine);

