module(..., package.seeall);

require('Config');	-- For Ball and Goal Size
require('ImageProc');
require('HeadTransform');	-- For Projection
require('Vision');
require('Body');
require('vcm');
require('unix');

-- Dependency
require('detectBall');
require('detectGoal');
require('detectLine');
require('detectCorner');
require('detectSpot');

--for quick test
require('detectRobot');


-- Define Color
colorOrange = Config.color.orange;
colorYellow = Config.color.yellow;
colorField = Config.color.field;
colorWhite = Config.color.white;

use_point_goal=Config.vision.use_point_goal;


enableLine = Config.vision.enable_line_detection or 0;
enableCorner = Config.vision.enable_corner_detection or 0;
enableSpot = Config.vision.enable_spot_detection or 0;
enable_freespace_detection = Config.vision.enable_freespace_detection or 0;
enableBoundary = Config.vision.enable_visible_boundary or 0;
enableRobot = Config.vision.enable_robot_detection or 0;
yellowGoals = Config.world.use_same_colored_goal or 0; --Config.vision.enable_2_yellow_goals or 0;

enable_timeprinting = Config.vision.print_time;

tstart = unix.time();
Tball = 0;
TgoalYellow = 0;
Tline = 0;
Tcorner = 0;
Trobot = 0;
Tfreespace = 0;
Tboundary = 0;

function entry()
  -- Initiate Detection
  ball = {};
  ball.detect = 0;

  ballYellow={};
  ballYellow.detect=0;
	
  goalYellow = {};
  goalYellow.detect = 0;

  line = {};
  line.detect = 0;

  corner = {};
  corner.detect = 0;
  
  spot = {};
  spot.detect = 0;

  obstacle={};
  obstacle.detect=0;

  freespace={};
  freespace.detect=0;

  boundary={};
  boundary.detect=0;


end



function update()


  
  if( Config.gametype == "stretcher" ) then
    ball = detectEyes.detect(colorOrange);
    return;
  end

  -- ball detector
  tstart = unix.time();
  ball = detectBall.detect(colorOrange);
  --print("Ball type is");
  --print(type(ball));
  Tball = unix.time() - tstart;
  

  -- goal detector
  
  if use_point_goal == 1 then
    ballYellow = detectBall.detect(colorYellow);
  else
    --print("@@@manually setting yellow detect to false because use_point_goal is false")
    goalYellow.detect=0;
    tstart = unix.time();
    goalYellow = detectGoal.detect(colorYellow);
    TgoalYellow = unix.time() - tstart;

  end

  -- line detection
  
  if enableLine == 1 then
    tstart = unix.time();
    line = detectLine.detect();
    Tline = unix.time() - tstart;
    if enableCorner == 1 then
      corner = detectCorner.detect(line);
      Tcorner = unix.time() - Tline - tstart; 
    end
  end

  -- spot detection
  if enableSpot == 1 then
     spot = detectSpot.detect();
  end

  -- Global robot detection
  if enableRobot ==1 then
    tstart = unix.time();
    detectRobot.detect();
    Trobot = unix.time() - tstart;
  end


  if false then --vcm.get_vision_enable() ==0 then
    print("@@@Vision enable is false, so therefore you dont detect anything");
    ball.detect = 0;
    ballYellow.detect=0; 
    goalYellow.detect = 0;
    line.detect = 0;
    corner.detect = 0;
  end


  update_shm();
end

