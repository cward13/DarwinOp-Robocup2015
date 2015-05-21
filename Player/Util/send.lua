-- this will send a list formated as a csv to a particular ip,port

local CommWired=require('MyComm');
local IP ='10.0.0.153'
local PORT = '40002'
CommWired.comm_connect(IP,PORT)-- connect
print("Initiated connection")


function send_local_data(data)
	if not string.find(data, "P#") then
		print(data)
	end
	return CommWired.comm_send(data, #data) == #data
end

function toCSV(t)
	local s = ""
	for _, p in pairs(t) do
		s = s .. "," .. p
	end
	return string.sub(s,2) -- remove first comma	
end
