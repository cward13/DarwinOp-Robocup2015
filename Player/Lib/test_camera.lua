Camera = require "OPCam"

image=Camera.get_image();
print(image);
for i=1,320 do
	print(image[i]);
end
Camera.stream_off();
Camera.stop();
