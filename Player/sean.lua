cwd = os.getenv('PWD')
require('init')

require('unix')
require('Config')
require('shm')
require('vector')
require('mcm')
require('getch')
require('Body')
require('Motion')

Motion.entry();
flag_walk = 0;

getch.enableblock(1);
Body.set_body_hardness(0);

targetvel=vector.zeros(3);

walk.set_velocity(unpack(targetvel));

function doit( n)
	local tDelay = 0.005 * 1E6; -- Loop every 5ms
	for i=0,n do
		Motion.update();
		--Body.update();
		unix.usleep(tDelay);
		end
	end
