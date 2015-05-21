module(... or "",package.seeall)
cwd = os.getenv('PWD')
require('init')
require('Config');
require('unix')
require('vcm')
require('gcm')
require('wcm')
require('mcm')
require('Body')
require('Vision')
require('World')
require('Detection') 
require('Speak');
wcm.set_horde_visionPenalty(0);
function print() end
--~ print a table
function printTable(list, i)

    local listString = ''
--~ begin of the list so write the {
    if not i then
        listString = listString .. '{'
    end

    i = i or 1
    local element = list[i]

--~ it may be the end of the list
    if not element then
        return listString .. '}'
    end
--~ if the element is a list too call it recursively
    if(type(element) == 'table') then
        listString = listString .. printTable(element)
    else
        listString = listString .. element
    end

    return listString .. ', ' .. printTable(list, i + 1)

end


comm_inited = false;
enable_team = Config.vision.enable_team_broadcast or 0;
vcm.set_camera_teambroadcast(1);  -- changed from enable_team to 1
vcm.set_camera_broadcast(0);
--Now vcm.get_camera_teambroadcast() determines 
--Whether we use wired monitoring comm or wireless team comm

count = 0;
nProcessedImages = 0;
tUpdate = unix.time();

enable_online_colortable_learning = Config.vision.enable_online_colortable_learning or 0;
enable_freespace_detection = Config.vision.enable_freespace_detection or 0;

if (string.find(Config.platform.name,'Webots')) then
  webots = true;
end

function broadcast()
  broadcast_enable = vcm.get_camera_broadcast();
  if broadcast_enable>0 then
    if broadcast_enable==1 then 
      --Mode 1, send 1/4 resolution, labeB, all info
      imgRate = 1; --30fps
    elseif broadcast_enable==2 then 
      --Mode 2, send 1/2 resolution, labeA, labelB, all info
      imgRate = 2; --15fps
    else
      --Mode 3, send 1/2 resolution, info for logging
      imgRate = 1; --30fps
    end
    -- Always send non-image data
    Broadcast.update(broadcast_enable);
    -- Send image data every so often
    if nProcessedImages % imgRate ==0 then
      Broadcast.update_img(broadcast_enable);    
    end
    --Reset this flag at every broadcast
    --To prevent monitor running during actual game
    vcm.set_camera_broadcast(0);
  end
end

function entry()
  World.entry();
  Vision.entry();
  if enable_freespace_detection == 1 then
    --OccupancyMap.entry();
  end
end

--Update function for wired kinnect input
function update_box()
  count = count + 1;
  tstart = unix.time();

  -- update vision 
  imageProcessed = Vision.update();
  World.update_odometry();

  -- update localization
  if imageProcessed then
    nProcessedImages = nProcessedImages + 1;
    World.update_vision();
  elseif gcm.get_game_state() == 0 then
    World.init_particles();
  end
 
 
 
  if not comm_inited and 
    (vcm.get_camera_broadcast()>0 or vcm.get_camera_teambroadcast()>0) then
      Config.dev.team = 'TeamBox'; --Force using Team box here 
      require('Team');
      require('GameControl');
      Team.entry();
      GameControl.entry();
      print("Starting to send wireless team message..");
      comm_inited = true;
  end
  if comm_inited then
  -- SJ: TeamBox receives KINNECT data, so should run every frame
    Team.update();
  end

  if comm_inited and imageProcessed then
    GameControl.update();
  end
end


lastTimeFoundForFlip = Body.get_time();
lastTimeFoundOnGoalieSide = Body.get_time();
lastTimeNotOnGoalieSide = 0;
-- if I have seen the ball on my side for >3s then I will say ball certain on my side
function updateGoalieFlip()

	if vcm.get_ball_detect() ~= 0 then
		lastTimeFoundForFlip = Body.get_time();
 		local ballGlobalXSign = wcm.get_ballGlobal_x() / math.abs(wcm.get_ballGlobal_x());
  		local goalSign = wcm.get_horde_goalSign();
  		
		if  math.abs(wcm.get_ballGlobal_x()) > 1 and ballGlobalXSign == goalSign then
			lastTimeFoundOnGoalieSide = Body.get_time();
		else
			lastTimeNotOnGoalieSide = Body.get_time();
		end
		
		if lastTimeFoundOnGoalieSide - lastTimeNotOnGoalieSide >= 3 then
			setDebugTrue();
			--Speak.talk("monkey brains");
			setDebugTrue();
			--Speak.talk("hey idk, what's up");
			print("lasttime, lasttimenot, goalsign,ballGlobalsign " .. lastTimeFoundOnGoalieSide .. " " .. lastTimeNotOnGoalieSide .. " " .. goalSign .. " " .. ballGlobalXSign);
			setDebugTrue();
			--Speak.talk("ball x, " .. wcm.get_ballGlobal_x());
			wcm.set_horde_goalieCertainBallOnMySide(1);
			setDebugFalse();
		elseif( lastTimeNotOnGoalieSide - lastTimeFoundOnGoalieSide >= .27) then
			wcm.set_horde_goalieCertainBallOnMySide(0);
		end
		
	elseif(Body.get_time() - lastTimeFoundForFlip > 3.5) then
		lastTimeNotOnGoalieSide = Body.get_time();
		wcm.set_horde_goalieCertainBallOnMySide(0);
	end
end



function update()
  if(wcm.get_horde_visionPenalty()==1) then
  	print("i cannot see, help, help help");
	Speak.talk("i cannot see. please, help");
  end
  count = count + 1;
  tstart = unix.time();
  
  if Config.game.role == 0 then
	updateGoalieFlip()
  end
  
  -- update vision 
  imageProcessed = Vision.update();

  World.update_odometry();

  -- update localization
  if imageProcessed then
    nProcessedImages = nProcessedImages + 1;
    World.update_vision();

    if (nProcessedImages % 500 == 0) then
      if not webots then
        print('team fps: '..(500 / (unix.time() - tUpdate)));
        tUpdate = unix.time();
      end
    end
  end
  if not comm_inited and 
    (vcm.get_camera_broadcast()>0 or
     vcm.get_camera_teambroadcast()>0) then
    if vcm.get_camera_teambroadcast()>0 then
      
print("Sean"); 
    print(printTable(package.loaded,nil));
      require('Team');
      require('GameControl');
      print("team is returned as " .. tostring(Team));
      Team.entry();
      GameControl.entry();
      print("Starting to send wireless team message..");
    else
      require('Broadcast');
      print("Starting to send wired monitor message..");
    end
    comm_inited = true;
  end

  if comm_inited and imageProcessed then
    if vcm.get_camera_teambroadcast()>0 then 
      GameControl.update();
      if nProcessedImages % 3 ==0 then
        --10 fps team update
        Team.update();
      end
    else
      broadcast();
    end
  end
end

-- exit 
function exit()
  if vcm.get_camera_teambroadcast()>0 then 
    Team.exit();
    GameControl.exit();
  end
  Vision.exit();
  World.exit();
end

