module(... or "", package.seeall)

require('cognition')

maxFPS = Config.vision.maxFPS;
tperiod = 1.0/maxFPS;
--print = function()end
function print() 
end
setDebugFalse();
cognition.entry();
vcm.set_vision_enable(vector.ones(1));
while (true) do
  
  --print("!!@@ hi");
  
  tstart = unix.time();

  cognition.update();

  tloop = unix.time() - tstart;

  if (tloop < tperiod) then
    unix.usleep((tperiod - tloop)*(1E6));
  end
end

cognition.exit();

