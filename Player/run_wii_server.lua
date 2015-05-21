require('init')
require('mcm')


local socket = require("socket")
local server = assert(socket.bind("localhost", 8888))

while 1 do
    local client = server:accept()
    client:settimeout(10)

    local line, err = client:receive()

    if not err then
	mcm.set_walk_wii_message(line)
	print(mcm.get_walk_wii_message())
    end
    client:close()
end