function update_shm()

  print(ball.detect .. "******************************** ball detect was set");
  vcm.set_ball_detect(ball.detect);
  if (ball.detect == 1) then
    vcm.set_ball_centroid(ball.propsA.centroid);
    vcm.set_ball_axisMajor(ball.propsA.axisMajor);
    vcm.set_ball_axisMinor(ball.propsA.axisMinor);
    vcm.set_ball_v(ball.v);
    vcm.set_ball_r(ball.r);
    vcm.set_ball_dr(ball.dr);
    vcm.set_ball_da(ball.da);
  end
  --print("@@@goalDetect value is: " .. goalYellow.detect)
  vcm.set_goal_detect(goalYellow.detect);
  if (goalYellow.detect == 1) then
    vcm.set_goal_color(colorYellow);
    vcm.set_goal_type(goalYellow.type);
    vcm.set_goal_v1(goalYellow.v[1]);
    vcm.set_goal_v2(goalYellow.v[2]);
  end


  vcm.set_line_detect(line.detect);
  if (line.detect == 1) then
    vcm.set_line_nLines(line.nLines);
    local v1x=vector.zeros(6);
    local v1y=vector.zeros(6);
    local v2x=vector.zeros(6);
    local v2y=vector.zeros(6);
    local endpoint11=vector.zeros(6);
    local endpoint12=vector.zeros(6);
    local endpoint21=vector.zeros(6);
    local endpoint22=vector.zeros(6);

    max_length=0;
    max_index=1;
    for i=1,line.nLines do 
      v1x[i]=line.v[i][1][1];
      v1y[i]=line.v[i][1][2];
      v2x[i]=line.v[i][2][1];
      v2y[i]=line.v[i][2][2];
      --x0 x1 y0 y1
      endpoint11[i]=line.endpoint[i][1];
      endpoint12[i]=line.endpoint[i][3];
      endpoint21[i]=line.endpoint[i][2];
      endpoint22[i]=line.endpoint[i][4];
      if max_length<line.length[i] then
        max_length=line.length[i];
	max_index=i;
      end
    end

    --TODO: check line length 

    vcm.set_line_v1x(v1x);
    vcm.set_line_v1y(v1y);
    vcm.set_line_v2x(v2x);
    vcm.set_line_v2y(v2y);
    vcm.set_line_endpoint11(endpoint11);
    vcm.set_line_endpoint12(endpoint12);
    vcm.set_line_endpoint21(endpoint21);
    vcm.set_line_endpoint22(endpoint22);

    vcm.set_line_v({(v1x[max_index]+v2x[max_index])/2,
	 	   (v1y[max_index]+v2y[max_index])/2,0,0});
    vcm.set_line_angle(line.angle[max_index]);

  end
  vcm.set_corner_detect(corner.detect);
  if (corner.detect == 1) then
    vcm.set_corner_type(corner.type)
    vcm.set_corner_vc0(corner.vc0)
    vcm.set_corner_v10(corner.v10)
    vcm.set_corner_v20(corner.v20)
    vcm.set_corner_v(corner.v)
    vcm.set_corner_v1(corner.v1)
    vcm.set_corner_v2(corner.v2)
  end

  vcm.set_spot_detect(spot.detect);
  if (spot.detect == 1) then
  end

  vcm.set_freespace_detect(freespace.detect);
  if (freespace.detect == 1) then
	vcm.set_freespace_block(freespace.block);
    vcm.set_freespace_nCol(freespace.nCol);
    vcm.set_freespace_nRow(freespace.nRow);
    vcm.set_freespace_vboundB(freespace.vboundB);
    vcm.set_freespace_pboundB(freespace.pboundB);
    vcm.set_freespace_tboundB(freespace.tboundB);
  end

  vcm.set_boundary_detect(boundary.detect);
  if (boundary.detect == 1) then
    if (freespace.detect == 1) then
      vcm.set_boundary_top(freespace.vboundB);
    else
      vcm.set_boundary_top(boundary.top);
    end
      vcm.set_boundary_bottom(boundary.bottom);
  end


end

function print_time()
  if (enable_timeprinting == 1) then
    if (ball.detect == 1) then
      print ('Ball detected')
    end
    print ('ball detecting time:            '..Tball..'\n')
    if (goalYellow.detect == 1) then
      print ('Goal detected')
    end
    print ('yellow goal detecting time:     '..TgoalYellow..'\n')
    if (enableLine == 1) then
      if (line.detect == 1) then
        print (line.nLines..'lines detected')
      end
      print ('line detecting time:            '..Tline..'\n')
      if (corner.detect == 1) then
        print ('corner detected')
      end
      print ('corner detecting time:          '..Tcorner..'\n')
   end
   if (enable_freespace_detection == 1) then
      if (freespace.detect == 1) then
        print ('freespace detected')
      end
      print ('freespace detecting time:       '..Tfreespace..'\n')
      if (boundary.detect == 1) then
        print ('boundary detected')
      end
      print ('boundary detecting time:        '..Tboundary..'\n')
    end
    if (enalbeRobot == 1) then
      print ('robot detecting time:           '..Trobot..'\n')
    end
  end
end

function exit()
end
