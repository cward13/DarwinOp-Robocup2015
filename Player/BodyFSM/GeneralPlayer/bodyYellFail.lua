module(..., package.seeall);

require('Body')
require('Motion')

function entry()
   print(_NAME..' entry');
   wcm.set_horde_yelledFail(1);
   print("done yelling fail in entry");
   started = false;
end

function update()
	print("setting yelledFail");
	wcm.set_horde_yelledFail(1);
        print("done yelling fail in update"); 
--        wcm.set_horde_timeMark(Body.get_time()); 
end

function exit()
  wcm.set_horde_yelledFail(0);
  --Motion.sm:add_event('walk');
end
