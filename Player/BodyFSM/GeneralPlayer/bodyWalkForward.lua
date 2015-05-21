module(..., package.seeall);

require('Body')
require('Motion')

function entry()
  	print(_NAME..' entry');
	Motion.event("walk");
        walk.start();
        walk.set_velocity(0,0,0);
end

function update()
     Motion.event("walk");
     walk.start();
     walk.set_velocity(.02,0,0);
end

function exit()
  Motion.sm:add_event('walk');
end
