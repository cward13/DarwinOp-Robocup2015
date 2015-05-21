module(... or "", package.seeall)

require('init')
require('mcm')
require('vcm')
require('wcm')
require('Config')
function toCSV(t)
        local s = ""
        for _, p in pairs(t) do
                s = s .. "," .. p
        end
        return string.sub(s,2) -- remove first comma    
end
local bot_id = Config.game.playerID;
local team_id = Config.game.teamNumber;
local socket = require("socket")
local server = assert(socket.bind('*', 40003))
print("i am now listening to port 40003")
local client = server:accept()
print("connection accepted")
client:settimeout(10)
local line, err = client:receive()
while 1 do
        local my_send_data = "pose," .. toCSV(wcm.get_pose()) .. "\n";
        client:send(my_send_data);
        if (vcm.get_ball_detect() == 1) then
                local ballx = wcm.get_ball_x();
                local bally = wcm.get_ball_y();
                local ball_position = "ball," ..  ballx .. "," .. bally .. "\n";
                print(ball_position);
                client:send(ball_position);
       end
       --ball not found stuff
       -- else
       --         local ball_not_found = "ball coordinates: -10000,-10000";
       --         print(send_local_data(ball_not_found));
       --         local strLength = string.len(ball_not_found)
       --         client:send(strLength)
       --         client:send(ball_not_found);
       -- end

        unix.usleep((.5)*(1E6));

end
               

