module(..., package.seeall);

require('Body')
require('Motion')

function entry()
  	print(_NAME..' entry');
	Motion.event("walk");
        Motion.event("walk")
	walk.start();
        started = false
        walk.set_velocity(0,0,0);
end

function update()
     Motion.event("walk");
     walk.start();
     vel = wcm.get_horde_walkVelocity();
     if(vel ~=nil) then
	--if(vel[0] ~=nil and vel[1] ~=nil and vel[2] ~=nil) then
	walk.set_velocity(vel[1],vel[2],vel[3]); --end
     end
end

function exit()
  Motion.sm:add_event('walk');
end
