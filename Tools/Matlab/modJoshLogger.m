function []= JoshLogger(teamNumber, playerID)
  
if nargin < 2
  playerID  = 1;
  teamNumber = 1;
end

% create shm interface
robot = shm_robot(teamNumber, playerID);

% camera number
ncamera = 1; %robot.vcmCamera.get_ncamera();

for i=1:100
  w = input('','s');
  if(mod(i,10)==1)
     fprintf('Taking picture %d...\n',i); 
  end
  tic;
  r_mon=robot.get_monitor_struct();
  yuyv_type = r_mon.yuyv_type;
 	if yuyv_type==0
   	  yuyv = robot.get_yuyv();
  elseif yuyv_type==2
 	    yuyv = robot.get_yuyv2();
 	elseif yuyv_type==3
   	  yuyv = robot.get_yuyv3();
	else 
		continue;
    end	
 siz = size(yuyv);
 yuyv_u8 = reshape(typecast(yuyv(:), 'uint8'), [4 siz]);
 ycbcr = yuyv_u8([1 2 4],:,:);
 yuyv = permute(ycbcr, [3 2 1]);
 imwrite(yuyv,strcat('CenterCircleImages/imLogs',sprintf('%03d',i) ,'.jpg'));
end
end
