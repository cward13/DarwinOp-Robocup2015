module(..., package.seeall);

require('Body')
require('keyframe')
require('walk')
require('vector')
require('Config')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion/keyframes"


STOPPING = 0;
RESTARTED = 2;
RESTOPPED = 3;

state = STOPPING;

function entry()
  print(_NAME .. " entry");
  walk.stop();
  state = STOPPING;
end

function update()
  walk.update();
  if (state == STOPPING) then
      if (walk.active) then  -- we're still walking, not done yet
      -- do nothing yet
			else
        walk.start();
        state = RESTARTED;
      end
  else if (state == RESTARTED) then
    walk.stop();  -- done with one loop
    state = RESTOPPED;
  else if (state == RESTOPPED) then
    -- do nothing
  else
		--do nothing?
	end
end
end
end

function exit()
 
end

