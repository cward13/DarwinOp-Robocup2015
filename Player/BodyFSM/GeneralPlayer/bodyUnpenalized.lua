module(..., package.seeall);

require('Body')
require('Motion')
require('wcm')

t0 = 0;
timeout = 15.0;

function entry()
  print(_NAME..' entry');
  t0 = Body.get_time();
end

function update()
  t = Body.get_time();
  walk.set_velocity(0.04,0,0);
  ball = wcm.get_ball();
  if (t-ball.t<0.2) then
    return "done";
  end

  if t-t0>timeout then
    return "done";
  end
end

function exit()
end
