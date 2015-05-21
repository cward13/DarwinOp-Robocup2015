module(..., package.seeall);

require('Body')
require('Motion')

function entry()
  print(_NAME..' entry');

   started = false;
end

function update()
	wcm.set_horde_passKick(1);
        wcm.set_horde_timeMark(Body.get_time()); 
end

function exit()
  Motion.sm:add_event('walk');
end
