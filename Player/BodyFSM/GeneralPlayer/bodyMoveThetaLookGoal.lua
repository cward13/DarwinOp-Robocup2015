module(..., package.seeall);

require('Body')
require('Motion')

function entry()
   print(_NAME..' entry');
   Motion.event("walk");
   walk.start();
   started = false;
   HeadFSM.sm:set_state("headIdle");
end

function update()
  walk.set_velocity(0,0,1);
 
end

function exit()
  Motion.sm:add_event('walk');
end
